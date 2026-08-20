#!/usr/bin/env bash

docker exec -u root redis-13099-test bash -c "apt-get update && apt-get install -y procps"

docker exec -i redis-13099-test redis-benchmark -t set -c 50 -P 100 -r 100000 -d 1024 -n 1000000

docker exec redis-13099-test pkill -f dd

docker exec redis-13099-test rm -f /data/io_stress_*
