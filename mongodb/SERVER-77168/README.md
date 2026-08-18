# SERVER-77168
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




