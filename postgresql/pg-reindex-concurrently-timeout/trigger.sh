#!/bin/bash
DB_USER=postgres
DB_NAME=postgres
until docker compose exec -T postgres pg_isready -U "$DB_USER" >/dev/null 2>&1; do
  sleep 1
done
docker compose exec -T postgres psql -U "$DB_USER" -d "$DB_NAME" -f - < repro.sql
# 취소가 트랜잭션 사이에 걸리는 타이밍을 찾기 위해 timeout 값을 바꿔가며 반복 (매번 새 세션)
for round in 1 2 3; do
  for ms in $(seq 1 40); do
    echo "=== round ${round}, statement_timeout=${ms}ms"
    docker compose exec -T -e PGOPTIONS="-c statement_timeout=${ms}" postgres \
      psql -U "$DB_USER" -d "$DB_NAME" -c "REINDEX INDEX CONCURRENTLY t_i_idx" || true
    sleep 0.5
    if grep -q "TRAP" logs/output.log 2>/dev/null; then
      echo "TRAP 발생 (round ${round}, statement_timeout=${ms}ms)"
      exit 0
    fi
  done
done
echo "TRAP 미발생"
