# DOC-09 · el README lleva el logo de la app y sus mejores cuatro capturas

status: proposed
cap: 30 min
sources:
  - "pedido (texto) · mensajes del usuario en la sesión (2026-10-27): «el logo lo podes poner en el readme» · «y pone las mejores 4 screanshoots en el readme»"
  - "repo · README.md (4 capturas: inicio, horarios, listo, avisos); apps/mobile/assets/icono/icono.png (el ícono de la app: isotipo sobre verde eléctrico); capturas de DOC-05 en git (edb519f~1:docs/capturas/): login, sedes, sede, confirmar, reservas, perfil, inicio claro, admin; apps/api/tests/unit/test_readme_conciso.py (DOC-06: a lo sumo 4 imágenes en todo el README)"
not_read:
  - "Jira: no hay ticket; el pedido llegó como texto"

## Specs

- S1 · "el logo lo podes poner en el readme" · acceptance: el README abre con el logo de la app (el mismo ícono del launcher), centrado, arriba del nombre
- S2 · "pone las mejores 4 screanshoots en el readme" · acceptance: el README muestra cuatro capturas en una fila: inicio de sesión, sedes, horarios y reserva confirmada; en docs/capturas no queda ninguna sin usar
- DOC-09-ASM-01 · «las mejores» son las que muestran el recorrido de reservar con más foto y color: inicio de sesión, sedes, horarios y reserva confirmada; inicio y avisos salen (el inicio de la captura dice «BUENOS DÍAS» a las 16:53) · S2
- DOC-09-ASM-02 · el logo vive en docs/logo.png, fuera de docs/capturas, y no cuenta como captura · S1

## Tasks

- T1 · S1,S2,DOC-09-ASM-01,DOC-09-ASM-02 · README.md (presentation), docs/logo.png (presentation), docs/capturas/01-login.jpg (presentation), docs/capturas/03-sedes.jpg (presentation), docs/capturas/02-inicio.jpg (presentation), docs/capturas/09-avisos.jpg (presentation) · tests: apps/api/tests/unit/test_readme_logo_y_capturas.py "el README abre con el logo de la app arriba del nombre @DOC-09-S1 @assumption:DOC-09-ASM-02"; apps/api/tests/unit/test_readme_logo_y_capturas.py "el README muestra en una fila inicio de sesión, sedes, horarios y reserva confirmada, sin capturas sin usar @DOC-09-S2 @assumption:DOC-09-ASM-01"
  reuses: apps/mobile/assets/icono/icono.png

## Changes to existing behavior

- el README suma el logo y cambia dos de sus cuatro capturas

## Gate

```
suite: sh D:/Temp/w/herramientas/arq01-pytest.sh -q -p no:cacheprovider apps/api/tests/unit/test_readme_logo_y_capturas.py apps/api/tests/unit/test_readme_conciso.py
lint: sh D:/Temp/w/herramientas/sim01-ruff-mypy-flutter-analyze.sh apps/api/tests/unit/test_readme_logo_y_capturas.py
no-docs: la card cambia el README mismo
no-visual: el README no es una pantalla de la app
```

## Log

- L1 · el logo lo podes poner en el readme · y pone las mejores 4 screanshoots en el readme
- L2 · 2026-10-27 · declared · fault-db · la card no toca la base
- L3 · 2026-10-27 · declared · attacks · la card no toca la API
- L4 · 2026-10-27 · replaces: apps/api/tests/unit/test_readme_conciso.py "el README muestra a lo sumo 4 capturas en una fila y no quedan capturas sin usar @DOC-06-S1" · cuenta toda imagen del README como captura y el logo no lo es · by: apps/api/tests/unit/test_readme_logo_y_capturas.py "el README muestra en una fila inicio de sesión, sedes, horarios y reserva confirmada, sin capturas sin usar @DOC-09-S2 @assumption:DOC-09-ASM-01"
