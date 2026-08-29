#!/usr/bin/env bash
set -e

# Primary 서버가 초기화되고 기동될 때까지 대기
echo "Waiting for Primary node to be ready..."
sleep 5

# 베이스 백업 및 물리적 리플리케이션 슬롯 생성
su - postgres -c "pg_basebackup -h primary -U postgres -D /var/lib/postgresql/data -R --slot=bug_test_slot -C"

# Replica 데몬 기동 (Foreground)
exec su - postgres -c "/usr/lib/postgresql/13/bin/postgres -D /var/lib/postgresql/data"
