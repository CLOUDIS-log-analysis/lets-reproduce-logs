
set -e

CONTAINER_NAME="mongo101180"

sudo docker compose up -d

sleep 3

sudo docker exec -i ${CONTAINER_NAME} mongosh <<'EOF'
kCollName = "boom";
db[kCollName].insert({_id: "X".repeat(16776704)});
db[kCollName].remove({});
EOF

if [ -f ./logs/mongod.log ]; then
    tail -100 ./logs/mongod.log
else
    sudo docker logs ${CONTAINER_NAME}
fi
