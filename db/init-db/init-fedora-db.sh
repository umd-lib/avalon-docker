#!/bin/bash
set -e

# Source the environment varaibles set in secrets file
if [ -f /run/secrets/ap-secrets ]; then
    . /run/secrets/ap-secrets
fi

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" <<-EOSQL
  CREATE ROLE fedora LOGIN PASSWORD '$FEDORA_DB_PASSWORD';
  CREATE DATABASE fcrepo WITH ENCODING='UTF8';
  GRANT ALL PRIVILEGES ON DATABASE fcrepo TO fedora;
EOSQL
