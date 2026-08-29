#Overview
이론상 replication이 너무 오랫동안 동기화되지 않아 max_slot_wal_keep_size 임계치가 초과되면 해당 replication slot을 무효화 상태(lost)로 전환하고 이전 WAL파일들을 삭제하며 디스크 공간을 확보 해야함

그러나 slot이 무효화되었음에도 primary는 무효화된 slot을 drop하거나 서버 재시작전까지 WAL 파일을 삭제하지 않고 유지하여 디스크가 고갈되며 crash가 발생

#Step to reproduce
sudo chmod 777 ./logs

sudo chmod +x ./*.sh

docker compose up -d

./trigger.sh

docker compose down

#Check
./logs에 생성된 log파일에 PANIC 확인
