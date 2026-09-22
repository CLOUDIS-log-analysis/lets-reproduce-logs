/*
 * Reproduction client for ZOOKEEPER-1560.
 *
 * This class intentionally uses the synchronous ZooKeeper.create API. The
 * experiment driver owns the 30-second wall-clock deadline and captures a
 * thread dump before terminating a client that is still blocked.
 */
package org.apache.zookeeper;

import java.io.IOException;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.TimeUnit;

public final class Reproduce implements Watcher {
    static final int PAYLOAD_BYTES = 500000;
    static final int SESSION_TIMEOUT_MS = 10000;
    static final int CONNECT_TIMEOUT_MS = 15000;
    static final String LARGE_PATH = "/large";
    static final String READY_PATH = "/zookeeper-1560-readiness";
    static final String SASL_CLIENT_CONFIG_PROPERTY =
            "zookeeper.sasl.clientconfig";
    static final String JAAS_CONFIG_PROPERTY =
            "java.security.auth.login.config";
    static final String NO_SASL_LOGIN_CONTEXT = "ZooKeeper1560NoSasl";

    private final CountDownLatch connected = new CountDownLatch(1);

    public void process(WatchedEvent event) {
        if (event.getState() == Event.KeeperState.SyncConnected) {
            connected.countDown();
        }
    }

    private static void emit(String value) {
        System.out.println("ZOOKEEPER_1560 " + value);
        System.out.flush();
    }

    private static byte[] deterministicPayload() {
        byte[] payload = new byte[PAYLOAD_BYTES];
        int i;
        for (i = 0; i < payload.length; i++) {
            payload[i] = (byte) (i * 31 + 17);
        }
        return payload;
    }

    private static String connectString(String[] args) {
        String value = System.getenv("ZK_CONNECT");
        if (value == null || value.length() == 0) {
            value = "127.0.0.1:2181";
        }

        int i;
        for (i = 0; i < args.length; i++) {
            if ("--connect".equals(args[i])) {
                if (i + 1 >= args.length) {
                    throw new IllegalArgumentException("--connect requires host:port");
                }
                value = args[++i];
            } else if (!"--inject-small-send-buffer".equals(args[i])) {
                throw new IllegalArgumentException("unknown argument: " + args[i]);
            }
        }
        return value;
    }

    private static boolean injectionRequested(String[] args) {
        int i;
        for (i = 0; i < args.length; i++) {
            if ("--inject-small-send-buffer".equals(args[i])) {
                return true;
            }
        }
        return false;
    }

    /*
     * ZooKeeper 3.4.4 can incorrectly treat the JVM's non-null default JAAS
     * Configuration as an active SASL setup (ZOOKEEPER-1455), indefinitely
     * deferring even the one-byte readiness request. This standalone
     * reproduction does not configure SASL. Naming an absent login context
     * selects 3.4.4's own LoginException fallback, while preserving any
     * explicit JAAS/SASL configuration supplied by the caller.
     */
    private static void configureStandaloneSaslFallback() {
        if (System.getProperty(SASL_CLIENT_CONFIG_PROPERTY) == null
                && System.getProperty(JAAS_CONFIG_PROPERTY) == null) {
            System.setProperty(SASL_CLIENT_CONFIG_PROPERTY,
                    NO_SASL_LOGIN_CONTEXT);
            emit("sasl_setup=standalone_fallback");
        }
    }

    private int run(String[] args) throws Exception {
        String connect = connectString(args);
        boolean inject = injectionRequested(args);
        configureStandaloneSaslFallback();
        if (inject) {
            FaultInjection.install();
        }

        emit("client_start connect=" + connect
                + " payload_bytes=" + PAYLOAD_BYTES
                + " fault_injection=" + (inject ? "enabled" : "disabled"));

        ZooKeeper zk = null;
        try {
            zk = new ZooKeeper(connect, SESSION_TIMEOUT_MS, this);
            if (!connected.await(CONNECT_TIMEOUT_MS, TimeUnit.MILLISECONDS)) {
                emit("environment_failure phase=connect reason=timeout");
                return 2;
            }
            emit("connected");

            byte[] control = new byte[] { 1 };
            zk.create(READY_PATH, control, ZooDefs.Ids.OPEN_ACL_UNSAFE,
                    CreateMode.PERSISTENT);
            zk.delete(READY_PATH, -1);
            emit("readiness_control=passed");

            byte[] payload = deterministicPayload();
            emit("large_create=started path=" + LARGE_PATH
                    + " payload_bytes=" + payload.length);
            long startedNanos = System.nanoTime();
            String created = zk.create(LARGE_PATH, payload,
                    ZooDefs.Ids.OPEN_ACL_UNSAFE, CreateMode.PERSISTENT);
            long elapsedMillis = TimeUnit.NANOSECONDS.toMillis(
                    System.nanoTime() - startedNanos);
            emit("large_create=returned path=" + created
                    + " elapsed_ms=" + elapsedMillis);
            return 0;
        } catch (Throwable failure) {
            emit("environment_failure type=" + failure.getClass().getName()
                    + " message=" + safeMessage(failure));
            failure.printStackTrace(System.err);
            System.err.flush();
            return 2;
        } finally {
            if (zk != null) {
                try {
                    zk.close();
                } catch (InterruptedException interrupted) {
                    Thread.currentThread().interrupt();
                }
            }
        }
    }

    private static String safeMessage(Throwable failure) {
        String message = failure.getMessage();
        if (message == null) {
            return "none";
        }
        return message.replace('\n', ' ').replace('\r', ' ');
    }

    public static void main(String[] args) throws IOException {
        int exit;
        try {
            exit = new Reproduce().run(args);
        } catch (Throwable failure) {
            emit("environment_failure type=" + failure.getClass().getName()
                    + " message=" + safeMessage(failure));
            failure.printStackTrace(System.err);
            exit = 2;
        }
        System.exit(exit);
    }
}
