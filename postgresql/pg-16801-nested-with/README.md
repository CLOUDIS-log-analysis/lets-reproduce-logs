# Overview
13버전으로 업데이트되면서 List가 linked-list에서 expansible array로 바뀜

깊게 중첩된 WITH RECURSIVE 쿼리를 파싱하는 과정에서 처음 할당된 배열 용량을 넘기면 배열 전체가 새 위치로 복사되고 기존 배열은 해제됨

리스트에 저장해둔  포인터는 기존 (대글링)포인터를 계속 가르켜 접근 시 크래시 발생

# reproduce
sudo chmod +x ./trigger.sh
./trigger.sh

# Check
생성된 ./logs/output.log에서 was terminated by signal 11: Segmentation fault 확인
