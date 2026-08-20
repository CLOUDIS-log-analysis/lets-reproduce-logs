# Overview
- 다중 프로세스가 대량의 더미데이터(dd)를 생성하고 전역 동기화(sync)를 반복호출하여 OS 커널의 VFS(virtual file system) Lock을 장기간 점유
- 이 때 매초 발생하도록 설정한 appendfsync 또한 대기
- 동시에 벤치마크 클라이언트들이 redis 메인 스레드로 지속적인 SET명령어(쓰기요청) 전송
- 메인 스레드는 SET명령어를 AOF 버퍼에 쓰기 직전 fsync 지연 상태 확인. 2초 초과 감지 시 OOM을 막기위해 blocking 후 디스크에 경고 로그 출력(방어로직)
- 메인 스레드가 blcok상태가 되어 어떠한 커맨드 응답도 반환받지 못하므로 네트워크 큐에서 대기하던 클라이언트 애플리케이션(ex: timeout 2초인 Jedis 등)에서 timeout exception 발생
- 백그라운드 I/O 스레드 병목으로 인해 메인 스레드가 불필요하게 지연되는 문제

# Step to reproduce
mkdir data

sudo chmod 777 data log

sudo chmod +x trigger/*.sh

sudo docker compose up -d

cd trigger

./01-stress-io.sh && ./02-run-benchmark.sh

cd ..

sudo docker compose down

# Check
./log/baseline.log에서 경고 로그 확인

“ * Asynchronous AOF fsync is taking too long (disk is busy?). Writing the AOF buffer without waiting for fsync to complete, this may slow down Redis. “
