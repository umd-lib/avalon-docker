#!/bin/sh

# Source the environment varaibles set in secrets file
if [ -f /run/secrets/ap-secrets ]; then
    . /run/secrets/ap-secrets
fi

chown jetty:jetty /data
export JAVA_OPTIONS="${JAVA_OPTIONS} -Dfcrepo.modeshape.configuration=${FEDORA_MODESHAPE_CONFIGURATION}"
export JAVA_OPTIONS="${JAVA_OPTIONS} -Dfcrepo.postgresql.host=${FEDORA_DB_HOST} -Dfcrepo.postgresql.port=${FEDORA_DB_PORT} -Dfcrepo.postgresql.db_name=${FEDORA_DB_NAME}"
export JAVA_OPTIONS="${JAVA_OPTIONS} -Dfcrepo.postgresql.username=${FEDORA_DB_USER} -Dfcrepo.postgresql.password=${FEDORA_DB_PASSWORD}"
export JAVA_OPTIONS="${JAVA_OPTIONS} -Dfcrepo.binary.minimum.size=${FEDORA_BINARY_MIN_SIZE}"
exec /docker-entrypoint.sh $@
