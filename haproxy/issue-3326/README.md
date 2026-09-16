# [issue-3326](https://github.com/haproxy/haproxy/issues/3326)

haproxy 설정파일에 존재하지 않는 ip 주소를 입력하면 segmentation fault로 인해 크래시 되는 이슈입니다.

# 원인

존재하지 않는 ip주소에 대한 접속 실패 코드를 실행 중 잘못된 함수 sc_conn_process()를 호출하여 함수 내부에서 null pointer dereferncing이 일어남

# 수정

잘못된 함수 sc_conn_process()를 tasklet_wakeup()으로 교체함

```c
fail:
		/* let the upper layer know the connection failed */
		if (sc) {
-			sc_conn_process(sc);
+			tasklet_wakeup(sc->wait_event.tasklet, TASK_WOKEN_MSG);
		}
		else if (conn_reverse_in_preconnect(conn)) {
			struct listener *l = conn_active_reverse_listener(conn);
```

수정 커밋: https://github.com/haproxy/haproxy/commit/b7add82f9211e0bc87ed5361220694ffc10c0062

# 로그 연관성

프로그램 자체에서 출력하는 로그에는 버그와 관련된 정보가 없지만,

uftrace를 사용하여 추출한 함수 호출 내역에는 segfault가 일어나기 직전에 실행 중이던 함수인 sc_notify()를 확인할 수 있습니다.

프로그램이 크래시 될때의 함수 호출 스택 또한 기록되어 sc_notify() 함수가 sc_conn_process() 함수 안에서 호출 됐음을 알 수 있습니다.

```
...
   0.070 us [ 710573] |           ssl_sock_get_ctx(); /* src/ssl_sock.c:894 */
   0.891 us [ 710573] |           ssl_sock_handle_hs_error(); /* src/ssl_sock.c:5984 */
            [ 710573] |           conn_create_mux() { /* src/connection.c:106 */
            [ 710573] |             sc_conn_process() { /* src/stconn.c:1620 */
            [ 710573] |               sc_notify() { /* src/stconn.c:906 */

uftrace stopped tracing with remaining functions
================================================
task: 710566
[3] _do_poll
[2] run_poll_loop
[1] run_thread_poll_loop
[0] main

task: 710572
[0] dummy_thread_function

task: 710573
[7] sc_notify
[6] sc_conn_process
[5] conn_create_mux
[4] ssl_sock_io_cb
[3] run_tasks_from_lists
[2] process_runnable_tasks
[1] run_poll_loop
[0] run_thread_poll_loop
...
```
uftrace 기록에서 발췌한 부분
