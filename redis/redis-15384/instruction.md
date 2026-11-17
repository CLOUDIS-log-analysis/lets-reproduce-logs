git clone https://github.com/redis/redis
cd redis
git checkout 8.8.0
make

./src/redis-server --loglevel debug --logfile ./output.log

./src/redis-cli
VADD v VALUES 1 1 a
VRANDMEMBER v -9223372036854775808 

