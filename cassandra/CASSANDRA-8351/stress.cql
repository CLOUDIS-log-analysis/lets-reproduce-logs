CREATE KEYSPACE IF NOT EXISTS "Keyspace1" WITH replication = {'class': 'SimpleStrategy', 'replication_factor': '1'}  AND durable_writes = true;

CREATE TABLE IF NOT EXISTS "Keyspace1"."Standard1" (
    key blob PRIMARY KEY,
    "C0" blob,
    "C1" blob,
    "C2" blob,
    "C3" blob,
    "C4" blob
) WITH COMPACT STORAGE
    AND caching = '{"keys":"ALL", "rows_per_partition":"NONE"}'
    AND comment = ''
    AND compaction = {'min_threshold': '4', 'class': 'org.apache.cassandra.db.compaction.SizeTieredCompactionStrategy', 'max_threshold': '32'}
    AND dclocal_read_repair_chance = 0.1
    AND default_time_to_live = 0
    AND gc_grace_seconds = 864000
    AND max_index_interval = 2048
    AND memtable_flush_period_in_ms = 0
    AND min_index_interval = 128
    AND read_repair_chance = 0.0
    AND speculative_retry = 'NONE';

COPY "Keyspace1"."Standard1" FROM 'stress.csv';
COPY "Keyspace1"."Standard1" FROM 'stress.csv';
COPY "Keyspace1"."Standard1" FROM 'stress.csv';
COPY "Keyspace1"."Standard1" FROM 'stress.csv';
COPY "Keyspace1"."Standard1" FROM 'stress.csv';
COPY "Keyspace1"."Standard1" FROM 'stress.csv';
COPY "Keyspace1"."Standard1" FROM 'stress.csv';
COPY "Keyspace1"."Standard1" FROM 'stress.csv';


