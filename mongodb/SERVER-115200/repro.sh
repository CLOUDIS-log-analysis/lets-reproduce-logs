
set -e

CONTAINER_NAME="mongo115200"
BASE_DIR="$HOME/mongo115200"
JOURNAL_DIR="$BASE_DIR/data/journal"

sudo docker compose up -d

cat > /tmp/repro115200_insert.js <<'JS'
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

sudo docker cp /tmp/repro115200_insert.js ${CONTAINER_NAME}:/tmp/repro115200_insert.js

sudo docker exec ${CONTAINER_NAME} mongosh --quiet /tmp/repro115200_insert.js

sudo docker kill -s SIGKILL ${CONTAINER_NAME}

WTLOG=$(sudo find "${JOURNAL_DIR}" -maxdepth 1 -type f -name 'WiredTigerLog.*' | sort | tail -1)

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

sudo docker start ${CONTAINER_NAME}

sleep 5

sudo docker ps -a --filter name=${CONTAINER_NAME}

sudo grep -Ei 'WiredTiger|WTRECOV|journal|recovery|corrupt|fatal|signal|segv|SIGSEGV|BACKTRACE|abort|assert|invariant|D[1-5]|DEBUG_[1-5]' "${BASE_DIR}/logs/mongod.log" -C 10 || true
