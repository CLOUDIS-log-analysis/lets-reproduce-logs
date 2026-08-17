# Step to reproduce

```shell
cd ./cassandra
sudo docker compose up -d
cd ../trigger
direnv allow
mvn clean package
cd ../cassandra
sudo docker compose down
cp ./log/debug.log log
```

# [CASSANDRA-15896](https://issues.apache.org/jira/browse/CASSANDRA-15896)

카산드라 서버에 exception을 발생시키는 이슈입니다.

