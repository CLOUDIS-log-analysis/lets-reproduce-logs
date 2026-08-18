
set -e

CONTAINER_NAME="mongo51733"

sudo docker compose up -d

sleep 5

sudo docker exec -i ${CONTAINER_NAME} \
  mongo localhost:27019 \
  --authenticationDatabase "admin" \
  -u "root" \
  -p "DontTryThis1satHome" <<'EOF'
rs.initiate({
    _id:"configs",
    configsvr:true,
    members:[
        {
            _id:0,
            host:"localhost:27019"
        }
    ]
})
EOF
