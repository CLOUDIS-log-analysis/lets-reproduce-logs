#!/usr/bin/env bash

sudo docker exec redis-4356-test redis-benchmark -c 20 -r 500000 -n 10000000 -t set -d 3500 -q &
sudo docker exec redis-4356-test redis-benchmark -c 20 -r 500000 -n 10000000 -t set -d 300 -q &
sudo docker exec redis-4356-test redis-benchmark -c 20 -r 500000 -n 10000000 -t set -d 1500 -q &
