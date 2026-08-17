# Step to reproduce

```shell
direnv allow # load old python and java...
wget https://archive.apache.org/dist/cassandra/3.9/apache-cassandra-3.9-bin.tar.gz
tar -xvf apache-cassandra-3.9-bin.tar.gz
./apache-cassandra-3.9/bin/cassandra -f # in other shell!
./apache-cassandra-3.9/bin/cqlsh -f trigger.cql
```
restart cassandra server then you will get the error.
```shell
cp ./apache-cassandra-3.9/logs/debug.log ./log
```

# (CASSANDRA-13669)[https://issues.apache.org/jira/browse/CASSANDRA-13669]

카산드라 서버에 특정 쿼리를 진행하면 서버 재시작시에 크래쉬가 일어나는 이슈입니다.

