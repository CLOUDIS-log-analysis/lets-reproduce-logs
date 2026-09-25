SET maintenance_work_mem = '64kB';
CREATE TABLE t (a int, b int);
INSERT INTO t SELECT g, g FROM generate_series(1, 100000) g;
CREATE INDEX ON t (a);
CREATE INDEX ON t (b);
VACUUM (PARALLEL 2) t;
