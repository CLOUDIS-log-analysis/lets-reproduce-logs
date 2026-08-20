#!/usr/bin/env bash

docker exec -d redis-13099-test sh -c 'for i in 1 2 3 4; do while true; do dd if=/dev/zero of=/data/io_stress_$i bs=1M count=512 2>/dev/null; sync; done & done'
