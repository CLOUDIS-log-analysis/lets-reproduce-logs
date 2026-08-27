#!/usr/bin/env bash

CONTAINER_NAME="pg_fsync_panic_test"

# 초기 데이터 세팅

docker exec -it $CONTAINER_NAME /usr/local/pgsql/bin/psql -U postgres -d postgres -c "DROP TABLE IF EXISTS t;"
docker exec -it $CONTAINER_NAME /usr/local/pgsql/bin/psql -U postgres -d postgres -c "create table t (i int primary key);"
docker exec -it $CONTAINER_NAME /usr/local/pgsql/bin/psql -U postgres -d postgres -c "insert into t select generate_series(1, 5000);"
docker exec -it $CONTAINER_NAME /usr/local/pgsql/bin/psql -U postgres -d postgres -c "cluster t using t_pkey;"
