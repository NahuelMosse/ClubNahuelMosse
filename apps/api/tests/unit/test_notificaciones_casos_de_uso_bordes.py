"""Bordes de los casos de uso de avisos: filtro por persona, registro del teléfono y lectura."""

from collections.abc import Sequence
from datetime import UTC, date, datetime
from typing import Any, cast
from uuid import UUID

import pytest

from app.modules.notifications import use_cases
from app.modules.notifications.rules import (
    DeliveryResult,
    LostNotice,
    Notice,
    PendingNotice,
    Reminder,
)
from app.modules.session import Profile
from app.shared.errors import Forbidden, InvalidData, NotFound, Unavailable

NOW = datetime(2026, 10, 1, 20, 0, tzinfo=UTC)


class _Notifications:
    """Guarda con qué filtro de persona le preguntaron y contesta lo que se le configuró."""

    def __init__(self, accepts_device: bool = True, owns_notification: bool = True) -> None:
        self.accepts_device = accepts_device
        self.owns_notification = owns_notification
        self.filters: list[UUID | None] = []

    def fail_stranded(self, user_id: UUID | None) -> list[LostNotice]:
        self.filters.append(user_id)
        return []

    def take_next(self, user_id: UUID | None) -> PendingNotice | None:
        self.filters.append(user_id)
        return None

    def due(self, now: datetime, user_id: UUID | None) -> list[Reminder]:
        self.filters.append(user_id)
        return []

    def register_device(self, user_id: UUID, token: str, platform: str, permission: bool) -> bool:
        return self.accepts_device

    def of_user(self, user_id: UUID) -> tuple[list[Any], int]:
        return ([], 3)

    def read(self, user_id: UUID, notification_id: UUID) -> bool:
        return self.owns_notification


class _Channel:
    def send(self, tokens: Sequence[str], notice: Notice) -> DeliveryResult:
        return DeliveryResult(sent=len(tokens))


def _profile(role: str = "usuario") -> Profile:
    return Profile(
        id=UUID(int=1),
        uid="uid",
        first_name="Ana",
        last_name="Pérez",
        email="ana@correo.com",
        role=cast(Any, role),
        dni="1",
        birth_date=date(2000, 1, 1),
    )


def test_sin_persona_el_barrido_y_el_despacho_miran_a_todos() -> None:  # @ENG-14-S1
    repo = _Notifications()
    use_cases.dispatch_pending(cast(Any, repo), _Channel())
    use_cases.send_reminders(cast(Any, repo), _Channel(), NOW)
    assert repo.filters == [None, None, None]


def test_sólo_un_usuario_registra_su_teléfono_con_token_y_cuenta_activa() -> None:  # @ENG-14-S1
    repo = cast(Any, _Notifications())
    use_cases.register_device(repo, _profile(), "tok", "ios", True)

    with pytest.raises(Forbidden):
        use_cases.register_device(repo, _profile("admin"), "tok", "ios", True)
    with pytest.raises(InvalidData):
        use_cases.register_device(repo, _profile(), "  ", "ios", True)
    with pytest.raises(Unavailable):
        use_cases.register_device(
            cast(Any, _Notifications(accepts_device=False)), _profile(), "tok", "ios", True
        )


def test_mis_avisos_son_los_del_repositorio_y_leer_uno_ajeno_no_existe() -> None:  # @ENG-14-S1
    assert use_cases.my_notifications(cast(Any, _Notifications()), _profile()) == ([], 3)
    use_cases.mark_read(cast(Any, _Notifications()), _profile(), UUID(int=9))
    with pytest.raises(NotFound):
        use_cases.mark_read(
            cast(Any, _Notifications(owns_notification=False)), _profile(), UUID(int=9)
        )
