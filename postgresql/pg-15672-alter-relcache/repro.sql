CREATE TABLE users(
    user_id int,
    name varchar(64),
    unique (user_id, name)
) PARTITION BY HASH(user_id);

CREATE TABLE users_000 PARTITION OF users FOR VALUES WITH (modulus 2, remainder 0);
CREATE TABLE users_001 PARTITION OF users FOR VALUES WITH (modulus 2, remainder 1);

ALTER TABLE users ALTER COLUMN name TYPE varchar(127);

BEGIN;
DROP TABLE users;
COMMIT;
