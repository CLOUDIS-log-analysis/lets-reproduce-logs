# SERVER-77168
MongoDB Sharded Cluster 환경.
Config Server 초기화 과정 중 Replica Set 설정, Config 데이터베이스 초기화 과정에서 발생!

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




