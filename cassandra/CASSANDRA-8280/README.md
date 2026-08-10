# Step to reproduce

```shell
cd ./cassandra
direnv allow # load old python and java...
wget https://archive.apache.org/dist/cassandra/2.1.1/apache-cassandra-2.1.1-bin.tar.gz
tar -xvf apache-cassandra-2.1.1-bin.tar.gz
sed -i 's/<root level="INFO">/<root level="DEBUG">/g' ./apache-cassandra-2.1.1/conf/logback.xml
./apache-cassandra-2.1.1/bin/cassandra -f # in other shell!
./apache-cassandra-2.1.1/bin/cqlsh -f prepare.cql
cd ../triger
direnv allow
python CASSANDRA-8280.py
# ctrl+c
cd ..
```

check apache-cassandra-2.1.1/logs/system.log

