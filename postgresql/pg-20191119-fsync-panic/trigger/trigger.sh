#!/usr/bin/env bash

CONTAINER_NAME="pg_fsync_panic_test"

# 파일 삭제 유도
printf "cluster t;\n\\watch 0.1\n" | docker exec -i $CONTAINER_NAME /usr/local/pgsql/bin/psql -U postgres -d postgres &

#더티버퍼 양산 및 fsync 유도
printf "update t set i = i;\n\\watch 0.05\n" | docker exec -i $CONTAINER_NAME /usr/local/pgsql/bin/psql -U postgres -d postgres &
