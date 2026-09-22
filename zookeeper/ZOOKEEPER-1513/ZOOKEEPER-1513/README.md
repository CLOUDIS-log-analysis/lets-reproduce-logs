# ZOOKEEPER-1513 reproduction specification

## Bug summary

ZooKeeper 3.3.4 accepts client data at the configured Jute buffer limit, but the
persisted transaction containing that data is slightly larger because it also
contains transaction metadata. On a later server start, transaction-log replay
applies the same limit to the complete serialized transaction and aborts while
loading the database.

The Jira report records the concrete failure as:

```text
java.io.IOException: Unreasonable length = 1048583
    at org.apache.jute.BinaryInputArchive.readBuffer(...)
    at org.apache.zookeeper.server.persistence.Util.readTxnBytes(...)
    at org.apache.zookeeper.server.persistence.FileTxnLog.read(...)
    at org.apache.zookeeper.server.ZKDatabase.loadDataBase(...)
```

`1,048,583` is `0x100007`: seven bytes above the default 1 MiB
`jute.maxbuffer` value. The Jira description attributes those extra bytes to
fields in `SetDataTxn`, in addition to the client data that was checked when it
was accepted.

## Target and resources

- Affected ZooKeeper version: **3.3.4**, the version named by Jira.
- Fixed-version reference: Jira lists **3.4.6** and **3.5.0** and says the
  change was committed to 3.4.6 and trunk.
- Java runtime: **JDK 8**, selected as a practical runtime for the old release;
  the Jira record does not identify a JDK-specific condition.
- Topology: **one server**. The defect is in local transaction persistence and
  startup replay, so leader election or a multi-node interaction is not needed
  to exercise it.
- Resources: **2 CPUs and 2 GiB memory**, sufficient for one server and a small
  client driver.
- Attempts: **3**. The report describes a deterministic size-boundary failure,
  not a flaky, timing-sensitive, or concurrent behavior.

## Reproduction procedure

The later implementation stage should automate the following sequence without
changing `jute.maxbuffer` from its default value:

1. Start a clean ZooKeeper 3.3.4 server with a persistent data directory and
   wait until it accepts client connections.
2. Create a znode with a small initial value.
3. Issue `setData` with a byte array exactly 1 MiB (1,048,576 bytes) long and
   assert that the operation succeeds. Use deterministic bytes so the input is
   identical in every attempt.
4. Stop the server cleanly after the successful write, preserving its data and
   transaction log.
5. Start the same server again against that directory and capture its complete
   startup output and process exit status.
6. Retain evidence that the write was acknowledged before the restart and that
   the restart subsequently failed during database loading.

The test must not synthesize or corrupt a transaction log: the point is to show
that an ordinary client operation accepted by the affected server creates an
on-disk record that the same server cannot later read.

## Result oracle

An attempt reproduces the bug only when all of these conditions hold:

- the 1 MiB `setData` operation succeeds before shutdown;
- restart using the resulting data directory fails to become ready (or exits);
- startup output contains `Unreasonable length = 1048583`; and
- the failure path is database restoration/transaction-log replay, evidenced by
  frames such as `BinaryInputArchive.readBuffer`, `Util.readTxnBytes`,
  `FileTxnLog`, and `ZKDatabase.loadDataBase`.

A rejection of the original client write is not this bug. A restart failure
without the size exception is also not sufficient. Reproducing the stated
failure in each of the three independent clean attempts is the success
criterion.

## Rationale and control

This boundary is taken directly from the Jira report: accepted client data plus
seven bytes of `SetDataTxn` fields becomes a 1,048,583-byte serialized buffer.
Restart is essential because the observed exception occurs while loading the
database from disk, not while handling the live request.

If a fixed-version control is added in a later stage, the same write and restart
sequence should complete successfully on ZooKeeper 3.4.6 while preserving the
configured client-data limit. Increasing `jute.maxbuffer` is documented in Jira
only as a workaround and must not be used in the primary reproduction.

## Evidence source

This specification is based solely on `1513.xml`: the issue description,
affected version 3.3.4, fix versions 3.4.6/3.5.0, recorded stack trace, and the
comment confirming the commit to 3.4.6 and trunk.
