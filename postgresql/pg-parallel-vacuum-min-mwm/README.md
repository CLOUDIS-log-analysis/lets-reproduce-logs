# Overview
PG17에서 maintenance_work_mem 최솟값이 64kB로 낮아짐

Parallel VACUUM의 공유메모리(DSA) 기본 오버헤드가 256KB라서, 죽은 튜플을 0개 모은 시점에 이미 예산(64KB) 초과로 판단됨

0개인 채로 인덱스 정리 사이클에 진입 -> num_items > 0을 전제로 짜인 Assert 실패


# reproduce
docker compose build
(약5분 소요)

sudo chmod 777 ./logs

sudo chmod +x ./trigger.sh

docker compose up -d

./trigger.sh

# Check
stdout 출력

psql:<stdin>:6: server closed the connection unexpectedly

        This probably means the server terminated abnormally

        before or while processing the request.

생성된 ./logs/output.log에서 TRAP: failed Assert 확인
