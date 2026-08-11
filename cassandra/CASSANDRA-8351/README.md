# Step to reproduce

```shell
direnv allow # load old python and java...
wget https://archive.apache.org/dist/cassandra/2.1.2/apache-cassandra-2.1.2-bin.tar.gz
tar -xvf apache-cassandra-2.1.2-bin.tar.gz
sed -i 's/<root level="INFO">/<root level="DEBUG">/g' ./apache-cassandra-2.1.2/conf/logback.xml
./apache-cassandra-2.1.2/bin/cassandra -f # in other shell!
./apache-cassandra-2.1.2/bin/cqlsh -f stress.cql --debug 2>&1 | tee cqlsh-log
# cassanra 서버에서 버그가 일어나지는 않지만 cqlsh와 통신과정에서 많은 로그가 생성되기 때문에 기록
cp ./apache-cassandra-2.1.2/logs/system.log cassandra-log 
```

# CASSANDRA-8351
이 이슈는 cassandra 서버 자체의 버그가 아닌, 부속 프로그램인 cqlsh에 일어나는 segfault에 관한 내용입니다. 

화면 마지막에 출력되는 segfault 라인은 실행 중이던 프로세스에서 나온 로그가 아닌 실행할 때 사용한 shell의 메시지입니다.

bash의 경우:
```
Segmentation fault (core dumped)
```
fish의 경우:
```
fish: Job 1, './apache-cassandra-2.1.2/bin/cq…' terminated by signal SIGSEGV (Address boundary error)
segmentation
```

이 메시지는 리다이렉션 되지 않기 때문에 남겨진 로그 파일에는 남지 않습니다.
