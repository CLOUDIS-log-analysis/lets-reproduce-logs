import uuid
from cassandra import ConsistencyLevel
from cassandra import InvalidRequest
from cassandra.cluster import Cluster
from cassandra.auth import PlainTextAuthProvider
from cassandra.policies import ConstantReconnectionPolicy
from cassandra.cqltypes import UUID
 
# DROP KEYSPACE IF EXISTS cs;
# CREATE KEYSPACE cs WITH replication = {'class': 'SimpleStrategy', 'replication_factor': 1};
# USE cs;
# CREATE TABLE test3 (name text, value uuid, sentinel text, PRIMARY KEY (name));
# CREATE INDEX test3_sentinels ON test3(sentinel);             
 
class CassandraDemo(object):
 
    def __init__(self):
        ips = ["127.0.0.1"]
        ap = PlainTextAuthProvider(username="cassandra", password="cassandra")
        reconnection_policy = ConstantReconnectionPolicy(20.0, max_attempts=1000000)
        cluster = Cluster(ips, auth_provider=ap, protocol_version=3, reconnection_policy=reconnection_policy)
        self.session = cluster.connect("cs")
 
    def exec_query(self, query, args):
        prepared_statement = self.session.prepare(query)
        prepared_statement.consistency_level = ConsistencyLevel.LOCAL_QUORUM
        self.session.execute(prepared_statement, args)
 
    def bug(self):
        k1 = UUID( str(uuid.uuid4()) )       
        long_string = "X" * 65536
        query = "INSERT INTO test3 (name, value, sentinel) VALUES (?, ?, ?);"
        args = ("foo", k1, long_string)
 
        self.exec_query(query, args)
        self.session.execute("DROP KEYSPACE IF EXISTS cs_test", timeout=30)
        self.session.execute("CREATE KEYSPACE cs_test WITH replication = {'class': 'SimpleStrategy', 'replication_factor': 1}")
         
c = CassandraDemo()

#first run
c.bug()

print("first run")

#second run, Cassandra crashes with java.lang.AssertionError
c.bug()

