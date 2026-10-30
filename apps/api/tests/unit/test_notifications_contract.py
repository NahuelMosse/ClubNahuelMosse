"""El contrato y el mensaje push de notificaciones, con los errores de cuerpo documentados."""

# ruff: noqa: E501  (los títulos de las pruebas llevan su etiqueta y no se parten)
import pytest

# (ruta, método) -> (operationId, parámetros, códigos, ¿lleva cuerpo?); todas llevan HTTPBearer.
CONTRACT = {
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


def test_the_notifications_contract_and_push_message_are_mains(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    """el contrato y el mensaje push de notificaciones son los de main @ENG-04-S3 @assumption:ENG-04-ASM-01"""
    monkeypatch.setenv("FIREBASE_AUTH_EMULATOR_HOST", "127.0.0.1:9099")
    from app.main import create_app
    from app.modules.notifications.push import build_message
    from app.modules.notifications.rules import Notice

    paths = create_app().openapi()["paths"]
    actual = {}
    for (path, method), _ in CONTRACT.items():
        op = paths[path][method]
        parameters = [(p["name"], p["in"], p["required"]) for p in op.get("parameters", [])]
        actual[(path, method)] = (
            op["operationId"],
            parameters,
            set(op["responses"]),
            "requestBody" in op,
            op["security"],
        )
    expected = {k: (*v, [{"HTTPBearer": []}]) for k, v in CONTRACT.items()}
    common = Notice(title="T", body="B", data={"kind": "reminder", "booking_id": "r"})
    forced = Notice(title="T", body="B", data={"kind": "forced_cancellation"})
    simple = build_message(["a", "b"], common)
    grouped = build_message(["a"], forced)

    assert actual == expected
    assert (simple.notification.title, simple.notification.body) == ("T", "B")
    assert simple.data == {"kind": "reminder", "booking_id": "r"}
    assert simple.tokens == ["a", "b"] and simple.android is None and simple.apns is None
    assert grouped.android.collapse_key == "forced_cancellation"
    assert grouped.android.notification.tag == "forced_cancellation"
    assert grouped.apns.headers == {"apns-collapse-id": "forced_cancellation"}
    assert grouped.data == {"kind": "forced_cancellation"}
