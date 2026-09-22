# ZOOKEEPER-1513 reproduction summary

## Overall conclusion

**SUCCESS** — the one completed experiment reproduced ZOOKEEPER-1513 with the
exact failure signature reported in `1513.xml`. An ordinary client write was
acknowledged and persisted, but the same ZooKeeper server then failed while
replaying that transaction after a clean stop and restart.

## Completed attempts

| Attempt | Result | Workload | Restart | Verification | Observation |
| --- | --- | ---: | ---: | ---: | --- |
| `attempt-001` | **SUCCESS** | exit 0 | exit 1 | exit 0 | `reproduced=true`; restart failed with `Unreasonable length = 1048583` in transaction-log replay |

No `attempt-002` or `attempt-003` result file exists, so there are no other
completed attempts to summarize. Although `repro.properties` permits three
attempts, repeatability across three independent runs was not evaluated.

## Key observations

- ZooKeeper acknowledged `setData` on `/zookeeper-1513` with a deterministic
  1,048,524-byte payload (`workload_exit=0`, version 1, `mzxid=3`). The
  persisted serialized transaction was exactly 1,048,583 bytes.
- The server remained responsive after the write (`post_write_readiness=imok`)
  and was then stopped cleanly.
- Restarting against the preserved data exited with status 1. The container
  was not OOM-killed.
- Startup failed while restoring the database with
  `java.io.IOException: Unreasonable length = 1048583`. The preserved stack
  includes `BinaryInputArchive.readBuffer`, `Util.readTxnBytes`, `FileTxnLog`,
  and `ZKDatabase.loadDataBase`, matching the Jira replay path.
- The verifier confirmed the acknowledged write, deterministic payload size
  and digest, serialized transaction size, failed restart, exact exception,
  and replay stack; it exited 0 with `reproduced=true`.
- The payload is slightly below 1 MiB because ZooKeeper 3.3.4's live buffer
  limit applies to the client buffer, while transaction metadata and the znode
  path bring the serialized transaction to the Jira-reported 1,048,583-byte
  boundary.

## Preserved evidence

- Attempt result: `result/attempt-001.properties`
- Write evidence: `logs/zk1/app_logs/attempt-001/write-evidence.properties`
- Workload output: `logs/zk1/app_logs/attempt-001/reproduce.stdout.log`
- Restart output: `logs/zk1/app_logs/attempt-001/restart-container.log`
- Restart state: `logs/zk1/os_logs/attempt-001/restart-container-state.txt`
- Verification output: `logs/zk1/app_logs/attempt-001/verify.stdout.log`
- Preserved transaction log and snapshot:
  `logs/zk1/txn_logs/attempt-001/` and
  `logs/zk1/snapshot_data/attempt-001/`
