#!/usr/bin/env bash
C=pg17103
q()   { docker exec -i $C psql -U postgres -qAt -c "$1"; }
wal() { docker exec $C sh -c 'du -sm /wal_disk | cut -f1'; }

until docker exec $C pg_isready -U postgres -q; do sleep 1; done

# 1. 테이블과 소비자가 없는 복제 슬롯 생성 (멈춘 replica 역할)
q "CREATE TABLE t (id bigint, pad text);"
q "SELECT pg_create_physical_replication_slot('lost_slot', true);"

# 2. WAL을 약 16MB씩 만들고 매번 CHECKPOINT → 슬롯이 무효화(lost)될 때까지 반복
i=0
while [ "$(q "SELECT wal_status FROM pg_replication_slots")" != "lost" ]; do
  i=$((i+1))
  q "INSERT INTO t SELECT g, repeat('x', 100) FROM generate_series(1, 100000) g;"
  q "CHECKPOINT;"
  echo "step $i: slot=$(q "SELECT wal_status FROM pg_replication_slots") pg_wal=$(wal)MB"
done

# 3. 무효화 뒤에도 같은 작업을 3번 더 → WAL이 줄어드는지 확인
for j in 1 2 3; do
  q "INSERT INTO t SELECT g, repeat('x', 100) FROM generate_series(1, 100000) g;"
  q "CHECKPOINT;"
  echo "after lost $j: pg_wal=$(wal)MB"
done

# 4. 체크포인트 없이 WAL을 한꺼번에 약 130MB 생성 (부하 급증)
echo "burst start: pg_wal=$(wal)MB"
q "INSERT INTO t SELECT g, repeat('x', 100) FROM generate_series(1, 800000) g;"
echo "burst end: exit=$? pg_wal=$(wal)MB"

