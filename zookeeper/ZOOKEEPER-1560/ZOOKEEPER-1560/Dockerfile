FROM debian:bookworm-slim@sha256:88200866dfff7ea7f5cbcb6ec7c8a701889efe6fe859fe64d6990e4b07ea4171

ARG ZK_ARCHIVE=zookeeper-3.4.4.tar.gz
ARG JDK_ARCHIVE=zulu6.22.0.3-ca-jdk6.0.119-linux_x64.tar.gz

COPY dist/${ZK_ARCHIVE} dist/${JDK_ARCHIVE} dist/SHA256SUMS /tmp/dist/

RUN set -eux; \
    cd /tmp/dist; \
    sha256sum -c SHA256SUMS; \
    tar -xzf "${ZK_ARCHIVE}" -C /opt; \
    tar -xzf "${JDK_ARCHIVE}" -C /opt; \
    ln -s /opt/zookeeper-3.4.4 /opt/zookeeper; \
    ln -s /opt/zulu6.22.0.3-jdk6.0.119-linux_x64 /opt/java; \
    groupadd --gid 1000 zookeeper; \
    useradd --uid 1000 --gid 1000 --home-dir /opt/zookeeper --shell /usr/sbin/nologin zookeeper; \
    install -d -o zookeeper -g zookeeper -m 0755 /data /logs /result; \
    rm -rf /tmp/dist

COPY --chmod=0644 config/zoo.cfg config/log4j.properties /opt/zookeeper/conf/
COPY --chmod=0755 scripts/docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh

ENV JAVA_HOME=/opt/java \
    ZK_HOME=/opt/zookeeper \
    ZOOCFGDIR=/opt/zookeeper/conf \
    ZOO_LOG_DIR=/logs \
    ZOO_LOG4J_PROP=INFO,CONSOLE,ROLLINGFILE \
    JMXDISABLE=true \
    SERVER_JVMFLAGS="-Xms128m -Xmx512m -Djava.io.tmpdir=/data/tmp" \
    PATH=/opt/java/bin:/opt/zookeeper/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

WORKDIR /opt/zookeeper
USER 1000:1000
EXPOSE 2181

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["/opt/zookeeper/bin/zkServer.sh", "start-foreground", "/opt/zookeeper/conf/zoo.cfg"]
