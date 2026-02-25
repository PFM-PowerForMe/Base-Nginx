# 构建时
FROM docker.io/library/alpine:latest AS builder
ARG REPO
# eg. amd64 | arm64
ARG ARCH
# eg. x86_64 | aarch64
ARG CPU_ARCH
ARG TAG
# eg. latest
ARG IMAGE_VERSION
ENV REPO=$REPO \
     ARCH=$ARCH \
     CPU_ARCH=$CPU_ARCH \
     TAG=$TAG \
     IMAGE_VERSION=$IMAGE_VERSION
RUN apk add --no-cache --virtual .build-deps \
                gcc \
                libc-dev \
                make \
                openssl-dev \
                pcre2-dev \
                zlib-dev \
                openssl-libs-static zlib-static  \
                pcre2-static \
                linux-headers \
                libxslt-dev \
                gd-dev \
                geoip-dev \
                perl-dev \
                libedit-dev \
                bash \
                alpine-sdk \
                findutils
WORKDIR /source/
COPY source-src/ ./
RUN ./auto/configure \
        --prefix=/etc/nginx \
        --sbin-path=/usr/sbin/nginx \
        --modules-path=/usr/lib/nginx/modules \
        --conf-path=/etc/nginx/nginx.conf \
        --error-log-path=/dev/stderr \
        --http-log-path=/dev/stdout \
        --pid-path=/run/nginx/nginx.pid \
        --lock-path=/run/nginx/nginx.lock \
        --http-client-body-temp-path=/tmp/nginx/client_temp \
        --http-proxy-temp-path=/tmp/nginx/proxy_temp \
        --http-fastcgi-temp-path=/tmp/nginx/fastcgi_temp \
        --http-uwsgi-temp-path=/tmp/nginx/uwsgi_temp \
        --http-scgi-temp-path=/tmp/nginx/scgi_temp \
        --with-perl_modules_path=/usr/lib/perl5/vendor_perl \
        --user=www-data \
        --group=www-data \
        --with-compat \
        --with-file-aio \
        --with-threads \
        --with-http_addition_module \
        --with-http_auth_request_module \
        --with-http_dav_module \
        --with-http_flv_module \
        --with-http_gunzip_module \
        --with-http_gzip_static_module \
        --with-http_mp4_module \
        --with-http_random_index_module \
        --with-http_realip_module \
        --with-http_secure_link_module \
        --with-http_slice_module \
        --with-http_ssl_module \
        --with-http_stub_status_module \
        --with-http_sub_module \
        --with-http_v2_module \
        --with-mail \
        --with-mail_ssl_module \
        --with-stream \
        --with-stream_realip_module \
        --with-stream_ssl_module \
        --with-stream_ssl_preread_module \
        --with-cc-opt='-static -no-pie' \
        --with-ld-opt='-static -no-pie'
RUN make && make DESTDIR=/output install
WORKDIR /output
RUN rm -rf /output/run && \
     rm -rf /output/dev && \
     rm -rf /output/etc/nginx && \
     mv /source/conf /output/etc/nginx && \
     rm -rf /output/etc/nginx/nginx.conf && \
     mkdir -pv /output/usr/lib/nginx/modules
     # mv /output/etc/nginx/html /output/usr/share/nginx/


# 运行时
FROM busybox AS runtime
COPY --from=builder /output/ /
COPY rootfs/ /