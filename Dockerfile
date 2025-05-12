FROM alpine:3.21

LABEL maintainer="Omer Segev"
LABEL description="This image contains DCMTK ${dcmtk_version} and is used to run the forwarder."

ARG dcmtk_version


RUN apk update && apk add --no-cache build-base cmake git bash bison flex gnu-libiconv-dev gnu-libiconv zlib zlib-dev \
    libpng-dev openssl-dev libxml2-dev

RUN cd /opt && \
    git clone https://github.com/DCMTK/dcmtk.git dcmtk-${dcmtk_version} && mkdir dcmtk-${dcmtk_version}-build

RUN cd /opt/dcmtk-${dcmtk_version}-build && cmake ../dcmtk-${dcmtk_version} && make -j4 && make DESTDIR=/ install

RUN rm -rf /opt/*
RUN apk add --no-cache haproxy
COPY config/haproxy.cfg /etc/haproxy/haproxy.cfg
COPY --chown=daemon:daemon scripts/forward.sh /forward.sh
COPY --chown=daemon:daemon entrypoint.sh /entrypoint.sh
COPY scripts/parser.lua /etc/haproxy/parser.lua
#USER daemon
ENTRYPOINT ["/entrypoint.sh"]