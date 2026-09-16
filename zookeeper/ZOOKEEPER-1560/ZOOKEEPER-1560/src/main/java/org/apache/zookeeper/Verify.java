/* Offline oracle for preserved ZOOKEEPER-1560 attempt artifacts. */
package org.apache.zookeeper;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStreamReader;

public final class Verify {
    private static final int REPRODUCED = 0;
    private static final int NOT_REPRODUCED = 1;
    private static final int INVALID_EVIDENCE = 2;

    private Verify() {
    }

    private static String readUtf8(File file) throws IOException {
        StringBuilder contents = new StringBuilder();
        BufferedReader reader = new BufferedReader(new InputStreamReader(
                new FileInputStream(file), "UTF-8"));
        try {
            char[] buffer = new char[8192];
            int count;
            while ((count = reader.read(buffer)) != -1) {
                contents.append(buffer, 0, count);
            }
        } finally {
            reader.close();
        }
        return contents.toString();
    }

    private static boolean has(String text, String token) {
        return text.indexOf(token) >= 0;
    }

    private static int verify(String clientLog, String threadDump) {
        if (!has(clientLog, "ZOOKEEPER_1560 readiness_control=passed")) {
            System.out.println("INVALID reason=readiness_control_not_passed");
            return INVALID_EVIDENCE;
        }
        if (has(clientLog, "ZOOKEEPER_1560 environment_failure")) {
            System.out.println("INVALID reason=client_reported_environment_failure");
            return INVALID_EVIDENCE;
        }
        if (!has(clientLog, "ZOOKEEPER_1560 large_create=started")) {
            System.out.println("INVALID reason=large_create_not_started");
            return INVALID_EVIDENCE;
        }
        if (has(clientLog, "ZOOKEEPER_1560 large_create=returned")) {
            System.out.println("NOT_REPRODUCED reason=large_create_returned");
            return NOT_REPRODUCED;
        }

        boolean submitRequest = has(threadDump,
                "org.apache.zookeeper.ClientCnxn.submitRequest");
        boolean create = has(threadDump, "org.apache.zookeeper.ZooKeeper.create");
        boolean waiting = has(threadDump, "java.lang.Object.wait")
                || has(threadDump, "java.lang.Object.wait0")
                || has(threadDump, "java.lang.Thread.State: WAITING");

        if (submitRequest && create && waiting) {
            System.out.println("REPRODUCED reason=timed_out_with_expected_waiting_stack");
            return REPRODUCED;
        }

        System.out.println("INVALID reason=expected_waiting_stack_missing"
                + " submitRequest=" + submitRequest
                + " create=" + create
                + " waiting=" + waiting);
        return INVALID_EVIDENCE;
    }

    private static void usage() {
        System.err.println("usage: org.apache.zookeeper.Verify"
                + " <client-output.log> <thread-dump.log>");
        System.err.println("exit 0=reproduced, 1=not reproduced, 2=invalid evidence");
    }

    public static void main(String[] args) {
        if (args.length != 2) {
            usage();
            System.exit(INVALID_EVIDENCE);
        }

        try {
            File client = new File(args[0]);
            File dump = new File(args[1]);
            if (!client.isFile() || !dump.isFile()) {
                System.err.println("both arguments must name readable regular files");
                System.exit(INVALID_EVIDENCE);
            }
            System.exit(verify(readUtf8(client), readUtf8(dump)));
        } catch (IOException failure) {
            System.err.println("verification failed: " + failure);
            System.exit(INVALID_EVIDENCE);
        }
    }
}
