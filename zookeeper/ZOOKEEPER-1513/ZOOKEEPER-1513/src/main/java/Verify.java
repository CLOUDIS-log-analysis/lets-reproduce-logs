import java.io.BufferedReader;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.LinkedHashMap;
import java.util.Map;

/** Evaluates the explicit ZOOKEEPER-1513 result oracle. */
public final class Verify {
    private static final String EXPECTED_LENGTH =
            "Unreasonable length = 1048583";
    private static final String[] REPLAY_FRAMES = {
        "BinaryInputArchive.readBuffer",
        "Util.readTxnBytes",
        "FileTxnLog",
        "ZKDatabase.loadDataBase"
    };

    private Verify() {
    }

    public static void main(String[] args) {
        if (args.length != 3) {
            usage();
            System.exit(2);
        }

        try {
            int restartExitCode = Integer.parseInt(args[2]);
            boolean reproduced = verify(Paths.get(args[0]), Paths.get(args[1]),
                    restartExitCode);
            System.exit(reproduced ? 0 : 1);
        } catch (Exception failure) {
            System.err.println("Verification error: " + failure);
            System.exit(2);
        }
    }

    static boolean verify(Path writeEvidence, Path restartOutput,
            int restartExitCode) throws IOException {
        Map<String, String> evidence = readSimpleProperties(writeEvidence);
        String output = new String(Files.readAllBytes(restartOutput),
                StandardCharsets.UTF_8);

        String path = evidence.get("write.path");
        boolean pathPresent = path != null;
        byte[] expectedPayload = pathPresent
                ? FaultInjection.deterministicPayload(path) : new byte[0];
        boolean writeAcknowledged = "true".equals(
                evidence.get("write.acknowledged"));
        boolean payloadSizeMatches = pathPresent
                && Integer.toString(expectedPayload.length)
                .equals(evidence.get("write.payload.bytes"));
        boolean payloadDigestMatches = pathPresent
                && FaultInjection.sha256(expectedPayload)
                .equals(evidence.get("write.payload.sha256"));
        boolean transactionSizeMatches = Integer.toString(
                FaultInjection.EXPECTED_TRANSACTION_SIZE)
                .equals(evidence.get("write.transaction.bytes"));
        boolean restartFailed = restartExitCode != 0;
        boolean exactLengthSeen = output.contains(EXPECTED_LENGTH);
        boolean replayPathSeen = true;
        for (String frame : REPLAY_FRAMES) {
            replayPathSeen &= output.contains(frame);
        }

        boolean reproduced = writeAcknowledged && payloadSizeMatches
                && payloadDigestMatches && transactionSizeMatches
                && restartFailed && exactLengthSeen && replayPathSeen;

        System.out.println("write.acknowledged=" + writeAcknowledged);
        System.out.println("write.payload.size.matches=" + payloadSizeMatches);
        System.out.println("write.payload.digest.matches=" + payloadDigestMatches);
        System.out.println("write.transaction.size.matches="
                + transactionSizeMatches);
        System.out.println("restart.failed=" + restartFailed);
        System.out.println("restart.exact.length.seen=" + exactLengthSeen);
        System.out.println("restart.replay.path.seen=" + replayPathSeen);
        System.out.println("reproduced=" + reproduced);
        return reproduced;
    }

    private static Map<String, String> readSimpleProperties(Path file)
            throws IOException {
        Map<String, String> values = new LinkedHashMap<String, String>();
        BufferedReader reader = Files.newBufferedReader(file,
                StandardCharsets.UTF_8);
        try {
            String line;
            while ((line = reader.readLine()) != null) {
                if (line.isEmpty() || line.startsWith("#")) {
                    continue;
                }
                int separator = line.indexOf('=');
                if (separator <= 0) {
                    throw new IOException("Malformed evidence line: " + line);
                }
                values.put(line.substring(0, separator),
                        line.substring(separator + 1));
            }
        } finally {
            reader.close();
        }
        return values;
    }

    private static void usage() {
        System.err.println("Usage: java -cp zookeeper-1513-reproducer.jar Verify "
                + "<write-evidence.properties> <restart-output.log> "
                + "<restart-exit-code>");
    }
}
