#!/bin/bash

# Copy the SSH Host keys from /host_keys if exists
if [ -d "/host_keys" ]; then
  cp /host_keys/* /etc/ssh/
  chmod 600 -R /etc/ssh/ssh_host_*
fi

# Set the AUTHORIZED_KEYS_URL environment variable in
# /etc/ssh/env as the get_authroized_keys.sh needs it.
echo export AUTHORIZED_KEYS_URL=$AUTHORIZED_KEYS_URL >> /etc/ssh/env
