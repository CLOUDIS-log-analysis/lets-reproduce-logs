git clone https://github.com/redis/redis
cd redis
git checkout 77a91442452548e901c2830c7e6b77c4e542d4bb~
make

./src/redis-server --loglevel debug --logfile ../output.log

./src/redis-cli
set foo 1
bitfield foo get i1 0
