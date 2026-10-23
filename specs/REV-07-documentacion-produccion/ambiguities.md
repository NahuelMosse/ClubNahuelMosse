# Ambigüedades — REV-07 · documentación de producción

## The ten questions

| Empty case    | the card says: "No existen: `specs/asvs.md` …, `docs/technical/system-design.md` …, ADRs, `THIRD_PARTY_NOTICES.md`, el modelo de costos, el runbook …, la declaración de accesibilidad y el registro de accesibilidad por pantalla"; donde hoy no hay nada que documentar (sin SLOs medidos, sin backups), the card does not say qué se escribe → REV-07-AMB-01
| Duplicates    | the card says: "Están registrados como `SUP-NN`, no `ASM-NN`"; the card does not say si los README repiten los 545 supuestos o eligen → REV-07-AMB-02
| Validation    | the card says: "`specs/asvs.md` (matriz L2, que `.claude/tools/checks/security-l2.mjs` exige)"; el resto de los documentos no tiene un chequeo que los valide → REV-07-AMB-03
| Limits        | the card says: "El modelo de datos documentado … cubre 4 de 9 tablas"; the card does not say el detalle de cada tabla → REV-07-AMB-03
| Permissions   | not applicable: la documentación no cambia quién puede hacer qué
| State         | not applicable: la card no agrega estados
| Error         | not applicable: la card no cambia comportamiento
| Order         | not applicable: la card no ordena nada que se muestre
| Concurrency   | not applicable: la card no agrega operaciones
| Trail         | the card says: "Ningún de los 545 supuestos está en `apps/api/README.md` ni en `apps/mobile/README.md`, y no hay README en la raíz"; the card does not say cuáles van → REV-07-AMB-02; y el módulo docs del kit está apagado → REV-07-AMB-04

## Events

REV-07-AMB-00 · 2026-10-20 · snapshot · frozen at 3b040b0
REV-07-AMB-01 · 2026-10-20 · no channel · Donde la app todavía no tiene algo (copias de seguridad, objetivos de servicio medidos, presupuesto de rendimiento), ¿el documento lo dice tal cual y propone un objetivo, o se deja el apartado afuera? → REV-07-ASM-01 · leaves without effect: «describe la app como es hoy» para los objetivos, que se escriben como metas sin medir
REV-07-AMB-02 · 2026-10-20 · no channel · ¿Qué decisiones tomadas sin respuesta tienen que estar en los README: todas, o las que cambian lo que ve quien usa o quien opera la app? → REV-07-ASM-02
REV-07-AMB-03 · 2026-10-20 · no channel · ¿Cuánto detalle lleva el modelo de datos: columnas, claves e índices de cada tabla, o sólo qué guarda cada una? → REV-07-ASM-03
REV-07-AMB-04 · 2026-10-20 · no channel · La documentación para usuarios del kit está apagada en este repo: ¿estos documentos de operación se escriben igual? → REV-07-ASM-04
REV-07-AMB-05 · 2026-10-20 · no channel · Otras correcciones en curso van a cambiar la seguridad, los datos y la operación: ¿cada una actualiza estos documentos al terminar? → REV-07-ASM-05
REV-07-OUT-01 · 2026-10-20 · proposal · los supuestos viejos se llaman SUP-NN y los snapshots usan fuentes: y no_leido:; corregirlo cambia snapshots congelados (hallazgos 22 y 24) — not touched
REV-07-OUT-02 · 2026-10-20 · medium · specs/MOD-01-modelo-de-datos/data-model.md · documenta 4 de 9 tablas; el modelo completo queda en docs/technical/system-design.md — not touched
REV-07-TESTS · 2026-10-20 · frozen at 7dbf987
REV-07-OUT-03 · 2026-10-20 · medium · apps/mobile/lib/sesion/sesion.dart:120, apps/api/app/infraestructura/identidad.py:98-105 · cerrar sesión es local: la API no revoca el token y uno robado sirve hasta que vence (ASVS V7.4.1); tampoco hay tiempo de inactividad, máximo absoluto, límite de sesiones ni cierre de sesiones por el usuario o el admin (V7.1.1, V7.1.2, V7.3.1, V7.3.2, V7.4.5, V7.5.2) — not touched
REV-07-OUT-04 · 2026-10-20 · medium · apps/api/app/dominio/usuarios.py:46-55 · la contraseña exige mayúscula y número y no se compara con contraseñas comunes, filtradas ni palabras del contexto (ASVS V6.2.4, V6.2.5, V6.2.11, V6.2.12, V6.1.2); sin segundo factor (V6.3.3) — not touched
REV-07-OUT-05 · 2026-10-20 · low · apps/api/app/aplicacion/recuperacion.py:17 · el enlace de recuperación vive 30 minutos; ASVS V6.5.5 pide 10 como máximo — not touched
REV-07-OUT-06 · 2026-10-20 · low · apps/api/app/interfaz/protecciones.py:5 · no se emite Referrer-Policy (ASVS V3.4.5) — not touched
REV-07-OUT-07 · 2026-10-20 · low · apps/api/app/interfaz/registro_errores.py:6,58-59 · no se registran los inicios de sesión ni los intentos de saltar controles (422), y no hay eventos de seguridad definidos (ASVS V16.3.1, V16.3.3) — not touched
REV-07-OUT-08 · 2026-10-20 · low · docs/technical/system-design.md · faltan la política de claves con su ciclo de vida, el inventario criptográfico y el documento de las vías de autenticación (ASVS V11.1.1, V11.1.2, V6.1.3); los decide una persona — not touched
REV-07-OUT-08 · 2026-10-20 · withdrawn · apunta a un documento que crea esta card; queda como REV-07-ASM-09
REV-07-ASM-09 · 2026-10-20 · la política de claves con su ciclo de vida, el inventario criptográfico completo y el documento de las vías de autenticación (ASVS V11.1.1, V11.1.2, V6.1.3) no estaban pedidos y los decide una persona: las filas quedan `fails` con esa razón · any-answer: yes
