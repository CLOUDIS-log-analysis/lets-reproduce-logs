# [SERVER-77168](https://jira.mongodb.org/browse/SERVER-77168)
Time Series Collection을 mongorestore로 복원할 때 mongodb가 crash하는 버그이다.

# 재현 방법
```shell

mkdir ./data
cp ./repro.sh ./data
chmod 777 ./data
chmod 777 ./data/repro.sh
docker compose up
sudo cp ./data/mongod.log log
sudo chown $(id -u) log

```

# 원인 및 수정

유저의 잘못된 입력을 받고 서버가 강제종료 되도록 한것이 원인이다.

수정된 버전에서는 잘못된 입력에 대해 예외처리로 대응하여 강제종료가 일어나지 않도록 한다.

# 로그 연관성

[수정 커밋](https://github.com/mongodb/mongo/commit/75b3b24942dec1877602d294b91aa46f87abc4e2)

핵심 로그:
```json
{"t":{"$date":"2026-08-15T07:38:50.073+00:00"},"s":"F",  "c":"ASSERT",   "id":23079,   "ctx":"conn26","msg":"Invariant failure","attr":{"expr":"!collectionName.startsWith(\"system.buckets.\")","file":"src/mongo/db/auth/resource_pattern.h","line":133}}
```

로그가 가리키는 코드 위치와 실제로 수정된 코드가 일치하여 로그 연관성이 매우 높다.
