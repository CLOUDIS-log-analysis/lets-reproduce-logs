#!/bin/sh
set -eu

: "${ZOO_MY_ID:?ZOO_MY_ID must be set}"

mkdir -p /data /datalog "${ZOO_LOG_DIR:-/logs}"

# ZooKeeper identifies each ensemble member using <dataDir>/myid.
printf '%s\n' "$ZOO_MY_ID" > /data/myid

# ZooKeeper/Log4j application logs go to zookeeper.log.
# Anything written directly to stdout/stderr by zkServer.sh, the JVM, etc.
# is preserved independently in zookeeper.out.
exec bin/zkServer.sh start-foreground \
    >> "${ZOO_LOG_DIR:-/logs}/zookeeper.out" 2>&1
