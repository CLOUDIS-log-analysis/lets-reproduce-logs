#!/bin/bash

docker exec -it redis-13099-test redis-benchmark -t set -c 50 -P 100 -r 100000 -d 1024 -n 1000000

docker exec -it redis-13099-test pkill -f dd

docker exec -it redis-13099-test rm -f /data/io_stress_*
