/*
 * Explicit, opt-in fault injection for ZOOKEEPER-1560.
 *
 * The vulnerable ZooKeeper 3.4.4 transport code is not replaced or patched.
 * This socket subclass only makes partial nonblocking writes easier to reach
 * by constraining SO_SNDBUF before connect. ClientCnxnSocketNIO.doIO remains
 * the unmodified implementation from the 3.4.4 dependency.
 */
package org.apache.zookeeper;

import java.io.IOException;
import java.nio.channels.SocketChannel;

public final class FaultInjection extends ClientCnxnSocketNIO {
    public static final String SEND_BUFFER_PROPERTY =
            "zookeeper1560.sendBufferBytes";
    public static final int DEFAULT_SEND_BUFFER_BYTES = 1024;

    public FaultInjection() throws IOException {
        super();
    }

    public static void install() {
        System.setProperty(ZooKeeper.ZOOKEEPER_CLIENT_CNXN_SOCKET,
                FaultInjection.class.getName());
    }

    SocketChannel createSock() throws IOException {
        SocketChannel channel = super.createSock();
        int requested = Integer.getInteger(SEND_BUFFER_PROPERTY,
                DEFAULT_SEND_BUFFER_BYTES).intValue();
        if (requested <= 0) {
            channel.close();
            throw new IOException(SEND_BUFFER_PROPERTY + " must be positive");
        }
        channel.socket().setSendBufferSize(requested);
        System.out.println("ZOOKEEPER_1560 fault_injection=socket_send_buffer"
                + " requested_bytes=" + requested
                + " actual_bytes=" + channel.socket().getSendBufferSize());
        System.out.flush();
        return channel;
    }
}
