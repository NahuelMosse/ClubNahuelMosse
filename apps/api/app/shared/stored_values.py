"""Translation between the values the HTTP contract speaks (Spanish) and the ones the database stores (English).

The contract keeps its values until the contract card renames them; the tables already store the English ones.
Both enumerations are closed: a value that is not listed is an error, never a default.
"""

_STORED_BY_CONTRACT = {
    # roles
    "usuario": "user",
    "admin": "admin",
    # booking status
    "activa": "active",
    "cancelada": "canceled",
    "anulada": "voided",
    "completada": "completed",  # only produced by the view booking_with_status
    # notification kinds
    "recordatorio": "reminder",
    "recordatorio_cinco": "five_minute_reminder",
    "cancelacion_forzosa": "forced_cancellation",
    "cancelacion_usuario": "user_cancellation",
    # notification delivery
    "pendiente": "pending",
    "enviando": "sending",
    "enviada": "sent",
    "sin_permiso": "no_permission",
    "sin_canal": "no_channel",
    "fallida": "failed",
}
_CONTRACT_BY_STORED = {stored: contract for contract, stored in _STORED_BY_CONTRACT.items()}


def stored(contract_value: str) -> str:
    """The value the database keeps for a value of the contract; KeyError if it is not one."""
    return _STORED_BY_CONTRACT[contract_value]


def contract(stored_value: str) -> str:
    """The value the contract shows for a value of the database; KeyError if it is not one."""
    return _CONTRACT_BY_STORED[stored_value]
