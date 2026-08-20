FROM ubuntu:20.04

RUN apt-get update && apt-get install -y\
    gcc make git bash && rm -rf /var/lib/apt/lists/*

RUN git clone --branch 3.0.5 --depth 1 https://github.com/redis/redis.git /redis-3.0.5 && cd /redis-3.0.5 && sed -i 's/childpid = fork()/childpid = -1/g' src/aof.c && make

CMD ["/redis-3.0.5/src/redis-server", "--loglevel", "debug", "--logfile", "/var/log/baseline.log"]
