# Overview
1. UPDATE로 인해 큐에 적재된 특정 세그먼트의(예: .2) fsync요청을 Chekcpointer가 처리
2. 그 때 내부 파일 오픈함수가 선행하는 세그먼트(예: .1)를 먼저 열려고 시도하는 구조적 특징
3. 이 때 CLUSTER가 그 선행 세그먼트를 이미 디스크에서 삭제해버림
4. Checkpointer는 해당 파일을 차지 못하고 PANIC(signal 6: Aborted)로 시스템 중단

# Step to reproduce
sudo chmod 777 ./logs

sudo chmod +x ./trigger

sudo docker compose up -d --build

cd ./trigger

./init.sh

./trigger.sh

crash 발생까지 1~2분 대기

docker compose down

# Check
./logs에 생성된 log파일에서 grep으로 PANIC 확인
