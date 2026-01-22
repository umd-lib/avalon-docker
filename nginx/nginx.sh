#!/bin/sh

# Make config file from template
[ -z "$AVALON_DOMAIN" ] && AVALON_DOMAIN="http://avalon"
[ -z "$AVALON_STREAMING_PORT" ] && AVALON_STREAMING_PORT=80
[ -z "$PROXY_CACHE_VALID_DURATION" ] && PROXY_CACHE_VALID_DURATION=3m
export AVALON_DOMAIN
export AVALON_STREAMING_PORT
# UMD Customization
export AVALON_STREAMING_BASE_URL
export PROXY_CACHE_VALID_DURATION
envsubst '$AVALON_DOMAIN,$AVALON_STREAMING_PORT,$AVALON_STREAMING_BASE_URL,$PROXY_CACHE_VALID_DURATION' < /etc/nginx/nginx.conf.template > /etc/nginx/nginx.conf
# End UMD Customization

exec /usr/local/nginx/sbin/nginx
