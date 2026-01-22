#!/bin/sh
# UMD Customization
# Build newer version of NGINX with nginx-vod-module
set -e

NGINX_VERSION=1.24.0

cd /usr/src

# nginx source
curl -fsSLO https://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz
tar xzf nginx-${NGINX_VERSION}.tar.gz
mv nginx-${NGINX_VERSION} nginx

# nginx-vod-module (latest stable tag)
git clone https://github.com/kaltura/nginx-vod-module.git
cd nginx-vod-module
git fetch --tags
git checkout $(git describe --tags --abbrev=0)

# build nginx
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
  --with-debug \
  --error-log-path=/dev/stderr \
  --http-log-path=/dev/stdout

make -j$(nproc)
make install

# cleanup
cd /
rm -rf /usr/src/nginx \
       /usr/src/nginx-vod-module \
       /usr/src/nginx-${NGINX_VERSION}.tar.gz
# End UMD Customization
