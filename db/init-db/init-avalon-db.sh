#!/bin/bash
set -e

# Source the environment varaibles set in secrets file
if [ -f /run/secrets/ap-secrets ]; then
    . /run/secrets/ap-secrets
fi

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" <<-EOSQL
  CREATE ROLE avalon LOGIN PASSWORD '$AVALON_DB_PASSWORD';
  CREATE DATABASE avalon WITH ENCODING='UTF8';
  GRANT ALL PRIVILEGES ON DATABASE avalon TO avalon;
EOSQL
