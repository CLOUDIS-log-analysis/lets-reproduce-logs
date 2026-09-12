# Overview
1. 클라이언트가 대용량 데이터를 TLS로 전송하면 메인 스레드는 네트워크 IO 대기열에 등록하여 백그라운드 IO 스레드에게 작업 위임

2. 대용량 데이터는 OpenSSL 버퍼에 잔여 데이터가 남게 되는데 메인스레드는 해당 클라이언트 객체를 TLS pending list에 등록

3. 이 때 클라이언트 소켓 연결이 끊어지면 IO스레드가 연결이 끊어진걸 확인하고 freeClient()함수 호출

4. 이후 메인 스레드가 TLS pending list에 있던 클라이언트 객체가 연결이 끊어진 것을 발견하고 예외처리하는 과정에서 freeClient()함수가 호출되어 double free로 SIGSEGV

# Step to reproduce
sudo chmod 777 logs

sudo chmod +x trigger.sh

sudo docker compose up -d

./trigger.sh

sudo docker compose down

# Check
asssertion failed로 종료되며 로그에 bug report 기록됨
