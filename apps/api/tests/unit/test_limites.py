import threading
from collections.abc import Iterator

import pytest
from fastapi import Depends, FastAPI
from fastapi.testclient import TestClient

from app.config import config
from app.interfaz import limites
from app.interfaz.limites import LimiteExcedido, Ventana, frenar_por_origen


class _Reloj:
    def __init__(self) -> None:
        self.ahora = 1000.0

    def __call__(self) -> float:
        return self.ahora


def _ventana(maximo: int = 3, segundos: int = 60) -> tuple[Ventana, _Reloj]:
    reloj = _Reloj()
    return Ventana(maximo, segundos, "Esperá un rato.", reloj), reloj


def test_deja_pasar_hasta_el_maximo_y_frena_el_siguiente() -> None:
    ventana, _ = _ventana()
    for _ in range(3):
        ventana.exigir("a")

    with pytest.raises(LimiteExcedido) as frenado:
        ventana.exigir("a")

    assert frenado.value.espera == 60
    assert frenado.value.mensaje == "Esperá un rato."


def test_cada_clave_tiene_su_cupo() -> None:
    ventana, _ = _ventana(maximo=1)
    ventana.exigir("a")

    ventana.exigir("b")


def test_el_cupo_vuelve_cuando_vence_el_pedido_mas_viejo() -> None:
    ventana, reloj = _ventana(maximo=2, segundos=60)
    ventana.exigir("a")
    reloj.ahora += 30
    ventana.exigir("a")
    reloj.ahora += 29.9
    with pytest.raises(LimiteExcedido):
        ventana.exigir("a")

    reloj.ahora += 0.1

    ventana.exigir("a")
    with pytest.raises(LimiteExcedido):
        ventana.exigir("a")


def test_un_pedido_frenado_no_alarga_la_espera() -> None:
    ventana, reloj = _ventana(maximo=1, segundos=60)
    ventana.exigir("a")
    for _ in range(5):
        reloj.ahora += 10
        with pytest.raises(LimiteExcedido):
            ventana.exigir("a")

    reloj.ahora += 10

    ventana.exigir("a")


def test_dos_pedidos_a_la_vez_cuentan_los_dos() -> None:
    ventana = Ventana(50, 60, "Esperá.")
    pasaron: list[int] = []
    arranque = threading.Barrier(20)

    def pedir() -> None:
        arranque.wait()
        for _ in range(10):
            try:
                ventana.exigir("a")
            except LimiteExcedido:
                continue
            pasaron.append(1)

    hilos = [threading.Thread(target=pedir) for _ in range(20)]
    for h in hilos:
        h.start()
    for h in hilos:
        h.join()

    assert len(pasaron) == 50


def test_por_cuenta_son_diez_por_hora_y_por_origen_diez_por_minuto() -> None:
    reloj = _Reloj()
    limites_ = limites.Limites(reloj)
    for ventana in (limites_.por_cuenta, limites_.por_origen):
        for _ in range(10):
            ventana.exigir("a")

    reloj.ahora += 59.9
    with pytest.raises(LimiteExcedido) as por_origen:
        limites_.por_origen.exigir("a")
    reloj.ahora += 0.1
    limites_.por_origen.exigir("a")

    reloj.ahora += 3539.9
    with pytest.raises(LimiteExcedido) as por_cuenta:
        limites_.por_cuenta.exigir("a")
    reloj.ahora += 0.1
    limites_.por_cuenta.exigir("a")

    assert por_origen.value.mensaje == limites.MENSAJE_POR_ORIGEN
    assert por_cuenta.value.mensaje == limites.MENSAJE_POR_CUENTA
    assert (por_origen.value.espera, por_cuenta.value.espera) == (60, 3600)


def test_las_claves_vencidas_se_barren_al_llegar_al_tope(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setattr(limites, "_CLAVES_MAXIMAS", 3)
    ventana, reloj = _ventana(maximo=1, segundos=60)
    for clave in ("a", "b", "c"):
        ventana.exigir(clave)
    reloj.ahora += 61

    ventana.exigir("d")

    assert list(ventana._pedidos) == ["d"]


@pytest.fixture
def app_con_limite() -> Iterator[TestClient]:
    app = FastAPI()
    limites.instalar(app)

    @app.get("/prueba", dependencies=[Depends(frenar_por_origen("prueba"))])
    def prueba() -> dict[str, bool]:
        return {"ok": True}

    with TestClient(app) as cliente:
        yield cliente


def test_el_onceavo_pedido_del_origen_responde_429_con_espera_y_mensaje(
    app_con_limite: TestClient,
) -> None:
    codigos = [app_con_limite.get("/prueba").status_code for _ in range(11)]
    frenado = app_con_limite.get("/prueba")

    assert codigos == [200] * 10 + [429]
    assert frenado.headers["retry-after"] == "60"
    assert frenado.json() == {
        "mensaje": "Hiciste demasiados intentos. Esperá un minuto y volvé a probar."
    }


def test_sin_proxy_un_x_forwarded_for_inventado_no_cambia_el_origen(
    app_con_limite: TestClient, monkeypatch: pytest.MonkeyPatch
) -> None:
    monkeypatch.setattr(config, "detras_de_proxy", False)

    codigos = [
        app_con_limite.get("/prueba", headers={"X-Forwarded-For": f"203.0.113.{n}"}).status_code
        for n in range(11)
    ]

    assert codigos[-1] == 429


def test_detras_del_proxy_el_origen_es_el_ultimo_valor_de_x_forwarded_for(
    app_con_limite: TestClient, monkeypatch: pytest.MonkeyPatch
) -> None:
    monkeypatch.setattr(config, "detras_de_proxy", True)

    inventados = [
        app_con_limite.get(
            "/prueba", headers={"X-Forwarded-For": f"203.0.113.{n}, 198.51.100.7"}
        ).status_code
        for n in range(11)
    ]
    otro = app_con_limite.get("/prueba", headers={"X-Forwarded-For": "198.51.100.8"})

    assert inventados[-1] == 429
    assert otro.status_code == 200


def test_detras_del_proxy_sin_cabecera_vale_la_direccion_del_socket(
    app_con_limite: TestClient, monkeypatch: pytest.MonkeyPatch
) -> None:
    monkeypatch.setattr(config, "detras_de_proxy", True)

    codigos = [app_con_limite.get("/prueba").status_code for _ in range(11)]

    assert codigos[-1] == 429
