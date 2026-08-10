# Step to reproduce

```shell
cd ./cassandra
sudo docker compose up -d
cd ../trigger
direnv allow
mvn clean package
cd ../cassandra
sudo docker compose down
```

check ./logs/debug.log
