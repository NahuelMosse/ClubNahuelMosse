# kit-shape: los tipos del mensaje, el destinatario y el enlace reclamado son un solo concepto
from dataclasses import dataclass
from uuid import UUID


@dataclass(frozen=True)
class Mensaje:
    para: str
    asunto: str
    cuerpo: str
    html: str | None = None


@dataclass(frozen=True)
class Destinatario:
    """La cuenta activa a la que se le manda el enlace."""

    id: UUID
    nombre: str
    correo: str


@dataclass(frozen=True)
class EnlaceReclamado:
    """Un enlace que se acaba de marcar como usado, con la cuenta a la que pertenece."""

    id: UUID
    usuario_id: UUID
    uid: str
