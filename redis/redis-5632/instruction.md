git clone https://github.com/redis/redis
cd redis
git checkout c710d4afdccc0c797745bc3264f3f32a4cdd85da~
make

./src/redis-server --loglevel debug --logfile ../output.log

./src/redis-cli
SET "" ""
KEYS "\x00*z"

