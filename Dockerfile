# Builds a goaccess image from the current working directory:
FROM alpine:edge

COPY . /goaccess
WORKDIR /goaccess

ARG TCB=tokyocabinet-1.4.48
ARG TCB_URL=http://fallabs.com/tokyocabinet/$TCB.tar.gz

ARG build_deps="build-base ncurses-dev autoconf automake git gettext-dev geoip-dev wget"
ARG runtime_deps="tini ncurses libintl gettext openssl-dev geoip zlib libbz2 zlib-dev bzip2-dev"

RUN apk update && \
    apk add -u $runtime_deps $build_deps && \
    ([ -d $TCB ] || wget $TCB_URL && tar -xzf $TCB.tar.gz) && \
    cd $TCB && ./configure --prefix=/usr --enable-off64 --enable-fastest && \
    make && make install && cd .. && \
    autoreconf -fiv && \
    ./configure --enable-utf8 --with-openssl --enable-geoip=legacy --enable-debug --enable-tcb=btree  && \
    make && \
    make install && \
    mkdir -p /srv/goaccess/data/ && \
    cd /srv/goaccess/data/ && \
    wget -N http://geolite.maxmind.com/download/geoip/database/GeoLiteCity.dat.gz && \
    gunzip GeoLiteCity.dat.gz && \
    apk del $build_deps && \
    rm -rf /var/cache/apk/* /tmp/goaccess/* /goaccess
# goaccess.conf > geoip-database /srv/data/GeoLiteCity.dat

VOLUME /srv/data
VOLUME /srv/logs
VOLUME /srv/report
EXPOSE 7890

ENTRYPOINT ["/sbin/tini", "--"]
CMD ["goaccess", "--no-global-config", "--config-file=/srv/data/goaccess.conf", "--real-time-html"]
