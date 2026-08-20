# Overview
Writable Replica에 만료된 key를 지우고 명령어를 AOF에 전송하기위해 큐 사용
그 과정에서 작업이 끝난 후 큐를 비우는 로직 누락
다음 AOF에 전송하기 전 큐가 비어있지 않아 방어로직 Assertion failure

# Step to reproduce
sudo chmod 777 log

sudo chmod +x trigger.sh

docker compose up -d

./trigger.sh


docker compose down

# Check
설정한 만료시간 3초 후 assertion failed로 종료되며 로그에 bug report 기록됨
