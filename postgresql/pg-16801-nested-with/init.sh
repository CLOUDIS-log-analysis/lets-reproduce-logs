#!/usr/bin/env bash

mkdir -p ./coredump
sudo chmod 777 ./coredump
sudo chmod 777 ./logs
sudo chmod +x trigger.sh
sudo sh -c 'echo "core.%p" > /proc/sys/kernel/core_pattern' 2>/dev/null
docker compose up -d
