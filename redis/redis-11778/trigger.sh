#!/usr/bin/env bash

docker exec redis-11778-test redis-benchmark -c 20 -r 100000 -n 1000000 SET auth_token:__rand_int__ "user_data" EX 3
