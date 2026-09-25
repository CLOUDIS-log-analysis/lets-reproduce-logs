# ZOOKEEPER-1560 reproduction summary

## Overall conclusion: SUCCESS

ZOOKEEPER-1560 was reproduced in the one completed attempt. The ZooKeeper
3.4.4 Java client passed the small-node readiness control, then its synchronous
creation of `/large` with a 500,000-byte payload remained blocked beyond the
30-second deadline. The captured thread dump shows the main thread waiting in
`Object.wait` through `ClientCnxn.submitRequest` and `ZooKeeper.create`, which
matches the specified Jira oracle. The deterministic verifier returned exit
code 0 and reported `REPRODUCED reason=timed_out_with_expected_waiting_stack`.

## Completed attempts

| Attempt | Recorded result | Conditions | Observation |
| --- | --- | --- | --- |
| `attempt-001` | `SUCCESS` | ZooKeeper 3.4.4, Zulu OpenJDK 6u119, one standalone server; socket send buffer constrained to 1,024 bytes requested and 2,304 bytes actual | Readiness passed; the 500,000-byte create timed out; the thread dump contained the expected synchronous waiting stack; verifier exit 0 (`REPRODUCED`) |

The attempt ran for 31,146 ms in total, with the large create observed for
30,794 ms. A thread dump was captured successfully before the blocked client
was terminated; client exit 143 therefore reflects experiment cleanup after
the deadline, not a JVM crash. The server initially established the session,
then recorded the client's disconnect and reconnection while the create
remained unresolved.

## Scope and key observations

- Only `attempt-001` has a completed result. No completed `attempt-002` or
  `attempt-003` result is present, despite `repro.properties` specifying three
  attempts.
- The successful attempt used the documented diagnostic socket-send-buffer
  constraint to encourage partial nonblocking writes. It demonstrates the bug
  under that condition; there is no completed primary run with fault injection
  disabled and no three-attempt repeatability evidence.
- Both client and server identify themselves as ZooKeeper 3.4.4, and the client
  ran on Zulu OpenJDK 1.6.0-119.
- Server readiness, evidence capture, container shutdown, and verification all
  completed successfully. The preserved attempt record reports
  `readiness_control=passed`, `large_create_timed_out=true`,
  `expected_waiting_stack=true`, and `verify_exit=0`.
