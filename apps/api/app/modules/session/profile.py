from dataclasses import dataclass
from datetime import date
from typing import Literal
from uuid import UUID

Role = Literal["usuario", "admin"]


@dataclass(frozen=True)
class Profile:
    id: UUID
    uid: str
    first_name: str
    last_name: str
    email: str
    role: Role
    dni: str
    birth_date: date
