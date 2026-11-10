#!/bin/sh
# Runs the screen scenarios against the real app on an Android emulator.
#
# Usage: sh scripts/e2e.sh [integration_test/<area> ...] [--name "@CU-03-"]
#
# For this run only, it starts the Firebase Auth emulator and the API against a database of its
# own, and stops them at the end. Variables:
#   E2E_DATABASE_URL  database of the run; it is dropped and migrated from scratch (default: club_e2e_test)
#   AUTH_PORT         port of the Firebase Auth emulator (default 9099)
#   API_PORT          port of the API (default 8000)
#   ADMIN_EMAIL, ADMIN_PASSWORD  the administrator account seeded for the run
#   DEVICE            serial of the device (required if more than one is connected)
#   AVD               AVD to use if no device is connected; it runs with -read-only
#   FLUTTER, ADB, EMULATOR  executables
set -eu
root=$(cd "$(dirname "$0")/.." && pwd)
FLUTTER=${FLUTTER:-flutter}
ADB=${ADB:-adb}
EMULATOR=${EMULATOR:-emulator}
AUTH_PORT=${AUTH_PORT:-9099}
API_PORT=${API_PORT:-8000}
E2E_DATABASE_URL=${E2E_DATABASE_URL:-postgresql+psycopg://club:club@127.0.0.1:5432/club_e2e_test}
# It lives only in the run's emulator, which has no real data: it is not a secret.
ADMIN_EMAIL=${ADMIN_EMAIL:-admin.e2e@clubnahuelmosse.test}
ADMIN_PASSWORD=${ADMIN_PASSWORD:-AdminE2e1}
tmp=$(mktemp -d)
pids=""

stop_all() {
  for pid in $pids; do
    # In Git Bash, $! is the MSYS PID: the Windows tree is stopped by its own PID.
    winpid=$(cat "/proc/$pid/winpid" 2>/dev/null || true)
    if [ -n "$winpid" ]; then
      taskkill //PID "$winpid" //T //F >/dev/null 2>&1 || true
    else
      kill "$pid" 2>/dev/null || true
    fi
  done
  rm -rf "$tmp"
}
trap stop_all EXIT INT TERM

wait_for_port() {
  i=0
  until (echo > "/dev/tcp/127.0.0.1/$1") 2>/dev/null || curl -s -o /dev/null "http://127.0.0.1:$1/"; do
    i=$((i + 1))
    [ "$i" -gt 180 ] && { echo "e2e: nothing listens on port $1" >&2; exit 1; }
    sleep 1
  done
}

echo "e2e: database of the run"
cd "$root/apps/api"
DATABASE_URL="$E2E_DATABASE_URL" uv run python -c "
import sqlalchemy as sa, sys
url = sa.engine.make_url('$E2E_DATABASE_URL')
if not url.database.endswith('_test'):
    sys.exit('e2e: the database of the run must end in _test')
admin = sa.create_engine(url.set(database='postgres'), isolation_level='AUTOCOMMIT')
with admin.connect() as c:
    if not c.execute(sa.text('SELECT 1 FROM pg_database WHERE datname = :d'), {'d': url.database}).first():
        c.execute(sa.text(f'CREATE DATABASE {url.database}'))
admin.dispose()
engine = sa.create_engine(url)
with engine.begin() as c:
    c.execute(sa.text('DROP SCHEMA public CASCADE; CREATE SCHEMA public'))
engine.dispose()
"
DATABASE_URL="$E2E_DATABASE_URL" uv run alembic upgrade head >/dev/null

if curl -s -o /dev/null "http://127.0.0.1:$AUTH_PORT/"; then
  echo "e2e: reusing the Firebase Auth emulator already listening on $AUTH_PORT"
else
  echo "e2e: Firebase Auth emulator on $AUTH_PORT"
  cat > "$tmp/firebase.json" <<EOF
{ "emulators": { "auth": { "host": "0.0.0.0", "port": $AUTH_PORT }, "ui": { "enabled": false }, "singleProjectMode": true } }
EOF
  cd "$root"
  npx firebase emulators:start --only auth --project demo-clubnahuelmosse --config "$tmp/firebase.json" > "$tmp/auth.log" 2>&1 &
  pids="$pids $!"
  wait_for_port "$AUTH_PORT"
fi

echo "e2e: administrator $ADMIN_EMAIL"
cd "$root/apps/api"
DATABASE_URL="$E2E_DATABASE_URL" FIREBASE_AUTH_EMULATOR_HOST="127.0.0.1:$AUTH_PORT" \
  FIREBASE_PROJECT_ID=demo-clubnahuelmosse ADMIN_PASSWORD="$ADMIN_PASSWORD" \
  uv run python -m app.modules.users.seed_admin --email "$ADMIN_EMAIL" \
  --first-name Administración --last-name Club --dni 20000001 --birth-date 1980-01-01 >/dev/null

echo "e2e: API on $API_PORT"
DATABASE_URL="$E2E_DATABASE_URL" FIREBASE_AUTH_EMULATOR_HOST="127.0.0.1:$AUTH_PORT" \
  FIREBASE_PROJECT_ID=demo-clubnahuelmosse E2E_TESTING=1 EMAIL_MODE=outbox \
  uv run uvicorn app.main:app --host 0.0.0.0 --port "$API_PORT" > "$tmp/api.log" 2>&1 &
api_pid=$!
pids="$pids $api_pid"
wait_for_port "$API_PORT"
if ! kill -0 "$api_pid" 2>/dev/null; then
  echo "e2e: another process holds port $API_PORT; the API of the run did not start" >&2
  tail -n 20 "$tmp/api.log" >&2
  exit 1
fi

device=${DEVICE:-}
if [ -z "$device" ]; then
  connected=$("$ADB" devices | awk 'NR > 1 && $2 == "device" { print $1 }')
  if [ "$(echo "$connected" | grep -c .)" -gt 1 ]; then
    echo "e2e: more than one device is connected; pick one with DEVICE=<serial>:" >&2
    echo "$connected" >&2
    exit 1
  fi
  device=$connected
fi
if [ -z "$device" ]; then
  echo "e2e: starting the emulator ${AVD:?set AVD or connect a device} read-only"
  "$EMULATOR" -avd "$AVD" -read-only -no-snapshot-save -no-boot-anim -no-audio > "$tmp/avd.log" 2>&1 &
  pids="$pids $!"
  "$ADB" wait-for-device
  until [ "$("$ADB" shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" = "1" ]; do sleep 2; done
  device=$("$ADB" devices | awk 'NR > 1 && $2 == "device" { print $1; exit }')
fi

echo "e2e: tests on $device"
cd "$root/apps/mobile"
[ "$#" -eq 0 ] && set -- integration_test
set +e
"$FLUTTER" test "$@" -d "$device" \
  --dart-define=API_URL="http://10.0.2.2:$API_PORT" \
  --dart-define=AUTH_EMULATOR="10.0.2.2:$AUTH_PORT" \
  --dart-define=ADMIN_EMAIL="$ADMIN_EMAIL" \
  --dart-define=ADMIN_PASSWORD="$ADMIN_PASSWORD"
result=$?
set -e
if [ "$result" -ne 0 ]; then
  echo "e2e: last lines of the API:"; tail -n 20 "$tmp/api.log"
fi
exit "$result"
