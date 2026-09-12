#!/usr/bin/env bash
CONTAINER="redis-10968"

docker exec -i $CONTAINER redis-cli -h "127.0.0.1" -p "6379" <<EOF
XGROUP CREATE s:foo g:foo $ MKSTREAM
XADD s:foo MAXLEN ~ 1 * foo 1
XADD s:foo MAXLEN ~ 1 * foo 2
XADD s:foo MAXLEN ~ 1 * foo 3
XADD s:foo MAXLEN ~ 1 * foo 4
XADD s:foo MAXLEN ~ 1 * foo 5
XREADGROUP GROUP g:foo c:1 COUNT 1 STREAMS s:foo >
XREADGROUP GROUP g:foo c:1 COUNT 1 STREAMS s:foo >
XREADGROUP GROUP g:foo c:1 COUNT 1 STREAMS s:foo >
XREADGROUP GROUP g:foo c:1 COUNT 1 STREAMS s:foo >
XREADGROUP GROUP g:foo c:1 COUNT 1 STREAMS s:foo >
XTRIM s:foo MAXLEN = 1
XREADGROUP GROUP g:foo c:1 COUNT 10 STREAMS s:foo 0
XAUTOCLAIM s:foo g:foo c:1 10 0 COUNT 1
EOF

# XAUTOCLAIM으로 크래시 발생이 되지 않은 경우 자연스럽게 발생하도록
docker exec $CONTAINER redis-cli XADD s:foo '*' status "crash_test" > /dev/null 2>&1

# 만약 그럼에도 크래시가 발생하지 않을경우SAVE로 모든 메모리를 접근하도록
docker exec $CONTAINER redis-cli SAVE > /dev/null 2>&1
