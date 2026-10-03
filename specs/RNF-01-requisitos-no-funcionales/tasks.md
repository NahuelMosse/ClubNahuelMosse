# Tareas — RNF-01

- [x] T1 `AndroidManifest.xml`: `android:label="ClubNahuelMosse"` (H01-01)
- [x] T2 ícono fuente `assets/icono/icono.png`, `flutter_launcher_icons` en `pubspec.yaml`, generar mipmaps (H08-01)
- [x] T3 `apps/mobile/README.md` (H07-01)
- [x] T4 `apps/api/README.md` (H07-02)
- [x] T5 `flutter build apk --debug` compila con el nombre y el ícono (H02-01)
- [x] T6 `sh scripts/test.sh` verde; H06-01 queda «no se pudo correr» (AMB-05)
- [x] T7 READMEs: `GOOGLE_APPLICATION_CREDENTIALS` obligatoria en producción, variables que sólo se leen del entorno, comandos verificados contra los scripts
- [x] T8 `apps/api/.env.example` y test de integración que recorre `app.routes` con la cota de 28 operaciones protegidas
- [x] T9 ícono adaptativo: el primer plano ocupa el 62 % del lienzo
- [x] T10 `render.yaml`: web service de la API y Postgres gestionado en Render (AMB-05)
- [x] T11 `config.py` normaliza la URL de Render a `postgresql+psycopg://`; la cuenta de servicio de Firebase llega en `FIREBASE_CREDENCIALES_JSON`, con tests unitarios
- [x] T12 README de la API con los pasos de Render y README de la app con el APK contra Render; `INTERNET` en el manifiesto principal
- [ ] T13 el usuario despliega el Blueprint y corre `API_URL_NUBE=<URL_PUBLICA> pytest tests/escenarios --card RNF-01` (H06-01: no se pudo correr hasta entonces)
