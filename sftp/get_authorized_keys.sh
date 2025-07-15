#!/bin/bash

source /etc/ssh/env

curl -sf "$AUTHORIZED_KEYS_URL"
