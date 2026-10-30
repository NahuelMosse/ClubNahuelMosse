"""Los bloqueos que toma un repositorio siguen valiendo dentro de `en_transaccion`."""

import time
from concurrent.futures import ThreadPoolExecutor

from fastapi.testclient import TestClient
from sqlalchemy import Engine, text


def test_el_alta_de_un_espacio_espera_la_baja_en_curso_de_su_sede_y_la_rechaza(
    api: TestClient, motor: Engine, token_admin: str, sede: tuple[str, str]
) -> None:
    """el alta de un espacio espera la baja en curso de su sede y la rechaza
    @ARQ-02-S2 @assumption:ARQ-02-ASM-05"""
    sede_id, _ = sede
    espacio = {
        "venue_id": sede_id,
        "sport": "Futbol",
        "kind": "F5",
        "covered": False,
        "lit": True,
        "price_per_hour": 38000,
    }
    with motor.connect() as baja, ThreadPoolExecutor(max_workers=1) as pool:
        baja.execute(
            text("UPDATE venue SET active = false, deactivated_at = now() WHERE id = :id"),
            {"id": sede_id},
        )
        alta = pool.submit(
            api.post, "/spaces", headers={"Authorization": f"Bearer {token_admin}"}, json=espacio
        )
        time.sleep(1.5)
        esperaba = not alta.done()
        baja.commit()
        r = alta.result(timeout=30)

    assert esperaba
    assert r.status_code == 422
    assert r.json() == {"errors": {"venue_id": "La sede ya no está disponible"}}
