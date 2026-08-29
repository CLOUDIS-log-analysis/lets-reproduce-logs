#!/usr/bin/env bash

# pgbench 스키마 초기화
docker exec -i primary pgbench -U postgres -i -s 10 postgres

# replica 컨테이너 종료(동기화 단절)
docker stop replica

#transaction 폭증 유도
docker exec -i primary pgbench -U postgres -c 5 -t 100000 postgres
