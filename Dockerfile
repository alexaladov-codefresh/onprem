FROM alpine:3.18

# add our user and group first to make sure their IDs get assigned consistently, regardless of whatever dependencies get added
RUN addgroup -S redis && adduser -S -G redis redis

# grab su-exec for easy step-down from root
RUN apk add --no-cache 'su-exec>=0.2'

ENV REDIS_VERSION 7.2.0
ENV REDIS_DOWNLOAD_URL http://download.redis.io/releases/redis-7.2.0.tar.gz
ENV REDIS_DOWNLOAD_SHA 8b12e242647635b419a0e1833eda02b65bf64e39eb9e509d9db4888fb3124943
ENV JQ_DOWNLOAD_URL https://github.com/jqlang/jq/releases/download/jq-1.7/jq-linux-arm64

# for redis-sentinel see: http://redis.io/topics/sentinel
RUN set -ex; \
        \
        apk add --no-cache --virtual .build-deps \
                coreutils \
                gcc \
                linux-headers \
                make \
                musl-dev \
        ; \
        \
    wget -q -O /usr/local/bin/jq "$JQ_DOWNLOAD_URL"; \
    chmod +x /usr/local/bin/jq; \
        wget -O redis.tar.gz "$REDIS_DOWNLOAD_URL"; \
        echo "$REDIS_DOWNLOAD_SHA *redis.tar.gz" | sha256sum -c -; \
        mkdir -p /usr/src/redis; \
        tar -xzf redis.tar.gz -C /usr/src/redis --strip-components=1; \
        rm redis.tar.gz; \
        \
        \
        make -C /usr/src/redis -j "$(nproc)"; \
        make -C /usr/src/redis install; \
        \
    rm -r /usr/src/redis

RUN apk add --update \
    python3 \
    python3-dev \
    py-pip \
    bash \
    curl \
    curl-dev

RUN pip install --upgrade pip && \
    pip install rdbtools==0.1.15 python-lzf==0.2.4
