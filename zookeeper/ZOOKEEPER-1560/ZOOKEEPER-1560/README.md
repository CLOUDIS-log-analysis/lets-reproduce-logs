# ZOOKEEPER-1560 reproduction specification

## Objective

Reproduce the ZooKeeper 3.4.4 Java client hang reported as
ZOOKEEPER-1560, "Zookeeper client hangs on creation of large nodes." The
experiment must exercise the unmodified 3.4.4 client and server. It must not
apply the eventual fix or substitute an artificial implementation of the
client write path.

The primary operation is a synchronous `ZooKeeper.create` of `/large` with a
500,000-byte payload. The Jira description calls this "0.5M of data," and a
later failure log reports an original packet limit of 500,074 bytes, which is
consistent with that payload plus protocol framing.

## Jira evidence and defect model

The specification is based only on `1560.xml`:

- Affected versions are 3.4.4 and 3.5.0; the listed fixed versions are 3.4.5
  and 3.5.0. Version 3.4.4 is therefore the concrete released vulnerable
  target.
- The reporter says a Java-client create containing 0.5M of data waits
  indefinitely for the server response.
- The captured thread dump places the caller in `Object.wait`, reached through
  `ClientCnxn.submitRequest`, while executing `ZooKeeper.create` from
  `ClientTest.testLargeNodeData`.
- The reported defect is in `ClientCnxnSocketNIO.doIO`. A nonblocking
  `SocketChannel.write` may consume only part of a packet. The faulty path
  removes that packet from `outgoingQueue` too early, recreates its byte
  buffer on a later pass, and assigns another xid. The server consequently
  does not receive one coherent request for which the waiting client can
  complete.
- The accepted change keeps a partially written packet at the head of the
  queue, creates its buffer and xid only once, and removes it only after the
  buffer is drained. The Jira records the production change as revision
  1404260 and the missing large-node test as revision 1404288.

This is a client transport bug, not a quorum or failover bug. One server is
enough to expose it.

## Environment contract

The later BUILD stage should provision, but this SPEC stage does not create:

- Apache ZooKeeper 3.4.4 for both server and Java client.
- JDK 6. The Jira does not state a JDK version, but discussion links the Java
  6 `SocketChannel.write` documentation and its stack traces are from the
  Java-6-era codebase, making JDK 6 the closest evidence-backed baseline.
- One standalone ZooKeeper server on loopback/container networking.
- One CPU and 1 GiB of memory. These are sufficient for a standalone server
  and keep the I/O conditions modest; the test must not fail because of an
  imposed memory limit.
- Three independent attempts, each starting with clean server data and a new
  client process.

All future container processes that write through host bind mounts must use
`umask 022` (or matching explicit modes) so host Harness can traverse and read
their artifacts.

## Reproduction procedure

For each attempt:

1. Start a fresh standalone ZooKeeper 3.4.4 server and wait until it accepts a
   client connection. Preserve its logs.
2. Start an unmodified ZooKeeper 3.4.4 Java client and wait for the connected
   state.
3. As a readiness control, synchronously create and then delete a small znode.
   If that operation fails, classify the attempt as an environment failure,
   not a reproduction.
4. Construct a deterministic byte array of exactly 500,000 bytes and call the
   synchronous create API for `/large` with open ACLs and persistent create
   mode. Use a fresh server data directory so the path cannot already exist.
5. Apply a 30-second wall-clock deadline to the client process. If the create
   is still pending at the deadline, capture a Java thread dump before
   terminating the process and preserve both client and server logs.
6. Record the process exit status, elapsed time, create result or exception,
   and whether the expected waiting stack was present. Do not infer success
   merely from the server-side existence or absence of `/large`.

No server restart, quorum, concurrent application request, source patch, or
fault-injection code is part of the primary reproduction. The packet is large
enough that an ordinary nonblocking socket may need multiple writes, which is
the condition described in the Jira.

## Oracle

An attempt **reproduces the bug** when all of the following hold:

1. The small-node readiness control completed successfully.
2. The 500,000-byte synchronous create did not return within 30 seconds.
3. A thread dump captured at the deadline shows the calling thread waiting in
   the synchronous request path, including `ClientCnxn.submitRequest` and
   `ZooKeeper.create`, matching the Jira evidence.

An attempt is a **non-reproduction** when the large create returns successfully
inside the deadline. A concrete ZooKeeper exception, JVM crash, server startup
failure, failed readiness control, or resource-limit termination is an
**environment/test failure** and must remain distinct from the hang oracle.

The issue is considered reproduced if at least one of the three valid attempts
meets the bug oracle. Report all three outcomes; do not discard successful
creates. Three attempts are appropriate because partial-write scheduling can
vary, while the Jira presents the 500,000-byte test as a direct reproduction
rather than a rare stress race.

## Optional confirmation (not the primary oracle)

After the vulnerable-version experiment is complete, the same scenario may be
run against the listed fixed version, ZooKeeper 3.4.5, as an A/B confirmation.
That comparison must be reported separately and must not replace the required
3.4.4 result. On the fixed version the create is expected to return normally
within the deadline.

## Prepared environment

The environment stage supplies the official ZooKeeper 3.4.4 release archive,
a pinned Zulu OpenJDK 6u119 archive, `Dockerfile`, `compose.yml`, and the
ZooKeeper 3.4.4 Log4j 1.x/server configuration. Archive hashes are recorded in
`dist/SHA256SUMS` and are checked again inside the image build.

Build the image from this directory with:

```sh
docker compose -f compose.yml build
```

Compose defaults to host UID/GID 1000. A host using different IDs should set
`HOST_UID` and `HOST_GID`. `ZK_DATA_DIR`, `ZK_LOG_DIR`, and `ZK_RESULT_DIR`
select the host bind-mount directories and should point at new, unique attempt
directories when experiments are eventually run. The non-root entrypoint sets
umask 022 and refuses mounts that are not readable, writable, and traversable.

After an attempt has fully stopped and its output has been captured, invoke
`scripts/protect-artifacts.sh` separately on its directory beneath `logs/` and
on its file or directory beneath `result/`. It makes regular files read-only
and directories readable/traversable but non-writable. It refuses paths
outside those two trees and refuses symbolic links.

This environment stage does not add reproduction/fault-injection Java source
and does not start the server or run an experiment.

## Implementation project

The Maven project compiles the reproduction classes with the pinned JDK 6
archive and packages their ZooKeeper 3.4.4 dependencies into
`target/zookeeper-1560-reproduction-jar-with-dependencies.jar`. Build it with:

```sh
mvn clean package
```

The primary client invocation is:

```sh
java -jar target/zookeeper-1560-reproduction-jar-with-dependencies.jar \
  --connect 127.0.0.1:2181
```

When the caller has not supplied an explicit JAAS or ZooKeeper SASL client
configuration, the launcher names an absent login context so that ZooKeeper
3.4.4 takes its built-in non-SASL fallback. This avoids the unrelated
ZOOKEEPER-1455-era behavior that can defer even the one-byte readiness request;
it does not alter or replace the 3.4.4 NIO write path under test.

The experiment driver must enforce the specified 30-second deadline and save a
thread dump before terminating a blocked client. `Reproduce` emits stable
`ZOOKEEPER_1560` markers for classification. `Verify` consumes the combined
client output and the captured dump without contacting ZooKeeper:

```sh
java -cp target/zookeeper-1560-reproduction-jar-with-dependencies.jar \
  org.apache.zookeeper.Verify client-output.log thread-dump.log
```

It exits 0 for a reproduced hang, 1 when the large create returned, and 2 for
invalid or incomplete evidence.

For an explicit diagnostic that makes partial nonblocking writes more likely,
pass `--inject-small-send-buffer`. This selects `FaultInjection`, which only
constrains the socket send buffer; it does not replace or patch ZooKeeper
3.4.4's `ClientCnxnSocketNIO.doIO`. The primary experiment leaves this option
disabled, as required by the oracle above.
