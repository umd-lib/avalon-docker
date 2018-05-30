#!/bin/bash

# Add the secrets to the container environment script
if [ -f /run/secrets/ap-secrets ]; then
    cat /run/secrets/ap-secrets >> /etc/profile.d/container_environment.sh
fi