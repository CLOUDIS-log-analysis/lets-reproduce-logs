FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive

#1. 최초 필수 패키지
RUN apt-get update && apt-get install -y \
	wget \
	build-essential \
	libreadline-dev \
	zlib1g-dev \
	gdb \
	&& rm -rf /var/lib/apt/lists/*

#2. 다운로드 및 압축해제
RUN wget https://ftp.postgresql.org/pub/source/v12.1/postgresql-12.1.tar.gz && tar -xzf postgresql-12.1.tar.gz

WORKDIR /postgresql-12.1

#3. RELSEG_SIZE 1로 변경
RUN sed -i 's/^#define RELSEG_SIZE/\/\* #define RELSEG_SIZE/g' src/include/pg_config_manual.h && \
    echo '#define RELSEG_SIZE 1' >> src/include/pg_config_manual.h

#4. 디버그 및 설치
RUN ./configure CFLAGS="-g -O0" && make -j$(nproc) && make install

#5. 권한 설정 및 DB 클러스터 초기화
RUN useradd -m postgres && \
mkdir -p /usr/local/pgsql/data && \
chown -R postgres:postgres /usr/local/pgsql

USER postgres
RUN /usr/local/pgsql/bin/initdb -D /usr/local/pgsql/data

#6. 표준 엔트리포인트
ENTRYPOINT ["/usr/local/pgsql/bin/postgres", "-D", "/usr/local/pgsql/data"]
