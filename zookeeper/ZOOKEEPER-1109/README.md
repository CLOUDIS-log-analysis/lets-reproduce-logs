```
        SyncThread
            │
            │ System.exit(11)
            ▼
    JVM shutdown 시작
            │
            │ shutdown hook이
            │ 끝나기를 기다림
            ▼
     ShutdownHook Thread
            │
            │ ZooKeeper shutdown
            ▼
 SyncRequestProcessor.shutdown()
            │
            │
            └── SyncThread.join()
                    │
                    │ SyncThread가
                    │ 끝나기를 기다림
                    ▼
                 SyncThread
```

순환 대기가 만들어져버림

디스크가 다 차서 종료되는건 당연한건데 (나머지가 리더로 선출되면 되니까)
이 이슈는 종료 자체가 제대로 안일어나고 순환대기가 일어나버려서 문제임

System.exit를 호출한 SyncThread와 shutdown hook 사이의 순환 대기(deadlock)
