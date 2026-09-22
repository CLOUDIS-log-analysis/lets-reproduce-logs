git clone https://github.com/redis/redis
cd redis
git checkout 3c9b817217b03d0377bed3857f0159a473711490~
make

./src/redis-server --loglevel debug --logfile ../output.log

./src/redis-cli
DEBUG POPULATE 1000000
MEMORY DOCTOR

