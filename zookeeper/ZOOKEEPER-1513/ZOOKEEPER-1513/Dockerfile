FROM eclipse-temurin:8-jdk-jammy

ARG ZK_UID=1000
ARG ZK_GID=988

RUN groupadd --gid "${ZK_GID}" zookeeper \
    && useradd --uid "${ZK_UID}" --gid "${ZK_GID}" \
        --home-dir /var/lib/zookeeper --no-create-home \
        --shell /usr/sbin/nologin zookeeper

COPY dist/zookeeper-3.3.4.tar.gz /tmp/zookeeper-3.3.4.tar.gz

RUN echo "cbb259eac2ae5c10956c49db5b2a05e112d645ac  /tmp/zookeeper-3.3.4.tar.gz" \
        | sha1sum -c - \
    && tar -xzf /tmp/zookeeper-3.3.4.tar.gz -C /opt \
    && ln -s /opt/zookeeper-3.3.4 /opt/zookeeper \
    && rm /tmp/zookeeper-3.3.4.tar.gz \
    && mkdir -p /etc/zookeeper /var/lib/zookeeper /var/log/zookeeper /result \
    && chown "${ZK_UID}:${ZK_GID}" \
        /var/lib/zookeeper /var/log/zookeeper /result

COPY zoo.cfg log4j.properties /etc/zookeeper/
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh

RUN chmod 0555 /usr/local/bin/docker-entrypoint.sh \
    && chmod 0444 /etc/zookeeper/zoo.cfg /etc/zookeeper/log4j.properties

ENV ZOOCFGDIR=/etc/zookeeper \
    ZOO_LOG_DIR=/var/log/zookeeper \
    ZOO_LOG4J_PROP=INFO,CONSOLE,ROLLINGFILE \
    SERVER_JVMFLAGS="-Xms256m -Xmx512m"

WORKDIR /opt/zookeeper
USER ${ZK_UID}:${ZK_GID}

EXPOSE 2181

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["/opt/zookeeper/bin/zkServer.sh", "start-foreground", "/etc/zookeeper/zoo.cfg"]
