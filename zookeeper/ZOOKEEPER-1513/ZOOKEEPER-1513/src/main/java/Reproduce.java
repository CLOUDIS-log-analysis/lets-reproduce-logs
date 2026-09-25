import java.io.BufferedWriter;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardOpenOption;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.TimeUnit;

import org.apache.zookeeper.CreateMode;
import org.apache.zookeeper.KeeperException;
import org.apache.zookeeper.WatchedEvent;
import org.apache.zookeeper.Watcher;
import org.apache.zookeeper.ZooDefs;
import org.apache.zookeeper.ZooKeeper;
import org.apache.zookeeper.data.Stat;

/**
 * Creates the normal client transaction needed to reproduce ZOOKEEPER-1513.
 * Server stop/restart is intentionally controlled outside this process so the
 * same persistent bind mount can be retained for replay.
 */
public final class Reproduce {
    private static final int SESSION_TIMEOUT_MS = 10_000;
    private static final int CONNECT_TIMEOUT_SECONDS = 20;
    private static final byte[] INITIAL_DATA =
            "initial".getBytes(StandardCharsets.UTF_8);

    private Reproduce() {
    }

    public static void main(String[] args) {
        if (args.length < 2 || args.length > 3) {
            usage();
            System.exit(2);
        }

        String connectString = args[0];
        Path evidenceFile = Paths.get(args[1]);
        String znode = args.length == 3 ? args[2] : FaultInjection.DEFAULT_ZNODE;

        try {
            reproduce(connectString, znode, evidenceFile);
        } catch (Exception failure) {
            System.err.println("Reproduction write failed: " + failure);
            failure.printStackTrace(System.err);
            System.exit(1);
        }
    }

    static void reproduce(String connectString, String znode, Path evidenceFile)
            throws Exception {
        validateZnode(znode);
        refuseExistingEvidence(evidenceFile);

        final CountDownLatch connected = new CountDownLatch(1);
        ZooKeeper client = new ZooKeeper(connectString, SESSION_TIMEOUT_MS,
                new Watcher() {
                    @Override
                    public void process(WatchedEvent event) {
                        if (event.getState() == Event.KeeperState.SyncConnected) {
                            connected.countDown();
                        }
                    }
                });

        try {
            if (!connected.await(CONNECT_TIMEOUT_SECONDS, TimeUnit.SECONDS)) {
                throw new IOException("Timed out connecting to " + connectString);
            }

            try {
                client.create(znode, INITIAL_DATA, ZooDefs.Ids.OPEN_ACL_UNSAFE,
                        CreateMode.PERSISTENT);
            } catch (KeeperException.NodeExistsException exists) {
                throw new IllegalStateException(
                        "The reproduction znode already exists; use a clean attempt: "
                                + znode,
                        exists);
            }

            byte[] payload = FaultInjection.deterministicPayload(znode);
            Stat acknowledged = FaultInjection.inject(client, znode, payload);

            Map<String, String> evidence = new LinkedHashMap<String, String>();
            evidence.put("write.acknowledged", "true");
            evidence.put("write.path", znode);
            evidence.put("write.payload.bytes", Integer.toString(payload.length));
            evidence.put("write.payload.sha256", FaultInjection.sha256(payload));
            evidence.put("write.transaction.bytes", Integer.toString(
                    FaultInjection.EXPECTED_TRANSACTION_SIZE));
            evidence.put("write.version", Integer.toString(acknowledged.getVersion()));
            evidence.put("write.mzxid", Long.toString(acknowledged.getMzxid()));
            writeEvidenceCreateOnly(evidenceFile, evidence);

            System.out.println("ACKNOWLEDGED path=" + znode
                    + " bytes=" + payload.length
                    + " version=" + acknowledged.getVersion()
                    + " mzxid=" + acknowledged.getMzxid());
            System.out.println("Evidence: " + evidenceFile.toAbsolutePath());
        } finally {
            client.close();
        }
    }

    private static void validateZnode(String znode) {
        if (!znode.startsWith("/") || "/".equals(znode)
                || znode.endsWith("/")) {
            throw new IllegalArgumentException(
                    "znode must be an absolute non-root path: " + znode);
        }
    }

    private static void refuseExistingEvidence(Path evidenceFile)
            throws IOException {
        if (Files.exists(evidenceFile)) {
            throw new IOException("Refusing to overwrite evidence: " + evidenceFile);
        }
    }

    private static void writeEvidenceCreateOnly(Path evidenceFile,
            Map<String, String> evidence) throws IOException {
        Path absolute = evidenceFile.toAbsolutePath();
        Path parent = absolute.getParent();
        if (parent != null && !Files.isDirectory(parent)) {
            throw new IOException("Evidence directory does not exist: " + parent);
        }

        BufferedWriter writer = Files.newBufferedWriter(absolute,
                StandardCharsets.UTF_8, StandardOpenOption.CREATE_NEW,
                StandardOpenOption.WRITE);
        try {
            for (Map.Entry<String, String> entry : evidence.entrySet()) {
                writer.write(entry.getKey());
                writer.write('=');
                writer.write(entry.getValue());
                writer.newLine();
            }
        } finally {
            writer.close();
        }
    }

    private static void usage() {
        System.err.println("Usage: java -jar zookeeper-1513-reproducer.jar "
                + "<connect-string> <new-evidence.properties> [znode]");
    }
}
