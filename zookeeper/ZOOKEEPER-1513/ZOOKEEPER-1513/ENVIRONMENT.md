# Environment notes

## Distribution provenance

`dist/zookeeper-3.3.4.tar.gz` is the unmodified Apache ZooKeeper 3.3.4
release archive downloaded from:

`https://archive.apache.org/dist/zookeeper/zookeeper-3.3.4/zookeeper-3.3.4.tar.gz`

Its published SHA-1 is stored alongside it in
`dist/zookeeper-3.3.4.tar.gz.sha1`:

`cbb259eac2ae5c10956c49db5b2a05e112d645ac`

Verify it with:

```sh
(cd dist && sha1sum -c zookeeper-3.3.4.tar.gz.sha1)
```

The official 3.3.4 JAR has a stale `Implementation-Version` manifest value of
`3.3.3-1203054`, so its startup banner reports 3.3.3. The same JAR's compiled
`org.apache.zookeeper.version.Info` constants are 3.3.4 revision 1203063, its
bundle version is 3.3.4, and the release archive's changelog identifies the
release as 3.3.4. Do not replace the verified release archive to alter the
banner.

## Build and mounts

The image contains the full Temurin JDK 8 and runs as a non-root user. The
defaults match the Harness host used to prepare this directory. On another
host, export its account IDs for both build and run:

```sh
export ZK_UID="$(id -u)"
export ZK_GID="$(id -g)"
docker compose -f compose.yml build
```

Compose applies a 2-CPU/2-GiB limit and binds only to loopback by default.
`data/` and `logs/` are writable by the non-root service account. `result/` is
mounted read-only; result capture is a host-side Harness responsibility. The
entrypoint fixes the process umask at `022`, so container-created regular files
are host-readable and directories are host-traversable.

Each later attempt must use new, never-reused directories by setting
`ZK_DATA_DIR` and `ZK_LOG_DIR`. Once the container has stopped and Harness has
captured an attempt, remove write permission from that attempt's log/result
files and their containing attempt directories. Never start a container with a
protected attempt directory as its writable log or data path.

`logs/environment-smoke/` is the protected output of the environment-only
startup check. It is not an experiment attempt and must not be reused.
