#!/bin/sh
# Corre los escenarios de pantalla contra la app real en un emulador de Android.
#
# Uso: sh scripts/e2e.sh [integration_test/<área> ...] [--name "@CU-03-"]
#
# Levanta, sólo para esta corrida, el emulador de Firebase Auth y la API contra una base propia,
# y los baja al terminar. Variables:
#   E2E_DATABASE_URL  base de la corrida; se borra y se migra desde cero (default: club_e2e_test)
#   AUTH_PORT         puerto del emulador de Firebase Auth (default 9099)
#   API_PORT          puerto de la API (default 8000)
#   AVD               AVD a usar si no hay un dispositivo conectado; corre en -read-only
#   FLUTTER, ADB, EMULATOR  ejecutables
set -eu
raiz=$(cd "$(dirname "$0")/.." && pwd)
FLUTTER=${FLUTTER:-flutter}
ADB=${ADB:-adb}
EMULATOR=${EMULATOR:-emulator}
AUTH_PORT=${AUTH_PORT:-9099}
API_PORT=${API_PORT:-8000}
E2E_DATABASE_URL=${E2E_DATABASE_URL:-postgresql+psycopg://club:club@127.0.0.1:5432/club_e2e_test}
tmp=$(mktemp -d)
pids=""

bajar() {
  for pid in $pids; do
    taskkill //PID "$pid" //T //F >/dev/null 2>&1 || kill "$pid" 2>/dev/null || true
  done
  rm -rf "$tmp"
}
trap bajar EXIT INT TERM

esperar_puerto() {
  i=0
  until (echo > "/dev/tcp/127.0.0.1/$1") 2>/dev/null || curl -s -o /dev/null "http://127.0.0.1:$1/"; do
    i=$((i + 1))
    [ "$i" -gt 180 ] && { echo "e2e: nada escucha en el puerto $1" >&2; exit 1; }
    sleep 1
  done
}

echo "e2e: base de la corrida"
cd "$raiz/apps/api"
DATABASE_URL="$E2E_DATABASE_URL" uv run python -c "
import sqlalchemy as sa, sys
url = sa.engine.make_url('$E2E_DATABASE_URL')
if not url.database.endswith('_test'):
    sys.exit('e2e: la base de la corrida tiene que terminar en _test')
admin = sa.create_engine(url.set(database='postgres'), isolation_level='AUTOCOMMIT')
with admin.connect() as c:
    if not c.execute(sa.text('SELECT 1 FROM pg_database WHERE datname = :d'), {'d': url.database}).first():
        c.execute(sa.text(f'CREATE DATABASE {url.database}'))
admin.dispose()
motor = sa.create_engine(url)
with motor.begin() as c:
    c.execute(sa.text('DROP SCHEMA public CASCADE; CREATE SCHEMA public'))
motor.dispose()
"
DATABASE_URL="$E2E_DATABASE_URL" uv run alembic upgrade head >/dev/null

if curl -s -o /dev/null "http://127.0.0.1:$AUTH_PORT/"; then
  echo "e2e: reuso el emulador de Firebase Auth que ya escucha en $AUTH_PORT"
else
  echo "e2e: emulador de Firebase Auth en $AUTH_PORT"
  cat > "$tmp/firebase.json" <<EOF
{ "emulators": { "auth": { "host": "0.0.0.0", "port": $AUTH_PORT }, "ui": { "enabled": false }, "singleProjectMode": true } }
EOF
  cd "$raiz"
  npx firebase emulators:start --only auth --project demo-clubnahuelmosse --config "$tmp/firebase.json" > "$tmp/auth.log" 2>&1 &
  pids="$pids $!"
  esperar_puerto "$AUTH_PORT"
fi

echo "e2e: API en $API_PORT"
cd "$raiz/apps/api"
DATABASE_URL="$E2E_DATABASE_URL" FIREBASE_AUTH_EMULATOR_HOST="127.0.0.1:$AUTH_PORT" \
  FIREBASE_PROJECT_ID=demo-clubnahuelmosse \
  uv run uvicorn app.main:app --host 0.0.0.0 --port "$API_PORT" > "$tmp/api.log" 2>&1 &
pids="$pids $!"
esperar_puerto "$API_PORT"

dispositivo=$("$ADB" devices | awk 'NR > 1 && $2 == "device" { print $1; exit }')
if [ -z "$dispositivo" ]; then
  echo "e2e: arrancando el emulador ${AVD:?definí AVD o conectá un dispositivo} en solo lectura"
  "$EMULATOR" -avd "$AVD" -read-only -no-snapshot-save -no-boot-anim -no-audio > "$tmp/avd.log" 2>&1 &
  pids="$pids $!"
  "$ADB" wait-for-device
  until [ "$("$ADB" shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" = "1" ]; do sleep 2; done
  dispositivo=$("$ADB" devices | awk 'NR > 1 && $2 == "device" { print $1; exit }')
fi

echo "e2e: tests en $dispositivo"
cd "$raiz/apps/mobile"
[ "$#" -eq 0 ] && set -- integration_test
set +e
"$FLUTTER" test "$@" -d "$dispositivo" \
  --dart-define=API_URL="http://10.0.2.2:$API_PORT" \
  --dart-define=AUTH_EMULADOR="10.0.2.2:$AUTH_PORT"
resultado=$?
set -e
if [ "$resultado" -ne 0 ]; then
  echo "e2e: últimas líneas de la API:"; tail -n 20 "$tmp/api.log"
fi
exit "$resultado"
