#!/usr/bin/env bash

sudo chmod 777 ./logs
sudo chmod +x trigger.sh

# libminidump.so가 없을 때만 빌드 (매번 apt-get 다시 돌리는 걸 방지)
if [ ! -f libminidump.so ]; then
  docker run --rm -v $(pwd):/build -w /build debian:buster bash -c \
    "sed -i 's|deb.debian.org|archive.debian.org|g; s|security.debian.org|archive.debian.org|g' /etc/apt/sources.list \
     && echo 'Acquire::Check-Valid-Until \"false\";' > /etc/apt/apt.conf.d/99no-check-valid \
     && apt-get update -qq \
     && apt-get install -y -qq gcc > /dev/null \
     && gcc -shared -fPIC -o libminidump.so minidump.c"
fi

docker compose up -d
