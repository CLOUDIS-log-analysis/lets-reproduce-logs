# [CASSANDRA-13669](https://issues.apache.org/jira/browse/CASSANDRA-13669)
새로운 카산드라 노드를 시작할때 
$CASSANDRA_HOME/data/data 디렉토리가 없으며
config의 설정 항목인 data_disk_usage_max_disk_size의 값이 설정되어 있으면
startup exception이 발생하여 크래시되는 이슈입니다.

# 원인과 해결
startup 시에 필요한 디렉토리들를 생성하는 createAllDirectories() 함수가 data_disk_usage_max_disk_size의 값을 사용하는 applyGuardrails() 함수보다 늦게 호출되고 $CASSANDRA_HOME/data/data 디렉토리를 찾지 못하여
```
java.lang.RuntimeException: Cannot get data directories grouped by file store
```
이러한 예외를 출력하고 크래시됩니다.

수정 커밋에서는 applyGuardrails()와 createAllDirectories()의 순서를 바꿔서 이슈를 해결합니다.

수정 커밋: https://github.com/apache/cassandra/pull/4272/changes/ce94c60a410e596353575a01bc3cfb67e08141be

