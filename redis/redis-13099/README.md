# Step to reproduce

sudo chmod 777 log

sudo chmod +x trigger/*.sh

sudo docker compose up -d

cd trigger

./01-stress-io.sh && ./02-run-benchmark.sh

cd ..

sudo docker compose down
