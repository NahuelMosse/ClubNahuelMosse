# Supuestos de la documentación

Los supuestos que cambian lo que ve quien usa la app o lo que hace quien la opera están en los README de `apps/api` y
`apps/mobile`; el registro completo de cada caso de uso, en `specs/<caso>/ambiguedades.md`.

- REV-07-ASM-01: donde la app todavía no tiene algo (copias de seguridad, objetivos de servicio medidos, presupuesto de
  rendimiento) el documento lo dice tal cual y escribe el objetivo como meta sin medir.
- REV-07-ASM-02: los README de `apps/api` y `apps/mobile` listan los supuestos que cambian lo que ve quien usa o lo que hace
  quien opera, con su ID, y no los 545 registrados.
- REV-07-ASM-03: el modelo de datos lleva columnas, claves, índices y triggers de cada tabla.
- REV-07-ASM-04: estos documentos se escriben aunque el módulo de documentación del método esté apagado, porque los pide el
  grado de producción.
- REV-07-ASM-05: los documentos describen `main`; los números de hallazgo que citan remiten a la revisión de la rama
  `kit-3`.
- REV-07-ASM-06: las filas de la matriz ASVS que hoy fallan quedan `fails` con el hallazgo y la card que las corrige; los
  plazos de remediación (V15.1.1) los decide una persona.
- REV-07-ASM-08: los precios salen de https://render.com/pricing.md consultado el 2026-10-20; la página no dice si la base
  free tiene backups.
- REV-07-ASM-09: la política de claves con su ciclo de vida, el inventario criptográfico completo y el documento de las vías
  de autenticación (ASVS V11.1.1, V11.1.2, V6.1.3) no estaban pedidos y los decide una persona: esas filas quedan `fails`.

## Estado

La revisión general de `main` está en [`specs/REVISION-main.md`](../specs/REVISION-main.md): qué corrió, qué falla y qué
conviene hacer después. La anterior, de la rama `kit-3`, sigue en `specs/REVISION-kit3.md`; las cards `REV-01` a `REV-08`
corrigieron lo que encontró.
