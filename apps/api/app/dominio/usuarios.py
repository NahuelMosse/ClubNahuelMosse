"""Reglas del perfil de usuario. Los mensajes son los que muestra la app."""

import re
from dataclasses import dataclass
from datetime import date
from typing import Literal

LARGO_MAXIMO_NOMBRE = 60


@dataclass(frozen=True)
class DatosRegistro:
    nombre: str
    apellido: str
    dni: str
    fecha_nacimiento: str
    correo: str
    contrasena: str


@dataclass(frozen=True)
class Registro:
    nombre: str
    apellido: str
    dni: str
    fecha_nacimiento: date
    correo: str
    contrasena: str


_CORREO = re.compile(r"^[^@\s]+@[^@\s]+\.[^@\s]+$")


def normalizar_correo(correo: str) -> str:
    return correo.strip().lower()


def correo_valido(correo: str) -> bool:
    return _CORREO.fullmatch(correo) is not None


def normalizar_dni(dni: str) -> str:
    return re.sub(r"[.\s]", "", dni.strip())


def problemas_contrasena(contrasena: str) -> list[str]:
    """Las reglas que no cumple, en el orden en que las muestra la app."""
    faltan = []
    if len(contrasena) < 8:
        faltan.append("Al menos 8 caracteres")
    if not re.search(r"[A-ZÁÉÍÓÚÑ]", contrasena):
        faltan.append("Una letra mayúscula")
    if not re.search(r"[0-9]", contrasena):
        faltan.append("Al menos un número")
    return faltan


def _fecha(texto: str) -> date | None:
    try:
        return date.fromisoformat(texto.strip())
    except ValueError:
        return None


def validar_registro(datos: DatosRegistro, hoy: date) -> tuple[Registro | None, dict[str, str]]:
    """Devuelve el registro normalizado, o los errores por campo si hay alguno."""
    errores: dict[str, str] = {}

    for campo, valor, obligatorio in (
        ("nombre", datos.nombre, "El nombre es obligatorio"),
        ("apellido", datos.apellido, "El apellido es obligatorio"),
    ):
        limpio = valor.strip()
        if not limpio:
            errores[campo] = obligatorio
        elif len(limpio) > LARGO_MAXIMO_NOMBRE:
            errores[campo] = f"Máximo {LARGO_MAXIMO_NOMBRE} caracteres"

    dni = normalizar_dni(datos.dni)
    if not dni:
        errores["dni"] = "El DNI es obligatorio"
    elif not re.fullmatch(r"[0-9]{7,8}", dni):
        errores["dni"] = "El DNI tiene 7 u 8 números"

    nacimiento = _fecha(datos.fecha_nacimiento)
    if not datos.fecha_nacimiento.strip():
        errores["fecha_nacimiento"] = "La fecha de nacimiento es obligatoria"
    elif nacimiento is None:
        errores["fecha_nacimiento"] = "La fecha no es válida"
    elif nacimiento >= hoy:
        errores["fecha_nacimiento"] = "La fecha tiene que ser anterior a hoy"

    correo = normalizar_correo(datos.correo)
    if not correo:
        errores["correo"] = "El correo es obligatorio"
    elif not _CORREO.fullmatch(correo):
        errores["correo"] = "Revisá el formato del correo"

    if not datos.contrasena:
        errores["contrasena"] = "La contraseña es obligatoria"
    elif faltan := problemas_contrasena(datos.contrasena):
        errores["contrasena"] = faltan[0]

    if errores or nacimiento is None:
        return None, errores
    return (
        Registro(
            nombre=datos.nombre.strip(),
            apellido=datos.apellido.strip(),
            dni=dni,
            fecha_nacimiento=nacimiento,
            correo=correo,
            contrasena=datos.contrasena,
        ),
        {},
    )


Rol = Literal["usuario", "admin"]


@dataclass(frozen=True)
class Perfil:
    id: int
    uid: str
    nombre: str
    apellido: str
    correo: str
    rol: Rol
