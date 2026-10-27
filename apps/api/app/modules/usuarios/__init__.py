from fastapi import APIRouter

from app.modules.usuarios.reglas import correo_valido, normalizar_correo, problemas_contrasena
from app.modules.usuarios.repositorio import UsuariosSql, repositorio_usuarios
from app.modules.usuarios.rutas_cuenta import router as _rutas_cuenta
from app.modules.usuarios.rutas_registro import router as _rutas_registro

router = APIRouter()
router.include_router(_rutas_registro)
router.include_router(_rutas_cuenta)

__all__ = [
    "UsuariosSql",
    "correo_valido",
    "normalizar_correo",
    "problemas_contrasena",
    "repositorio_usuarios",
    "router",
]
