#!/usr/bin/env bash

DB_USER=postgres
DB_NAME=postgres

echo "[*] Waiting for PostgreSQL to be ready..."
until docker compose exec -T postgres pg_isready -U "$DB_USER" >/dev/null 2>&1; do
  sleep 1
done
echo "[*] PostgreSQL is ready."

echo "[*] Running reproduction SQL (crash expected on COMMIT)..."
docker compose exec -T postgres psql -U "$DB_USER" -d "$DB_NAME" -f - < repro.sql
