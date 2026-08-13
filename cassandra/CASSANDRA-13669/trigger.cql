CREATE KEYSPACE testkeyspace
WITH replication = {'class': 'SimpleStrategy', 'replication_factor': '1'} 
           AND durable_writes = true;

use testkeyspace ;

CREATE TABLE testtable (
   col1 uuid,
   col2 uuid,
   ts timeuuid,
   col3 uuid,
   PRIMARY KEY((col1, col2), ts) ) with clustering order by (ts desc);

CREATE CUSTOM INDEX col3_testtable_idx ON testtable(col3)
USING 'org.apache.cassandra.index.sasi.SASIIndex'
WITH OPTIONS = {'analyzer_class': 'org.apache.cassandra.index.sasi.analyzer.StandardAnalyzer', 'mode': 'PREFIX'};

INSERT INTO testtable(col1, col2, ts, col3)
VALUES(898e0014-6161-11e7-b9b7-238ea83bd70b,
               898e0014-6161-11e7-b9b7-238ea83bd70b,
               now(), 898e0014-6161-11e7-b9b7-238ea83bd70b);
