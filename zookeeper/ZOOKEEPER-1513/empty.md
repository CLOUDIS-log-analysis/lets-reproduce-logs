Notice the size is 0x100007 - 7 bytes beyond.

ZooKeeper가 클라이언트의 쓰기는 정상적으로 받아서 transaction log에 저장했는데, 재시작하면서 그 transaction log를 자기 자신이 읽지 못해서 서버가 기동 실패하는 문제입니다.



0xfffff
= 1,048,575 bytes
≈ 1 MiB
패킷 제한이 있음

쓰기에도 이 제한을 통과해야 쓸 수 있음

그런데 제한을 통과한 후 들어오고 나서 트랜잭션 로그를 쓰기전에 메타데이터가 추가됨

저장에는 문제가 없었다가

재시동 후 트랜잭션로그를 읽어들일 때 문제가 됨

Unreasonable length 에러가 뜨며 종료됨
