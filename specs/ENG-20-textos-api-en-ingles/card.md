# ENG-20 · los textos que produce la API en inglés

status: proposed
cap: 60 min
sources:
  - "pedido (texto) · mensajes del usuario: 2026-10-27 «quiero que termines esa migracion al ingles, y no solo el codigo, quiero que todo pase a ingles» · 2026-10-27 «porque quiero que este en ingles, igual que absolutamente todo en el repo» · 2026-10-30 «continua una horita mas»"
  - "alcance (texto) · la porción del pedido que es esta card, del plan acordado en la sesión: los textos legibles que produce apps/api pasan a inglés (ver L1)"
  - "glosario · docs/technical/glosario-ingles.md (ENG-00): el nombre en inglés de cada término del dominio"
not_read:
  - "no hay Jira: no hay comentarios, adjuntos ni enlaces que leer"

## Specs

- S1 · "error messages (the `detail` texts)" · acceptance: cada mensaje de error que la API devuelve (`detail`, `message` y los textos por campo de `errors`) está en inglés
- S2 · "email subjects and bodies" · acceptance: el asunto y el cuerpo de cada correo que manda la API están en inglés
- S3 · "push notification titles and bodies" · acceptance: el título y el cuerpo de cada aviso push y de cada aviso guardado que la API crea están en inglés
- S4 · "the catalog texts" · acceptance: los nombres de deporte y de tipo que devuelve `/spaces/catalog` están en inglés
- S5 · "the seed data" · acceptance: los datos que la API siembra en una base nueva (el administrador inicial y lo que siembre cada repositorio) están en inglés
- S6 · "Content already stored in the DB stays as is" · acceptance: ninguna migración reescribe filas ya guardadas
- S7 · "Do not remove functionality." · acceptance: mismas rutas, códigos, claves y comportamiento; sólo cambia el texto
- ENG-20-ASM-01 · la API responde en inglés siempre, sin mirar `Accept-Language`: es la lectura más barata de deshacer (agregar localización después no rompe nada); la app muestra el mensaje tal cual llega (la suposición 04 de ENG-19), así que una persona con la app en castellano ve los mensajes de la API en inglés · S1
- ENG-20-ASM-02 · las claves del catálogo (`Futbol`, `F5`…) son valores guardados y del contrato: no cambian; sólo cambian los nombres que se muestran (`Fútbol`→`Football`, `Fútbol 5`→`Football 5`, `Polvo de ladrillo`→`Clay`…) · S4
- ENG-20-ASM-03 · un texto que el glosario no cubre se traduce con su criterio, en inglés llano y con el mismo sentido; el término del dominio es el del glosario (venue, space, booking, slot) · S1

## Tasks

- T1 · S1,S7,ENG-20-ASM-01,ENG-20-ASM-03 · apps/api/app/shared/errors.py (presentation), apps/api/app/shared/input_validation.py (presentation), apps/api/app/shared/identity.py (presentation), apps/api/app/modules/session/current_user.py (presentation), apps/api/app/shared/documented_app.py (presentation), apps/api/app/modules/availability/routes.py (presentation), apps/api/app/modules/bookings/routes.py (presentation), apps/api/app/modules/notifications/routes.py (presentation), apps/api/app/modules/password_recovery/routes.py (presentation), apps/api/app/modules/spaces/routes.py (presentation), apps/api/app/modules/venues/routes.py (presentation), apps/api/app/modules/users/account_routes.py (presentation), apps/api/app/modules/users/registration_routes.py (presentation), apps/api/app/modules/availability/rules.py (rule), apps/api/app/modules/notifications/rules.py (rule), apps/api/app/modules/venues/rules.py (rule), apps/api/app/modules/users/rules.py (rule), apps/api/app/modules/availability/use_cases.py (rule), apps/api/app/modules/bookings/use_cases.py (rule), apps/api/app/modules/spaces/use_cases.py (rule), apps/api/app/modules/venues/use_cases.py (rule), apps/api/app/modules/bookings/repository.py (data), apps/api/app/modules/spaces/repository.py (data), apps/api/app/modules/venues/repository.py (data), apps/api/app/modules/users/password.py (rule), apps/api/app/modules/availability/slots.py (rule) · tests: apps/api/tests/escenarios/test_english_texts.py "an error detail is English @ENG-20-S1"; apps/api/tests/escenarios/test_english_texts.py "a field error message is English @ENG-20-S1"; apps/api/tests/escenarios/test_english_texts.py "the API answers in English whatever Accept-Language says @ENG-20-ASM-01"; apps/api/tests/escenarios/test_english_texts.py "no string literal of the API code is Spanish @ENG-20-ASM-03"; apps/api/tests/escenarios/test_english_texts.py "the routes, codes and keys are main's @ENG-20-S7"
  reuses: cada literal de texto en su lugar; sólo cambia el contenido del string
- T2 · S2,S3 · apps/api/app/modules/bookings/email.py (presentation), apps/api/app/shared/email_template.py (presentation), apps/api/app/modules/password_recovery/use_cases.py (rule), apps/api/app/modules/notifications/push.py (data), apps/api/app/modules/notifications/sweep.py (rule), apps/api/app/modules/notifications/use_cases.py (rule) · tests: apps/api/tests/escenarios/test_english_texts.py "a booking email subject and body are English @ENG-20-S2"; apps/api/tests/escenarios/test_english_texts.py "a notification title and body are English @ENG-20-S3"
  reuses: las plantillas de correo y de aviso existentes; sólo cambia el texto
- T3 · S4,S5,S6,ENG-20-ASM-02 · apps/api/app/modules/spaces/rules.py (rule), apps/api/app/modules/users/seed_admin.py (data), apps/api/app/modules/users/admins.py (data) · tests: apps/api/tests/escenarios/test_english_texts.py "the catalog names are English @ENG-20-S4"; apps/api/tests/escenarios/test_english_texts.py "the catalog keys are main's @ENG-20-ASM-02"; apps/api/tests/escenarios/test_english_texts.py "the seeded data is English @ENG-20-S5"; apps/api/tests/escenarios/test_english_texts.py "no migration of this card rewrites stored rows @ENG-20-S6"
  reuses: apps/api/app/modules/spaces/rules.py CATALOG y apps/api/app/modules/users/seed_admin.py
- T4 · S1,S2,S3,S4,S5 · apps/api/tests/** · los tests de la API que comparan un texto en castellano pasan a compararlo en inglés (refactor-tests)
  new: no escribe lógica de producción

## Changes to existing behavior

- cada texto legible de la API (errores, correos, avisos, catálogo, siembra) pasa de castellano a inglés; rutas, códigos y claves no cambian
- los tests de la API que comparan esos textos cambian el literal (T4); lo que verifican no cambia

## Gate

```
suite [timeout 50 min]: sh D:/Temp/w/herramientas/arq01-pytest.sh -q -p no:cacheprovider -rf {affected}
lint: sh D:/Temp/w/herramientas/eng17-ruff-mypy.sh
app: sh D:/Temp/w/herramientas/arq01-app.sh eng20_app
attacks: sh D:/Temp/w/herramientas/arq01-attacks.sh eng20_app --json --body-limit 1048576 --no-ambient --raw-headers-exempt "uvicorn (h11) responde los pedidos crudos mal formados antes de que lleguen a la app" --write 'POST /venues {"name": "Attack Venue", "address": "Street 1", "opens_at": "08:00", "closes_at": "23:00", "open_days": [1, 2, 3, 4, 5, 6, 7]}' --read /bookings --read /me --openapi app
refactor-tests: los tests de la API que comparan un texto que la API produce cambian el literal castellano por el inglés; lo que verifican no cambia
no-visual: la card no toca ninguna pantalla de la app
no-docs: la card cambia textos, no comportamiento ni contrato
```

## Log

- L1 · 2026-10-27 «quiero que termines esa migracion al ingles, y no solo el codigo, quiero que todo pase a ingles» · 2026-10-27 «porque quiero que este en ingles, igual que absolutamente todo en el repo» · 2026-10-30 «continua una horita mas» · Scope of this card, a slice of that requirement from the plan agreed in session: the human-readable texts the API (apps/api) produces move to English: error messages (the `detail` texts); email subjects and bodies; push notification titles and bodies; the catalog texts; the seed data. Context: The HTTP contract is already English (ENG-18) and the DB is English (ENG-17). The app is bilingual (ENG-19) and shows API messages as they arrive (ENG-19-ASM-04). Whether the API should localize by Accept-Language is an ambiguity; take the cheapest-to-undo reading as an ASM. Content already stored in the DB stays as is (ENG-17-ASM-06). Do not remove functionality.
- L2 · 2026-10-30 · sin Jira: las dudas van directo a ASM (ENG-20-ASM-01..03), sin ronda de preguntas
- L3 · 2026-10-30 · declared · fault-db · la card cambia sólo literales de texto; ningún acceso a la base cambia y la base dañada responde igual que en main
