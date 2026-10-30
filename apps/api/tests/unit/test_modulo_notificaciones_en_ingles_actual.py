"""El contrato y el mensaje push de notificaciones, con los errores de cuerpo documentados."""

# ruff: noqa: E501  (los títulos de las pruebas llevan su etiqueta y no se parten)
import pytest

# (ruta, método) -> (operationId, parámetros, códigos, ¿lleva cuerpo?); todas llevan HTTPBearer.
CONTRATO = {
    ("/devices", "put"): ("register_devices_put", [], {"204", "400", "401", "403", "408", "409", "413", "422"}, True),
    ("/devices/unregister", "post"): ("unregister_devices_unregister_post", [], {"204", "400", "401", "408", "413", "422"}, True),
    ("/notifications", "get"): ("center_notifications_get", [], {"200", "401"}, False),
    ("/notifications/read-all", "post"): ("read_all_notifications_read_all_post", [], {"204", "401"}, False),
    ("/notifications/{notification_id}/read", "post"): (
        "read_notifications__notification_id__read_post",
        [("notification_id", "path", True)],
        {"204", "401", "404", "422"},
        False,
    ),
}  # fmt: skip


def test_el_contrato_y_el_mensaje_push_de_notificaciones_son_los_de_main(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    """el contrato y el mensaje push de notificaciones son los de main @ENG-04-S3 @assumption:ENG-04-ASM-01"""
    monkeypatch.setenv("FIREBASE_AUTH_EMULATOR_HOST", "127.0.0.1:9099")
    from app.main import create_app
    from app.modules.notifications.push import build_message
    from app.modules.notifications.rules import Notice

    caminos = create_app().openapi()["paths"]
    obtenido = {}
    for (ruta, metodo), _ in CONTRATO.items():
        op = caminos[ruta][metodo]
        parametros = [(p["name"], p["in"], p["required"]) for p in op.get("parameters", [])]
        obtenido[(ruta, metodo)] = (
            op["operationId"],
            parametros,
            set(op["responses"]),
            "requestBody" in op,
            op["security"],
        )
    esperado = {k: (*v, [{"HTTPBearer": []}]) for k, v in CONTRATO.items()}
    comun = Notice(title="T", body="B", data={"kind": "reminder", "booking_id": "r"})
    forzosa = Notice(title="T", body="B", data={"kind": "forced_cancellation"})
    simple = build_message(["a", "b"], comun)
    agrupado = build_message(["a"], forzosa)

    assert obtenido == esperado
    assert (simple.notification.title, simple.notification.body) == ("T", "B")
    assert simple.data == {"kind": "reminder", "booking_id": "r"}
    assert simple.tokens == ["a", "b"] and simple.android is None and simple.apns is None
    assert agrupado.android.collapse_key == "forced_cancellation"
    assert agrupado.android.notification.tag == "forced_cancellation"
    assert agrupado.apns.headers == {"apns-collapse-id": "forced_cancellation"}
    assert agrupado.data == {"kind": "forced_cancellation"}
