#!/bin/bash
set -e
DB_USER=postgres
DB_NAME=postgres
until docker compose exec -T postgres pg_isready -U "$DB_USER" >/dev/null 2>&1; do
  sleep 1
done
docker compose exec -T postgres psql -U "$DB_USER" -d "$DB_NAME" -f - < repro.sql || true
