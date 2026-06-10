#!/bin/sh
# UMD Customization
# Build NGINX with nginx-vod-module using the system nginx source package.
# Using apt-get source (Ubuntu Noble) instead of a pinned nginx.org tarball
# for better compatibility with the Noble toolchain.
set -e

# Get nginx source from Ubuntu Noble apt sources (requires deb-src in sources.list)
cd /usr/src && apt-get source nginx && mv nginx-* nginx

# nginx-vod-module (latest stable tag)
cd /usr/src && git clone https://github.com/kaltura/nginx-vod-module.git
cd /usr/src/nginx-vod-module && git checkout -b latest-tag $(git describe --tags)

# build nginx
cd /usr/src && git clone https://github.com/nginx/njs.git
cd /usr/src/nginx

./configure \
  --prefix=/usr/local/nginx \
  --conf-path=/etc/nginx/nginx.conf \
  --with-file-aio \
  --with-threads \
  --with-http_ssl_module \
  --with-http_auth_request_module \
  --with-http_sub_module \
  --with-cc-opt="-O3" \
  --add-module=/usr/src/nginx-vod-module \
  --add-module=/usr/src/njs/nginx \
  --with-debug \
  --error-log-path=/dev/stderr \
  --http-log-path=/dev/stdout

make -j$(nproc)
make install

# cleanup
cd / && rm -rf /usr/src/*
# End UMD Customization
