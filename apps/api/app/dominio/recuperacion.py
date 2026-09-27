from dataclasses import dataclass


@dataclass(frozen=True)
class Destinatario:
    """La cuenta activa a la que se le manda el enlace."""

    id: int
    nombre: str
    correo: str


@dataclass(frozen=True)
class EnlaceReclamado:
    """Un enlace que se acaba de marcar como usado, con la cuenta a la que pertenece."""

    id: int
    usuario_id: int
    uid: str
