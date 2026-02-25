#!/bin/bash
set -e

# Web app strategy when schema is missing:
#   1. Drop all user tables (preserve extensions like PostGIS / pgcrypto).
#   2. db:schema:load — retried up to 3 times (PostGIS init can race on first boot).
#   3. db:seed — runs once, on fresh DB only.
#   4. db:migrate — applies any pending migrations (no-op if none).
#
# Worker strategy when schema is missing:
#   1. Wait (poll every 5 s) until the "procedures" table exists.
#   2. db:migrate — applies any pending migrations (no-op if none).

psql_cmd() {
  PGPASSWORD="${DB_PASSWORD}" psql \
    -h "${DB_HOST}" \
    -p "${DB_PORT:-5432}" \
    -U "${DB_USERNAME}" \
    -d "${DB_DATABASE}" \
    "$@"
}

drop_all_tables() {
  psql_cmd -c "
    DO \$\$
    DECLARE r RECORD;
    BEGIN
      FOR r IN (SELECT tablename FROM pg_tables WHERE schemaname = 'public') LOOP
        EXECUTE 'DROP TABLE IF EXISTS ' || quote_ident(r.tablename) || ' CASCADE';
      END LOOP;
    END \$\$;
  " 2>/dev/null || true
}

schema_load() {
  DISABLE_DATABASE_ENVIRONMENT_CHECK=1 bundle exec rails db:schema:load
}

procedures_exists() {
  psql_cmd -tAc \
    "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'procedures';" \
    2>/dev/null || echo "0"
}

echo "[entrypoint] Checking database state..."

if [ "$(procedures_exists)" = "0" ]; then
  # Distinguish web app (bin/rails server) from worker (bin/rake jobs:work).
  if [ "$1" = "bin/rails" ]; then
    echo "[entrypoint] Schema not initialized — loading schema (up to 3 attempts)..."

    drop_all_tables

    MAX_ATTEMPTS=3
    attempt=1
    while true; do
      if schema_load; then
        echo "[entrypoint] Schema loaded successfully."
        echo "[entrypoint] Seeding database..."
        bundle exec rails db:seed
        echo "[entrypoint] Database seeded."
        break
      fi

      if [ "${attempt}" -ge "${MAX_ATTEMPTS}" ]; then
        echo "[entrypoint] Schema load failed after ${MAX_ATTEMPTS} attempts — giving up."
        exit 1
      fi

      echo "[entrypoint] Schema load attempt ${attempt} failed — cleaning up and retrying in 5s..."
      sleep 5
      drop_all_tables
      attempt=$((attempt + 1))
    done
  else
    echo "[entrypoint] Worker waiting for schema to be initialized by app container..."
    while [ "$(procedures_exists)" = "0" ]; do
      sleep 5
    done
    echo "[entrypoint] Schema ready."
  fi
fi

if [ "$1" = "bin/rails" ]; then
  echo "[entrypoint] Running pending migrations..."
  bundle exec rails db:migrate
fi

exec "$@"
