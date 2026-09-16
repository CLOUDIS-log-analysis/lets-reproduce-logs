# [issue-1851](https://github.com/haproxy/haproxy/issues/1851)

haproxy에 http3 요청을 넣으면 segmentation fault로 인해 크래시 되는 이슈입니다.

# 원인

http3의 QUIC 기반 연결을 진행 중 ssl_tlsext_ticket_key_cb() 함수 안에서 QUIC이 아닌 일반 연결용 구조체를 사용, 이를 이용해서 구한 ref 포인터가 NULL이기 때문에 null pointer dereferncing이 일어남 

```
	struct connection *conn;
	int head;
	int i;
	int ret = -1; /* error by default */

	conn = SSL_get_ex_data(s, ssl_app_data_index);
	ref  = __objt_listener(conn->target)->bind_conf->keys_ref;
	HA_RWLOCK_RDLOCK(TLSKEYS_REF_LOCK, &ref->lock);
```


# 수정

조건문을 통해 QUIC 전용 로직을 따로 만듦

```
static int ssl_tlsext_ticket_key_cb(SSL *s, unsigned char key_name[16], unsigned char *iv, EVP_CIPHER_CTX *ectx, MAC_CTX *hctx, int enc)
{
-	struct tls_keys_ref *ref;
+	struct tls_keys_ref *ref = NULL;
	union tls_sess_key *keys;
-	 struct connection *conn;
	int head;
	int i;
	int ret = -1; /* error by default */
+	struct connection *conn = SSL_get_ex_data(s, ssl_app_data_index);
+#ifdef USE_QUIC
+	struct quic_conn *qc = SSL_get_ex_data(s, ssl_qc_app_data_index);
+#endif
+
+	if (conn)
+		ref  = __objt_listener(conn->target)->bind_conf->keys_ref;
+#ifdef USE_QUIC
+	else if (qc)
+		ref =  qc->li->bind_conf->keys_ref;
+#endif
+
+	if (!ref) {
+		/* must never happen */
+		ABORT_NOW();
+	}

-	conn = SSL_get_ex_data(s, ssl_app_data_index);
-	ref  = __objt_listener(conn->target)->bind_conf->keys_ref;
	HA_RWLOCK_RDLOCK(TLSKEYS_REF_LOCK, &ref->lock);
```

수정 커밋: https://github.com/haproxy/haproxy/commit/6aec1f380e095cc36b279c4c9e1a955d01d41f6c

# 로그 연관성

프로그램 자체에서 출력하는 로그에는 버그와 관련된 정보가 없지만,

uftrace를 사용하여 추출한 함수 호출 내역에는 segfault가 일어나기 직전에 실행 중이던 함수인 ssl_tlsext_ticket_key_cb()를 확인할 수 있습니다.

```
...
   0.561 us [ 991963] |         quic_parse_crypto_frame(); /* src/quic_frame.c:449 */
   0.741 us [ 991963] |       } /* qc_parse_frm */
            [ 991963] |       qc_provide_cdata() { /* src/xprt_quic.c:2182 */
   0.371 us [ 991963] |         ssl_sock_msgcbk(); /* src/ssl_sock.c:2055 */
            [ 991963] |         ssl_tlsext_ticket_key_cb() { /* src/ssl_sock.c:1155 */

uftrace stopped tracing with remaining functions
================================================
task: 991956
[2] _do_poll
[1] run_poll_loop
[0] main

task: 991961
[0] dummy_thread_function

task: 991963
[7] ssl_tlsext_ticket_key_cb
[6] SSL_do_handshake
[5] qc_provide_cdata
[4] qc_parse_pkt_frms
[3] qc_treat_rx_pkts
[2] quic_conn_io_cb
[1] process_runnable_tasks
[0] run_poll_loop


...
```
uftrace 기록에서 발췌한 부분
