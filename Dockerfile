FROM alpine:3.21 AS builder

LABEL maintainer="Omer Segev"
LABEL description="This image contains DCMTK and is used to run the forwarder."

ARG dcmtk_version

# Install build dependencies and build DCMTK
RUN apk update && apk add --no-cache \
    build-base \
    cmake \
    git \
    bash \
    bison \
    flex \
    gnu-libiconv-dev \
    zlib-dev \
    libpng-dev \
    openssl-dev \
    libxml2-dev && \
    cd /opt && \
    git clone https://github.com/DCMTK/dcmtk.git dcmtk-${dcmtk_version} && \
    mkdir dcmtk-${dcmtk_version}-build && \
    cd /opt/dcmtk-${dcmtk_version}-build && \
    cmake ../dcmtk-${dcmtk_version} && \
    make -j$(nproc) && \
    make DESTDIR=/tmp/dcmtk install

# Final stage
FROM alpine:3.21

LABEL maintainer="Omer Segev"
LABEL description="This image contains DCMTK ${dcmtk_version} and is used to run the forwarder."

# Install runtime dependencies
RUN apk add --no-cache \
    bash \
    gnu-libiconv \
    zlib \
    libpng \
    openssl \
    libxml2 \
    haproxy \
    libstdc++ \
    libgcc

# Copy built DCMTK from builder stage
COPY --from=builder /tmp/dcmtk/ /

# Copy configuration and scripts
COPY config/haproxy.cfg /etc/haproxy/haproxy.cfg
COPY scripts/parser.lua /etc/haproxy/parser.lua
COPY --chown=daemon:daemon scripts/forward.sh /forward.sh
COPY --chown=daemon:daemon entrypoint.sh /entrypoint.sh

# Make scripts executable
RUN chmod +x /forward.sh /entrypoint.sh

# Switch to non-root user for better security
USER daemon

ENTRYPOINT ["/entrypoint.sh"]