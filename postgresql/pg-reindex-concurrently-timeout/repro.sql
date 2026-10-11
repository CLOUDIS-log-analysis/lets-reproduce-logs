CREATE TABLE t(i) AS SELECT * FROM generate_series(1,9);
CREATE INDEX ON t(i);
