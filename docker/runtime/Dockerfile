FROM ubuntu:18.04

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        ca-certificates \
        libboost-filesystem1.65.1 \
        libboost-program-options1.65.1 \
        libboost-regex1.65.1 \
        libboost-system1.65.1 \
        libboost-thread1.65.1 \
        libbz2-1.0 \
        libmysqlclient20 \
        libreadline7 \
        libssl1.1 \
        tzdata \
        zlib1g \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /opt/legion/server
