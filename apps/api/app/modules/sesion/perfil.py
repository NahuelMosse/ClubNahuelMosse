from dataclasses import dataclass
from datetime import date
from typing import Literal
from uuid import UUID

Rol = Literal["usuario", "admin"]


@dataclass(frozen=True)
class Perfil:
    id: UUID
    uid: str
    nombre: str
    apellido: str
    correo: str
    rol: Rol
    dni: str
    fecha_nacimiento: date
