#!/bin/sh
set -eu

# Files and directories created through host bind mounts must remain readable
# and traversable by the host-side Harness account.
umask 022

for mounted_dir in /logs /data /result; do
    if [ ! -d "$mounted_dir" ]; then
        echo "required bind-mount directory is missing: $mounted_dir" >&2
        exit 70
    fi
    if [ ! -r "$mounted_dir" ] || [ ! -w "$mounted_dir" ] || [ ! -x "$mounted_dir" ]; then
        echo "required bind-mount directory is not readable, writable, and traversable: $mounted_dir" >&2
        exit 71
    fi
done

mkdir -p /data/txnlog /data/tmp

exec "$@"
