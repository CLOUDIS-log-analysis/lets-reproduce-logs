# Step to reproduce

```shell
cd ./cassandra
sudo docker compose up -d
cd ../trigger
mvn clean package
cd ../cassandra
sudo docker compose down
```

check ./log/debug.log
