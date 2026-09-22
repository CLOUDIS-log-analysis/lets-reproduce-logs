git clone https://github.com/redis/redis
cd redis
git checkout e2c1f80b464a3a6dde961bb30bff9a39c17c6b29~
make

./src/redis-server --loglevel debug --logfile ../output.log

telnet
MONITOR
unknowncommand

