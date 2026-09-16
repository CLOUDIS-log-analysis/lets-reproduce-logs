재현실패
jira에도 로그파일은 없음


설명:

각 트랜잭션에는 zxid가 붙음
zxid 100
zxid 101
zxid 102
이런식

그런데 
1. zxid갱신
2. DataTree 변경
1,2사이에 thread가 끼일 수 있음
```
Transaction Thread                  Snapshot Thread
──────────────────                  ───────────────

txn zxid=100 시작

lastProcessedZxid = 100
        │
        │ context switch
        ├──────────────────────────→
                                    lastProcessedZxid 읽음
                                    = 100

                                    snapshot.100 생성

                                    DataTree serialize
                                    /important 없음
        ←───────────────────────────
        │
createNode("/important")
        │
txn 완료


              CRASH
                ↓

          snapshot.100
       (/important 없음)
                ↓
             restart
                ↓
lastProcessedZxid = 100
                ↓
      txnLog.read(101)
                ↓
      txn 100 건너뜀
                ↓
       /important 유실
```
