#!/bin/sh
set -eu

# Files created in bind mounts must remain readable and directories traversable
# by the host-side Harness account.
umask 022

for writable_dir in /var/lib/zookeeper /var/log/zookeeper; do
    if [ ! -d "${writable_dir}" ]; then
        mkdir -p "${writable_dir}"
    fi
    if [ ! -r "${writable_dir}" ] || [ ! -w "${writable_dir}" ] || [ ! -x "${writable_dir}" ]; then
        echo "ZooKeeper requires a readable, writable, traversable mount: ${writable_dir}" >&2
        exit 73
    fi
done

if [ -d /result ] && { [ ! -r /result ] || [ ! -x /result ]; }; then
    echo "The result mount must be readable and traversable: /result" >&2
    exit 73
fi

exec "$@"
