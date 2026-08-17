# Overview
AOF 재작성 등을 위해 백그라운드 프로세스를 fork()하다가 실패할 경우 부모-자식 간 통신을 위해 미리 열어둔 파이프 리소스가 닫히지 않고 그대로 누수되어 한계에 도달하게되면 새로운 I/O핸들을 요구하는 모든 시스템 콜(accept, pipe, open, socket)이 EMFILE(Too many open files) eror를 반환하며 차단됨

# Step to Reproduce
sudo chmod 777 log
sudo chmod +x ./trigger.sh

sudo docker compose up -d --build
./trigger.sh

"누수된 FD 개수가 더이상 증가하지 않을 때 CTRL + C 강제종료"

sudo docker compose down

# Check
./log/baseline.log에 반복적인 fork()실패 후 Too many open files error 확인
