# Overview
XADD … MAXLEN ~1 명령이 반복실행되면 stream은 설정된 최대길이 유지를 위해 오래된 데이터 제거

이 때 성능을 위해 즉시 물리적 해제가 아닌 Tombstone(삭제 마킹) 처리만 수행(논리적 삭제)

이 상태에서 XAUTOCLAIM 명령을 호출하여 이미 삭제된 미아 메시지 ID 배열 생성을 위한 heap 메모리 할당

Tombstone 엔트리 수와 실제 유효 엔트리수를 기반으로 메모리 버퍼의 할당 크기 산출과정에서 결함 존재(메모리 할당 시 실제 필요한 공간보다 작은 크기의 heap할당)

overflow된 데이터가 메모리를 손상시키고 손상된 메모리에 접근 시 SIGSEGV발생


# Step to reproduce
sudo chmod 777 logs

sudo chmod +x trigger.sh

docker compose up -d

./trigger.sh

docker compose down

# Check
SIGSEGV에 의해 종료되며 output.log로그에 bug report 기록됨
