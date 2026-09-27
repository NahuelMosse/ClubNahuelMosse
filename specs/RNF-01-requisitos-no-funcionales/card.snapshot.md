---
card: RNF-01
extraido: 2026-09-27T14:10:00-03:00
fuentes:
  - "enunciado: Trabajo Práctico_2026.docx.pdf § Requerimientos No Funcionales 1 a 6 — texto de la card, sin CU propio"
  - "enunciado: Trabajo Práctico_2026.docx.pdf § RF 8 Nombre de la aplicación · § RF 9 Nombre del repositorio GITHUB"
  - "enunciado: Trabajo Práctico_2026.docx.pdf § Entregables para evaluación, Entrega 2"
no_leido: []
estado: propuesta
---

# Snapshot — RNF-01 · Requisitos no funcionales y entregables

## Card, tal como está escrita

**RF 8 · Nombre de la aplicación** (fuente: enunciado) — «El nombre de la aplicación debe ser Club
[Nombre y Apellido del alumno o alumna]. Por ejemplo: ClubJuanaGonzalez.»

**RF 9 · Nombre del repositorio GITHUB** (fuente: enunciado) — «El nombre del repositorio de GitHub
deberá coincidir con el nombre de la aplicación.»

**RNF 1 · Aplicación móvil** (fuente: enunciado) — «El diseño de UX/UI se deberá realizar utilizando
Figma» · «La aplicación móvil se deberá realizar utilizando Flutter».

**RNF 2 · Repositorio** (fuente: enunciado) — «El proyecto deberá gestionarse mediante un repositorio
GitHub.» «Cada alumno deberá utilizar su propia cuenta de GitHub y realizar commits durante el
desarrollo del proyecto.» «El historial del repositorio podrá ser considerado como parte del proceso
de evaluación.»

**RNF 3 · REST API** (fuente: enunciado) — «La API REST deberá estar documentada mediante
Swagger/OpenAPI.» «Se podrá elegir el lenguaje que se desee. (Preferentemente Python)».

**RNF 4 · BBDD** (fuente: enunciado) — «Se podrá elegir cualquier base de datos relacional.
(Preferentemente PostgreSQL)».

**RNF 5 · Cloud** (fuente: enunciado) — «La API REST y la base de datos deberán estar disponibles en
la nube.» «Se podrán utilizar servicios como Render para el despliegue de la API y base de datos, y
Firebase para autenticación y notificaciones push.» «Las operaciones de la API relacionadas con
usuarios y reservas deberán identificar al usuario autenticado.»

**RNF 6 · Readme** (fuente: enunciado) — «Tanto la aplicación móvil como el backend deberán contar
con un archivo README que explique todos los pasos necesarios para configurar, ejecutar y, cuando
corresponda, desplegar cada proyecto.»

**Entrega 2** (fuente: enunciado) — «Backend desplegado en la nube y aplicación móvil conectada a la
API REST.» · «Aplicación móvil en Flutter» · «Icono» · «Inicio de sesión, registración y
recuperación de contraseña» · «Gestión de reservas» · «Modelo de datos de la aplicación, incluyendo
entidades, atributos y relaciones.» · «Manejo de errores (…)» · «Mostrar aplicación funcionando en
emulador.» · «Subir a la plataforma Blackboard, antes de la exposición, el código del backend (ZIP) y
el código de la aplicación móvil (ZIP).» · «La Entrega 2 será individual y deberá ser defendida
individualmente.»

## Escenarios

La subida de los ZIP a Blackboard y la defensa son acciones del alumno fuera del sistema: no tienen
escenario. El diseño en Figma es la Entrega 1 y ya existe (`VUiZR6V4USuiyxRgtshhEn`). Los
requisitos funcionales de la Entrega 2 los cubren sus propias cards.

- [ ] RNF-01-H01-01 — la app se llama ClubNahuelMosse en el dispositivo y el repositorio de GitHub tiene el mismo nombre
- [ ] RNF-01-H02-01 — la app es un proyecto Flutter que compila y corre en un emulador Android
- [ ] RNF-01-H03-01 — el repositorio es de la cuenta del alumno y el historial tiene commits a lo largo del desarrollo
- [ ] RNF-01-H04-01 — la API publica su documentación OpenAPI con todos los endpoints que usa la app
- [ ] RNF-01-H05-01 — la API guarda los datos en una base PostgreSQL
- [ ] RNF-01-H06-01 — la API y la base responden desde una URL pública en la nube y la app instalada usa esa URL
- [ ] RNF-01-H06-02 — una operación sobre usuarios o reservas sin usuario autenticado se rechaza
- [ ] RNF-01-H06-03 — una operación sobre reservas actúa sobre el usuario autenticado y no sobre otro indicado en el pedido
- [ ] RNF-01-H07-01 — siguiendo sólo el README de la app se configura y ejecuta la app
- [ ] RNF-01-H07-02 — siguiendo sólo el README del backend se configura, ejecuta y despliega la API
- [ ] RNF-01-H08-01 — la app tiene un ícono propio en el launcher

## Contradicciones dentro de la card

- Ninguna dentro del enunciado. El README es uno por proyecto, y app y API viven en el mismo
  repositorio: cada una lleva el suyo en su carpeta · RNF 6, `.claude/STACK.md`.
