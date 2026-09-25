FROM debian:bookworm

RUN apt-get update && apt-get install -y \
    build-essential bison flex libreadline-dev zlib1g-dev \
    libssl-dev libicu-dev pkg-config git sudo \
    && rm -rf /var/lib/apt/lists/*

RUN useradd -m postgres

RUN git clone --depth 1 --branch REL_17_0 https://github.com/postgres/postgres.git /usr/src/postgres

WORKDIR /usr/src/postgres

RUN ./configure --prefix=/usr/local/pgsql --enable-cassert --enable-debug && \
    make -j4 && \
    make install

RUN mkdir -p /usr/local/pgsql/data /var/log/postgresql && \
    chown -R postgres:postgres /usr/local/pgsql/data /var/log/postgresql

ENV PATH=/usr/local/pgsql/bin:$PATH
USER postgres

RUN initdb -D /usr/local/pgsql/data

EXPOSE 5432
CMD ["postgres", "-D", "/usr/local/pgsql/data"]
