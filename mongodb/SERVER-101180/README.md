# SERVER-101180
# 1 -> 2 -> 3

# 1. 컨테이너 실행

```bash
sudo docker compose up -d
```

# 2. MongoDB Shell 접속

```bash
sudo docker exec -it mongo101180 mongosh
```

# 3. 재현 코드 실행

MongoDB Shell에서 아래 코드를 그대로 실행한다.

```javascript
kCollName = "boom";
db[kCollName].insert({_id: "X".repeat(16776704)});
db[kCollName].remove({});
```

# 간단한 설명!
MongoDB의 BatchedDelete 처리 과정에서 invariant failure가 발생해서 mongoDB가 비정상 종료된다.