# Overview
파티션 테이블의 부모 인덱스가 제약조건이 아닌 일반 UNIQUE 인덱스이고

붙이는 파티션은 PRIMARY KEY(제약조건)를 가진 경우

ATTACH(AttachPartitionEnsureIndexes)는 부모에 제약조건이 없으므로 인덱스만 연결하고 제약조건은 연결하지 않음 (coninhcount = 0)

DETACH(DetachPartitionFinalize)는 자식에 제약조건만 있으면 무조건 연결 해제 → coninhcount가 -1이 되어 Assert 실패 

# reproduce
docker compose build

sudo chmod 777 ./logs

sudo chmod +x ./trigger.sh

docker compose up -d

./trigger.sh

# Check
stdout 출력
psql:<stdin>:5: server closed the connection unexpectedly

./logs/output.log에서 TRAP: failed Assert("constrForm->coninhcount == 0"), File: "pg_constraint.c", Line: 831 확인
