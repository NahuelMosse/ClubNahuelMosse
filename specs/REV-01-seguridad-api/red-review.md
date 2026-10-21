# Red review · REV-01 · seguridad de la API

Fuente: `card.snapshot.md` (19 escenarios), `## Assumptions` y `## Perimeter` del plan, `tests/escenarios/test_seguridad_api.py` (28 tests) y la corrida en rojo `D:/Temp/rojo-rev01.log` (28 failed). No se editó ningún test.

## Resumen

| Escenario | Test | ¿Prueba por la interfaz? | Rojo por la razón correcta | Veredicto |
|---|---|---|---|---|
| H01-01 | `test_el_correo_exige_un_certificado_valido…` | función `correo.enviar` con SMTP doble | sí (`context=None`) | falta el flujo de falla (ver R-03) |
| H05-01 | `test_una_reserva_con_horas_desmesuradas…` | HTTP | sí (OverflowError) | faltan formas y bordes (R-04) |
| H05-02 | `test_una_reserva_al_final_del_calendario…` | HTTP | sí (date out of range) | ok |
| H05-03 | `test_una_pagina_enorme…` | HTTP | sí (bigint out of range) | faltan formas y bordes (R-04) |
| H05-04 | 7 parametrizaciones | HTTP | 5 de 7 (R-05) | cubre 7 de ~16 rutas con texto (R-02) |
| H06-01 | `test_las_recuperaciones_en_rafaga…` | HTTP | sí (202) | falta borde y respuesta del 429 (R-06) |
| H06-02 | `test_los_registros_en_rafaga…` | HTTP | sí (422) | idem |
| H06-03 | `test_probar_dni_ajenos…` | HTTP | sí (200) | ok bajo ASM-01; borde no fijado |
| H06-04 | `test_probar_correos_ajenos…` | HTTP | sí (409) | ok bajo ASM-01 |
| H07-01 | `test_la_api_no_usa_un_certifi…` | `uv.lock` | sí | ok |
| H09-01 | `test_un_rechazo_del_servidor_de_correo…` | función | sí | ok |
| H09-02 | `test_el_log_de_accesos…` | uvicorn real | **no**: `UnicodeDecodeError` al leer el log | R-01 |
| H09-03 | `test_una_ruta_con_saltos_de_linea…` | HTTP | sí | falta `\r` (R-07) |
| H09-04 | `test_los_secretos_no_llegan…` | HTTP | sí (eco de `input` en 422) | cobertura parcial (R-08) |
| H16-01 | 3 tests (config, `render.yaml`, contrato) | app + blueprint | sí | falta el health check (R-09) |
| H16-02 | `test_las_respuestas_impiden…` | HTTP | sí | respuestas de error sin cubrir (L) |
| H25-01 | `test_un_host_ajeno_se_rechaza` | HTTP | sí (401) | caso positivo frágil, sin token ni escritura (R-10) |
| H25-02 | 2 tests | `crear_app()` | sí | falta `GOOGLE_APPLICATION_CREDENTIALS` y el positivo (R-11) |
| H25-03 | `test_el_token_de_otra_persona…` | HTTP + base | sí (`NoResultFound`) | falta el traspaso legítimo (R-12) |

## Hallazgos

### R-01 · H · H09-02 está en rojo por una razón ajena al escenario
`test_el_log_de_accesos_no_guarda_lo_que_busca_el_administrador` falla en `salida.read_text(encoding="utf-8")` con `UnicodeDecodeError: byte 0xf3` (log, línea 4647): uvicorn escribe la línea propia `usuario=anónimo` en la codificación de la consola, no en UTF-8, aunque el fixture pone `PYTHONUTF8=1`. El test nunca llega a las aserciones de correo/DNI. Con la corrección el test puede seguir rojo por lo mismo, o quedar verde por un cambio de codificación que no tiene que ver con el hallazgo. Un rojo que no es el del escenario no prueba nada.

### R-02 · M · H05-04 dice «todas las rutas que reciben texto» y prueba 7
Rutas que reciben texto sin caso de NUL: `POST /espacios`, `PUT /espacios/{id}`, `PUT /sedes/{id}`, `PUT /yo/contrasena`, `PUT /recuperacion` (código y contraseña nueva), `POST /reservas/{id}/cancelar`, `POST /reservas/{id}/modificar` (si lleva texto), `POST /dispositivos/baja` (token) y el query `q` de `GET /reservas/todas`. El escenario es literal («todas»); el hallazgo 5 sólo midió 7. Además sólo se prueba `\x00`: ASM-02 dice «NUL o caracteres de control → 422» y ningún test manda otro control (`\x1b`, `\n` en un nombre). Tampoco hay ningún caso de los largos máximos de ASM-02 (correo 254, token 4096, búsqueda 100…), que son la «cota» que pide el título del hallazgo 5.

### R-03 · M · H01-01 no prueba qué pasa cuando el certificado falla
El test sólo mira el `SSLContext` pasado a `starttls`. ASM-06 fija la consecuencia: el envío falla, se registra sin la dirección y la persona ve 202. No hay test donde `starttls` lance `ssl.SSLCertVerificationError` y se verifique: (a) que `login` no se llama (las credenciales SMTP no salen, que es el impacto del hallazgo), (b) que `POST /recuperacion` sigue respondiendo 202, (c) que el log no lleva el correo. Además el doble está atado a `starttls(context=…)`: una implementación con `SMTP_SSL(context=…)` u otro camino correcto deja el test rojo; es acoplamiento a la forma, no al comportamiento (el perímetro ya declara que no hay TLS real).

### R-04 · M · H05-01 y H05-03: un solo valor desmesurado, sin formas de entrada ni bordes
`horas` sólo con `10**12`; `pagina` sólo con `2**70`. Faltan: ausente, `null`, tipo equivocado (`"4"`, `true`, `1.5`), `0`, negativo, y los bordes de ASM-02: `horas` 4 aceptado / 5 rechazado, `pagina` 10000 aceptado / 10001 rechazado, `pagina=0` y `pagina=-1`. Sin el borde, una cota mal puesta (p. ej. `horas ≤ 10**6`) pasa el test y el 500 sigue con `horas=10**7`. H05-02 tampoco prueba `9999-12-31 23:00 horas 1` (termina en 10000-01-01, mismo desborde con el mínimo de horas).

### R-05 · M · dos casos de H05-04 están en rojo por otra causa
- `POST /recuperacion/consulta` con NUL hoy da **410**, no 500 (log 2464): el hallazgo no se reproduce en esa ruta con ese cuerpo y el test sólo exige un cambio de código.
- `POST /reservas/999999999/anular` hoy da **422 sin `errores`** (log 4418): ya no es 500; y la reserva no existe, así que el valor nunca llegaría a la base. Con una reserva real (la del hallazgo) el test probaría el 500 medido; con un id inexistente no lo prueba.

### R-06 · M · H06-01/02: no se fija el límite, la respuesta del 429 ni el origen
Sólo se mira el primer y el último código de 30/20 pedidos. Falta: el borde de ASM-03 (el 10.º pasa, el 11.º da 429), `Retry-After: 60` y el cuerpo `{"mensaje": …}` del 429, que otro origen no quede frenado (ASM-11: el origen es la IP / `X-Forwarded-For`; no hay test de que un `X-Forwarded-For` falso rote el origen y saltee el límite sin proxy), y que H06-01 siga respondiendo igual exista o no el correo dentro del límite (regla de seguridad de CU-04b). H06-03: sólo `codigos[-1] == 429` con 20 pedidos; no fija «10 por hora por cuenta» ni que el límite no corte el primer cambio de perfil legítimo.

### R-07 · L · H09-03 sólo prueba `\n`
El ataque del hallazgo usa `%0a`; `%0d` (`\r`) también parte líneas en muchos visores y no se prueba. Tampoco se prueba la línea de rechazo nueva de ASM-09 (429 y Host ajeno registran «ruta escapada»).

### R-08 · M · H09-04 cubre un solo camino de cada secreto
La contraseña sólo se manda con **tipo equivocado** (`"nueva": ["Clave9Secreta"]`) a `PUT /recuperacion`. No se prueba: `POST /registro` y `PUT /yo/contrasena` con contraseña inválida (corta, larga) que FastAPI repite en `input`; el código de recuperación en un `PUT /recuperacion` con forma válida; el log de accesos de uvicorn (sólo se mira `caplog` de la app); la contraseña SMTP (impacto del hallazgo 1). El escenario nombra «contraseñas, tokens y códigos».

### R-09 · H · H16-01 deja sin test el health check de Render
La contradicción del snapshot («Health check y /docs») sigue: con `DOCUMENTACION_INTERACTIVA=false` en `render.yaml` y `render.yaml:14` apuntando a `/docs`, el deploy queda sin chequeo válido. ASM-07 resuelve con `GET /health`; ningún test verifica que `/health` responda 200 con la documentación apagada ni que `healthCheckPath` del blueprint ya no sea `/docs`. Además el hallazgo dice «ni linteado»: el contrato versionado se compara, pero no se lintea (observación).

### R-10 · M · H25-01: el caso positivo depende de `testserver`, y falta lo que midió el hallazgo
`propio = api.get("/yo")` usa el Host por defecto de TestClient (`testserver`), que no está en la lista de ASM-12; el test sólo puede pasar si la implementación agrega `testserver` o la configuración de pruebas lo hace, y no prueba que el Host real (`URL_PUBLICA`, `localhost:8000` con puerto, `10.0.2.2` del emulador Android) pase. El hallazgo midió el ataque **con token** y en una escritura (200/201); el test lo hace sin token sobre un GET. Tampoco `X-Forwarded-Host` ajeno.

### R-11 · L · H25-02: falta una variante de ASM-10 y el caso que debe arrancar
No hay caso con `GOOGLE_APPLICATION_CREDENTIALS` (ASM-10 la nombra). Ningún test afirma que emulador + proyecto `demo-` + sin credenciales **sí** arranca (sólo lo cubre de forma indirecta el resto de la suite). La negativa se prueba en `crear_app()`, no en el arranque real (`uvicorn app.main:app`, que el fixture `servidor` ya sabe levantar).

### R-12 · M · H25-03: falta el traspaso legítimo que ASM-04 marca como riesgo
ASM-04 es `any-answer: no` justamente por el teléfono compartido. No hay test de: dueña da de baja su token (o cierra sesión) y la segunda persona lo registra → pasa a la segunda. Sin él, una implementación que nunca reasigna un token pasa el test y rompe los avisos del segundo usuario. Tampoco se prueba que la dueña re-registrando su propio token siga en 204 y activo.

## Observaciones

- Los límites de ASM-08 viven en memoria «de cada instancia»; `api` crea una app por test, así que hoy no se cruzan. Si el contador queda a nivel de módulo, las altas de `_alta_socio` del resto de la suite (mismo origen `testclient`) chocarían con el límite de `/registro`: ningún test lo fija.
- H06-03/H06-04 dependen de ASM-01 (`any-answer: no`): los mensajes de duplicado se mantienen por CU-03 FA2; los tests sólo prueban el freno.
- H16-02 no mira las cabeceras en respuestas de error (404, 422, 429, 500).
- H07-01 sólo mira certifi; el escenario no pide más.
