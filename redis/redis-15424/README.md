# Requirements

- 실행하는 유저의 그룹에 docker를 추가할 것(docker 명령을 sudo 없이 사용 가능)

- python 설치하기 혹은 direnv allow 

# Step to reproduce

./run.sh

# redis-15424

특정 동작 수행 중 확률적으로 crash가 발생하는 이슈

keys가 5000이 넘어가도 crash가 발생하지 않으면 재시도 추천
