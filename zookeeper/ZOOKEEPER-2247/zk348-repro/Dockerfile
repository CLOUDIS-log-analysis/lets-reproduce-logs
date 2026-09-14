FROM eclipse-temurin:8-jre

ENV ZOOKEEPER_HOME=/opt/zookeeper
ENV PATH="${ZOOKEEPER_HOME}/bin:${PATH}"

# Logging policy is part of the image.
# Application logs -> /logs/zookeeper.log
# Raw stdout/stderr -> /logs/zookeeper.out (entrypoint.sh)
ENV ZOO_LOG_DIR=/logs
ENV ZOO_LOG4J_PROP=DEBUG,FILE


RUN mkdir -p "${ZOOKEEPER_HOME}" \
    && curl -fL \
       "https://archive.apache.org/dist/zookeeper/zookeeper-3.4.8/zookeeper-3.4.8.tar.gz" \
       -o /tmp/zookeeper.tar.gz \
    && tar -xzf /tmp/zookeeper.tar.gz \
       -C "${ZOOKEEPER_HOME}" \
       --strip-components=1 \
    && rm /tmp/zookeeper.tar.gz

COPY zoo.cfg ${ZOOKEEPER_HOME}/conf/zoo.cfg
COPY log4j.properties ${ZOOKEEPER_HOME}/conf/log4j.properties
COPY entrypoint.sh /entrypoint.sh

WORKDIR ${ZOOKEEPER_HOME}

RUN chmod +x /entrypoint.sh \
    && mkdir -p /data /datalog /logs

EXPOSE 2181 2888 3888

ENTRYPOINT ["/entrypoint.sh"]
