# [redis-5663](https://github.com/redis/redis/pull/5663)

monitor client가 redis 서버로 잘못된 명령을 보내면 서버가 크래시 되는 이슈 

비정상 동작:
```shell
> telnet localhost 6379
Trying ::1...
Connected to localhost.
Escape character is '^]'.
> MONITOR
+OK
> unknowncommand
Connection closed by foreign host.
```
잘못된 명령을 보내자 서버의 크래시로 인한 연결 종료


정상 동작:
```shell
> telnet localhost 6379
Trying ::1...
Connected to localhost.
Escape character is '^]'.
> MONITOR
+OK
> unknowncommand
-ERR unknown command 'unknowncommand'
```
잘못된 명령을 보냈다는 메시지를 보냄


# 원인

## Master-Slave 관계
2개 이상의 redis서버를 대상으로하여
master의 데이터를 다른 slaves들로 복제하여 운용 가능 

클라이언트에게 보낼 에러 메시지를 작성하는 코드
```c
void addReplyErrorLength(client *c, const char *s, size_t len) {
    /* If the string already starts with "-..." then the error code
     * is provided by the caller. Otherwise we use "-ERR". */
    if (!len || s[0] != '-') addReplyString(c,"-ERR ",5);
    addReplyString(c,s,len);
    addReplyString(c,"\r\n",2);

    /* Sometimes it could be normal that a slave replies to a master with
     * an error and this function gets called. Actually the error will never
     * be sent because addReply*() against master clients has no effect...
     * A notable example is:
     *
     *    EVAL 'redis.call("incr",KEYS[1]); redis.call("nonexisting")' 1 x
     *
     * Where the master must propagate the first change even if the second
     * will produce an error. However it is useful to log such events since
     * they are rare and may hint at errors in a script or a bug in Redis. */
    if (c->flags & (CLIENT_MASTER|CLIENT_SLAVE)) {
        char* to = c->flags & CLIENT_MASTER? "master": "replica";
        char* from = c->flags & CLIENT_MASTER? "replica": "master";
        char *cmdname = c->lastcmd ? c->lastcmd->name : "<unknown>";
        serverLog(LL_WARNING,"== CRITICAL == This %s is sending an error "
                             "to its %s: '%s' after processing the command "
                             "'%s'", from, to, s, cmdname);
        /* Here we want to panic because when a master is sending an
         * error to some slave in the context of replication, this can
         * only create some kind of offset or data desynchronization. Better
         * to catch it ASAP and crash instead of continuing. */
        if (c->flags & CLIENT_SLAVE)
            serverPanic("Continuing is unsafe: replication protocol violation.");
    }
}
```
master와 slave 간의 데이터 무결성을 지키는 것이 중요

만약 에러 메시지를 master나 slave로 보내고 있다면 데이터 무결성이 오염되었을 가능성이 높아 더 오염되기 전에 빠르게 panic 

## MONITOR
monitor 명령은 클라이언트를 monitor client로 만듦

monitor client는 다른 client의 명령을 읽는 것이 가능 (주로 디버깅 전용 기능)


## 문제점
CLIENT_SLAVE flag를 가지는 클라이언트의 두가지 가능성:
  1. 클라이언트가 slave (CLIENT_SLAVE)
  2. 클라이언트가 monitor (CLIENT_SLAVE | CLIENT_MONITOR)

monitor 클라이언트는 slave 클라이언트의 동작을 공통으로 사용할 수 있도록 CLIENT_SLAVE flag가 추가로 저장됨

문제가 되는 조건문에서는 CLIENT_SLAVE가 있는지 만을 확인하기 때문에 CLIENT_SLAVE와 CLIENT_MONITOR가 동시에 있는 monitor client를 slave client와 구별하지 못함


# 수정

CLIENT_MONITOR를 확인하는 조건을 추가함

```c
  - if (c->flags & (CLIENT_MASTER|CLIENT_SLAVE)) {
  + if (c->flags & (CLIENT_MASTER|CLIENT_SLAVE) && !(c->flags & CLIENT_MONITOR)) {
        char* to = c->flags & CLIENT_MASTER? "master": "replica";
        char* from = c->flags & CLIENT_MASTER? "replica": "master";
        char *cmdname = c->lastcmd ? c->lastcmd->name : "<unknown>";
```

수정 커밋: https://github.com/redis/redis/pull/5663/changes/e2c1f80b464a3a6dde961bb30bff9a39c17c6b29
