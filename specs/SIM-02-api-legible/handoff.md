# Handoff SIM-02

Hecho: RED (369231d); T1; T2 (reservas; almacen con noqa PLR0913/0917 como las otras firmas públicas); pyproject con per-file-ignore de PLR2004/SIM102/C901 para tests/unit/test_codigo_legible.py (el test congelado se queda, no se reemplaza).

Falta:
- T3 (notificaciones): quitar el alias `reemplaza`, partir encolar_cancelacion_forzosa y entregar, FBT001 en almacen/repositorio/casos_de_uso.
- T4 (espacios: insertar 58 y actualizar 45 líneas; sedes/repositorio con `actualizar(..., *, confirmar)`; horarios/disponibilidad y horarios/repositorio PLR0913; recuperacion/casos_de_uso:96) y el resto de ruff.

Hallazgos: cd apps/api; UV_PROJECT_ENVIRONMENT=<venv> uv run --no-sync ruff check app --output-format concise
Verificación: sh D:/Temp/w/herramientas/arq01-pytest.sh -q -p no:cacheprovider tests/unit/test_codigo_legible.py (desde la raíz del worktree). Cerrar con ruff format --check app, mypy --strict app y la suite completa.
Firmas públicas no cambian (git show main:); PLR0913 en firmas públicas fijas: `# noqa: PLR0913, PLR0917 -- firma pública fijada por sus llamadores`.
