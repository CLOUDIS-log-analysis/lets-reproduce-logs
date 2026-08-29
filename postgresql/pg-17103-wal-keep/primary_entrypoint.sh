#!/usr/bin/env bash
set -e

chown postgres:postgres /var/lib/postgresql/data
chown postgres:postgres /var/log/postgresql
su - postgres -c "/usr/lib/postgresql/13/bin/initdb -D /var/lib/postgresql/data"

cp -a /var/lib/postgresql/data/pg_wal/* /wal_disk/
chown -R postgres:postgres /wal_disk

rm -rf /var/lib/postgresql/data/pg_wal
su - postgres -c "ln -s /wal_disk /var/lib/postgresql/data/pg_wal"

cat <<EOF >> /var/lib/postgresql/data/postgresql.conf
listen_addresses = '*'
wal_level = replica
max_slot_wal_keep_size = 280MB
checkpoint_timeout = 5min
max_wal_size=32MB
log_error_verbosity = verbose
logging_collector = on
log_directory = '/var/log/postgresql'
log_filename = 'postgresql.log'
log_min_messages = debug2
log_error_verbosity = verbose
EOF

echo "host replication all all trust" >> /var/lib/postgresql/data/pg_hba.conf
echo "host all all all trust" >> /var/lib/postgresql/data/pg_hba.conf

exec su - postgres -c "/usr/lib/postgresql/13/bin/postgres -D /var/lib/postgresql/data"
