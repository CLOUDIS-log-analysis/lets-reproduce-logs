# ZOOKEEPER-2247

## 재현 보고서

### 관련 자료

- https://issues.apache.org/jira/browse/ZOOKEEPER-2247    이슈원본
- https://zookeeper.apache.org/doc/r3.5.0-alpha/          공식문서
- https://archive.apache.org/dist/zookeeper/              소스코드

- ![alt text](image.png)

### 기반 환경 세팅

1. opentofu (+ terraform-provider-incus) + cloud-init 을 통한 VM 생성
    - 0_CLOIDS/iac/incus-infra/main.tf
    - 0_CLOIDS/iac/incus-infra/cloudinit.yaml
    - (우분투 환경임)

2. 도커 컨테이너
    - how to install docker in ubuntu 문서 참고

### 핵심 환경 세팅

- Dockerfile (여기에 아예 Apache archive 경로에서 curl 하게 했음) -> base image는 이클립스 테무린-8버전 (curl,tar 있음)
- docker-compose.yml (3노드 쉽게 띄우는 용도)
- entrypoint.sh (myid 생성 및 진입점 start)
- zoo.cfg (주키퍼 설정)
- log4j.properties (특정 주키퍼 버전 이하에서만) (로그 설정 : )
- logback.xml (특정 주키퍼 버전 이후)

1. Dockerfile에서 원하는 버전의 zk 적기
2. docker build -t zk버전:local .   //점 필수임!!!!!!!!!!!
3. docker images 확인
4. docker-compose.yml의 images 버전을 위 빌드한 이미지로 맞추기
5. /mnt/zk-txn 만들기     //이거 뭐 만드는 방법이 있음...
6. 마운트 하기
7. docker-compose.yml에 한 노드만 /mnt/zk-txn에 바인딩 하기
8. docker compose up -d --force-recreate
9. docker ps 로 상태 확인
10. docker compose exec zk1~3 bin/zkServer.sh status    //팔로워,리더 뜸. 이때 /mnt마운트 된 노드가 리더가 되게 하기
11. `echo "create /test hello" | docker compose exec -T zk1 bin/zkCli.sh -server zk3:2181`
    - 트랜잭션 로그를 생성하는 명령. -T는 tty끄기 옵션
    - 트랜잭션 로그할 때, 각 이름이? 달라야한다고 함 여러번 보낼 때 주의
12. docker compose down
13. sudo mount -o remount,bind,ro /mnt/zk-txn  쓰기 불가 상태
14. docker compose up -d
15. ```echo "create /after "boom" | docker compose exec -T zk1 bin/zkCli.sh -server zk3:2181```
16. [에상] 트랜잭션 로그 쓰기 실패
17. sudo mount -o remount,bind,rw /mnt/zk-txn   쓰기 가능으로 다시 바꾸기
18. [예상] docker ps 3 node 정상
19. [예상] docker compose exec zk1~3 bin/zkServer.sh status 여전히 리더가 바뀌지 않음
20. [예상] ```echo "create /validate "hello2" | docker compose exec -T zk1 bin/zkCli.sh -server zk3:2181```  여전히 쓰기 실패
21. [예상] 트랜잭션 로그 쓰기는 안되면서 리더에서 내려오지는 않는 에러가 발생
