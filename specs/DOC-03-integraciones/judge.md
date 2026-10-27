- ACT-01 · H · S2 pide nombrar «las variables de entorno o de compilación que necesita» cada integración, pero ningún spec, ASM ni test dice que el documento cita solo el nombre y nunca el valor (clave de Brevo, cuenta de servicio de Firebase, `DATABASE_URL` con contraseña de `render.yaml`); el test de ASM-01 comprueba que existan, no que falten secretos. Pregunta abierta: «Does a log line or an error echo personal data or a secret?» · card.md L14, L15 · plan · closed · DOC-03-ASM-03
- ACT-02 · M · S2 exige que «cada sección» nombre archivos «de la API y de la app» y «cómo se prueba en local», pero S1 incluye miembros donde eso no aplica (Render, el monitor que mantiene despierta la API, PostgreSQL sin archivo en la app); no hay AMB/ASM sobre qué escribe la sección cuando un elemento no existe, y el test «cada sección nombra sus archivos, variables y cómo se prueba en local» falla o empuja a inventar contenido. Pregunta abierta: «Does a quantifier ("each", "all", "any") name its members, and does each member have a test?» / «Which reading works with any answer to the open question, and is that the one assumed?» · card.md L13, L14, L20 · plan · closed · DOC-03-ASM-04, S2
- ACT-03 · L · S1 y S2 agregan «qué pasa si el servicio no responde» y «cómo se prueba en local», que L1 («hablar de las integraciones y donde se hace cada una») no pide; no está declarado como ASM. Pregunta abierta: «Does each S# say the same as the sentence it quotes, no less and no more?» · card.md L13, L14, L37 · plan · closed · S1 y S2 sin lo que L1 no pide; DOC-03-ASM-04

## Verified

- interpretation · fails (ACT-02, ACT-03)
- security · fails (ACT-01)
- overdesign · meets · T1 son tres `.md` y un test unitario; sin capas, interfaces ni patrones
