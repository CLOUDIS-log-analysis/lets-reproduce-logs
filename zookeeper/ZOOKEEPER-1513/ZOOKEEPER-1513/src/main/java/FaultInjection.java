import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.nio.charset.StandardCharsets;

import org.apache.zookeeper.ZooKeeper;
import org.apache.zookeeper.data.Stat;

/**
 * The explicit boundary operation that creates the problematic transaction.
 *
 * <p>Do not replace this with a prebuilt transaction log. ZOOKEEPER-1513 is
 * reproduced only when ZooKeeper itself accepts an ordinary client write and
 * persists the transaction that it later cannot replay.</p>
 */
public final class FaultInjection {
    public static final String DEFAULT_ZNODE = "/zookeeper-1513";
    public static final int EXPECTED_TRANSACTION_SIZE = 1_048_583;

    // ZooKeeper 3.3.4's binary transaction consists of a 32-byte TxnHeader,
    // then the SetDataTxn path (4-byte length + UTF-8 bytes), data (4-byte
    // length + bytes), and version (4 bytes).
    private static final int TXN_HEADER_SIZE = 32;
    private static final int SET_DATA_FIXED_SIZE = 12;

    private FaultInjection() {
    }

    /**
     * Build deterministic data whose persisted transaction is exactly the
     * 1,048,583-byte record reported by ZOOKEEPER-1513. The data itself stays
     * below 3.3.4's 0xfffff readBuffer limit, so the live request is accepted.
     */
    public static byte[] deterministicPayload(String path) {
        byte[] payload = new byte[expectedPayloadSize(path)];
        for (int i = 0; i < payload.length; i++) {
            payload[i] = (byte) ((i * 31 + 17) & 0xff);
        }
        return payload;
    }

    public static int expectedPayloadSize(String path) {
        int pathBytes = path.getBytes(StandardCharsets.UTF_8).length;
        int payloadSize = EXPECTED_TRANSACTION_SIZE - TXN_HEADER_SIZE
                - SET_DATA_FIXED_SIZE - pathBytes;
        if (payloadSize < 0) {
            throw new IllegalArgumentException("znode path is too long: " + path);
        }
        return payloadSize;
    }

    /**
     * Submit the boundary-sized setData request and return only after the
     * server acknowledges it.
     */
    public static Stat inject(ZooKeeper client, String path, byte[] payload)
            throws Exception {
        int expectedSize = expectedPayloadSize(path);
        if (payload.length != expectedSize) {
            throw new IllegalArgumentException(
                    "Fault payload must be exactly " + expectedSize
                            + " bytes, but was " + payload.length);
        }
        return client.setData(path, payload, -1);
    }

    public static String sha256(byte[] payload) {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            byte[] hash = digest.digest(payload);
            StringBuilder value = new StringBuilder(hash.length * 2);
            for (byte octet : hash) {
                value.append(String.format("%02x", octet & 0xff));
            }
            return value.toString();
        } catch (NoSuchAlgorithmException impossible) {
            throw new IllegalStateException("SHA-256 is unavailable", impossible);
        }
    }
}
