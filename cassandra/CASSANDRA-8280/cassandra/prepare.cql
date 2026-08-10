DROP KEYSPACE IF EXISTS cs;
CREATE KEYSPACE cs WITH replication = {'class': 'SimpleStrategy', 'replication_factor': 1};
USE cs;
CREATE TABLE test3 (name text, value uuid, sentinel text, PRIMARY KEY (name));
CREATE INDEX test3_sentinels ON test3(sentinel);             
