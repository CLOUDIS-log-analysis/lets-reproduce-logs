# Overview



# Step to reproduce
sudo chmod 777 ./logs

sudo chmod +x ./trigger

sudo docker compose up -d --build

cd ./trigger

./init.sh

./trigger.sh

*error발생까지 1~2분 대기

docker compose down

# Check
./logs에 생성된 log파일에서 PANIC 확인
