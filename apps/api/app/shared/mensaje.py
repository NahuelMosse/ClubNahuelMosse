from dataclasses import dataclass


@dataclass(frozen=True)
class Mensaje:
    para: str
    asunto: str
    cuerpo: str
    html: str | None = None
