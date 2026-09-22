# [redis-3783](https://github.com/redis/redis/issues/3783)

redis 메모리의 상태를 분석하는 명령인 MEMORY DOCTOR을 전달하면 signal 8 (division-by-zero)로 인해 크래시되는 이슈

# 원인

redis를 복제본(slave) 노드 없이 사용하면
복제 노드의 수를 나타내는 numslaves의 값이 0이됨

MEMORY DOCTOR 명령어를 통해 redis 서버의 메모리 점검을 실시함

getMemoryDoctorReport 함수가 호출됨

만약 redis에 할당된 메모리의 총량을 나타내는 total_allocated 변수의 값이 5MB(1024*1024*5)보다 크거나 같다면

mh->clients_slaves / numslaves 이라는 계산이 실행되고 numslaves는 0이기 때문에 division-by-zero로인한 크래시

```c
/* This implements MEMORY DOCTOR. An human readable analysis of the Redis
 * memory condition. */
sds getMemoryDoctorReport(void) {
    int empty = 0;          /* Instance is empty or almost empty. */
    int big_peak = 0;       /* Memory peak is much larger than used mem. */
    int high_frag = 0;      /* High fragmentation. */
    int big_slave_buf = 0;  /* Slave buffers are too big. */
    int big_client_buf = 0; /* Client buffers are too big. */
    int num_reports = 0;
    struct redisMemOverhead *mh = getMemoryOverheadData();

    if (mh->total_allocated < (1024*1024*5)) {
        empty = 1;
        num_reports++;
    } else {
        /* Peak is > 150% of current used memory? */
        if (((float)mh->peak_allocated / mh->total_allocated) > 1.5) {
            big_peak = 1;
            num_reports++;
        }

        /* Fragmentation is higher than 1.4? */
        if (mh->fragmentation > 1.4) {
            high_frag = 1;
            num_reports++;
        }

        /* Clients using more than 200k each average? */
        long numslaves = listLength(server.slaves);
        long numclients = listLength(server.clients)-numslaves;
        if (mh->clients_normal / numclients > (1024*200)) {
            big_client_buf = 1;
            num_reports++;
        }

        /* Slaves using more than 10 MB each? */
        if (mh->clients_slaves / numslaves<<값이 0이므로 크래시>> > (1024*1024*10)) {
            big_slave_buf = 1;
            num_reports++;
        }
...
```

# 수정

numslaves > 0 조건 추가

```c
  -  if (mh->clients_slaves / numslaves > (1024*1024*10)) {
  +  if (numslaves > 0 && mh->clients_slaves / numslaves > (1024*1024*10)) {
        big_slave_buf = 1;
        num_reports++;
    }
```
