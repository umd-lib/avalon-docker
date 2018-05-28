#!/bin/sh

# Source the environment varaibles set in secrets file
if [ -f /run/secrets/ap-secrets ]; then
    . /run/secrets/ap-secrets
fi

chown jetty:jetty /data
export JAVA_OPTIONS="${JAVA_OPTIONS} -Dfcrepo.modeshape.configuration=classpath:/config/jdbc-postgresql/repository.json"
export JAVA_OPTIONS="${JAVA_OPTIONS} -Dfcrepo.postgresql.username=fedora -Dfcrepo.postgresql.password=${FEDORA_DB_PASSWORD} -Dfcrepo.postgresql.host=db"
exec /docker-entrypoint.sh $@
