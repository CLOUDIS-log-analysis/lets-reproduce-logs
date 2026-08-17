# Step to reproduce

```shell

mkdir ./data
cp ./repro.sh ./data
chmod 777 ./data
chmod 777 ./data/repro.sh
docker compose up
sudo cp ./data/mongod.log log
sudo chown $(id -u) log

```

# SERVER-77168

