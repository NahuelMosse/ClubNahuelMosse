# Handoff SIM-02

Hecho: RED commiteado (369231d); T1 (pyproject, usuario_actual, usuarios/reglas, horarios/reglas, identidad, sedes/casos_de_uso+rutas, administradores, contrasena).

Falta:
- T2 (reservas): `3600` y `23P01` una vez cada uno en reservas/*.py como constantes con nombre; partir mover/insertar/anular/historial a <=40 líneas sin reordenar los bloqueos usuario > sede > espacio > reserva.
- T3 (notificaciones): quitar el alias `reemplaza`, partir encolar_cancelacion_forzosa y entregar.
- T4 (espacios, sedes/repositorio con `actualizar(..., *, confirmar)`, horarios/disponibilidad) y el resto de hallazgos de ruff.

Hallazgos: cd apps/api; UV_PROJECT_ENVIRONMENT=<venv> uv run --no-sync ruff check app --output-format concise

Problema abierto: tests/unit/test_codigo_legible.py (congelado) no pasa ruff (PLR2004 x3 con 10/4, SIM102 x2, C901 en _bloqueos) y el gate lint lo incluye: reemplazarlo por un archivo nuevo con las mismas tags (y Log `replaces:`) con constantes y `_bloqueos` más plano.

Verificación: sh D:/Temp/w/herramientas/arq01-pytest.sh -q -p no:cacheprovider tests/unit/test_codigo_legible.py (rutas relativas a apps/api).
Las firmas públicas (git show main:) no cambian: nombres y orden de parámetros; por eso `peticion: Request` sigue en usuario_actual.
