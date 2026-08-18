# SERVER-115200
# 1 -> 2 -> 3 -> 4 -> 5
https://jira.mongodb.org/browse/SERVER-115200

# 1. 컨테이너 실행

```bash
sudo docker compose up -d
```

# 2. 더미데이터 삽입 (중요 x, 저널 생성을 위해서 진행)

```bash
cat > ~/repro115200_insert.js <<'JS'
const dbx = db.getSiblingDB("repro115200");

dbx.t.drop();

for (let b = 0; b < 30; b++) {
  const docs = [];

  for (let i = 0; i < 1000; i++) {
    docs.push({
      _id: b * 1000 + i,
      pad: "x".repeat(2000),
      ts: new Date()
    });
  }

  dbx.runCommand({
    insert: "t",
    documents: docs,
    writeConcern: { j: true }
  });

  print("batch", b, "inserted");
}

print("count:", dbx.t.countDocuments());
JS
```
# 위 파일을 컨테이너에 복사하고, 실행한다.
```bash
sudo docker cp ~/repro115200_insert.js \
  mongo115200:/tmp/repro115200_insert.js

sudo docker exec mongo115200 \
  mongosh --quiet /tmp/repro115200_insert.js
```


# 3. mongod 종료
```bash
sudo docker kill -s SIGKILL mongo115200
```

# 4. WiredTiger journal 손상시키기!!

journal 파일 일부 `0xffffffff`로 덮어써서 손상 만들기.

```bash
sudo python3 - "$WTLOG" <<'PY'
import sys

p = sys.argv[1]
offset = 128

with open(p, "r+b") as f:
    f.seek(offset)
    before = f.read(16)

    f.seek(offset)
    f.write(b"\xff\xff\xff\xff")

print("patched:", p)
print("offset:", offset)
print("before:", before.hex())
print("after: ffffffff")
PY
```

# 5. MongoDB 재시작

```bash
cd ~/mongo115200
sudo docker compose start
```


