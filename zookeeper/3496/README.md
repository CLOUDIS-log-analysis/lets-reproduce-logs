# ZOOKEEPER-3496 재현 보고서

## 재현 절차

1. (로컬)docker compose up
2. (zk-py) pip install uv
3. (zk-py) uv sync
4. (zk-py) uv add kazoo
5. (zk-py) uv run normal.py
6. (zk-py) uv run reproduce.py
7. (로컬) docker ps
8. (로컬) /logs 디렉토리 zookeeper.log 확인

## 비고

- 로깅은 롤링파일 및 콘솔로 했음
- log4j 설정으로 둘다 저장 및 송출 가능함
- zoo.cfg는 도커 허브의 이미지에 내장된 환경변수로 사용할 것임
