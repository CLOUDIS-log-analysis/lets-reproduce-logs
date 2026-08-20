#!/usr/bin/env bash

CONTAINER_NAME="redis-2857-test"

while true; do
	# 1. 백그라운드 저장 명령(fork) 지속 호출
	docker exec $CONTAINER_NAME /redis-3.0.5/src/redis-cli BGREWRITEAOF > /dev/null 2>&1
	# 2. 커널 가상 파일 시스템(procfs)을 통한 실시간 FD 누수 확인
	FD_COUNT=$(docker exec $CONTAINER_NAME ls /proc/1/fd 2>/dev/null | wc -l)
    echo " -> 현재 Redis 프로세스(PID 1)의 누수된 FD 개수: $FD_COUNT / 256"
    
    # 시스템 과부하 방지를 위한 0.1초 대기
    sleep 0.1
done
