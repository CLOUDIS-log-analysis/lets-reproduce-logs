# Overview
PG 12.0의 REINDEX CONCURRENTLY는 작업을 여러 트랜잭션으로 나누고, 그 사이 테이블을 보호하려고 세션 잠금(ShareUpdateExclusiveLock)을 잡음
취소 확인(CHECK_FOR_INTERRUPTS)이 트랜잭션과 트랜잭션 사이에 있어, 여기서 statement_timeout 에러가 나면 abort 정리가 실행되지 않아 세션 잠금이 남음
세션 종료 시 ProcKill()의 "남은 잠금 없음" Assert 실패
Assert()라 --enable-cassert 빌드 필수. 12.1에서 수정 (commit 8270a0d9)
# reproduce
docker compose build
sudo chmod 777 ./logs
sudo chmod +x ./trigger.sh
docker compose up -d
./trigger.sh
# Check
statement_timeout 값을 바꿔가며 반복하다 TRAP 발생 시 멈춤 (타이밍 의존이라 시도 횟수는 실행마다 다름)
./logs/output.log에서 TRAP: FailedAssertion(... SHMQueueEmpty(&(MyProc->myProcLocks[i])) ..., File: "proc.c", Line: 832) 확인
