#!/bin/sh

chown jetty:jetty /data
export JAVA_OPTIONS="${JAVA_OPTIONS} -Dfcrepo.home=/data -Dfcrepo.postgresql.host=db -Dfcrepo.postgresql.port=5432 -Dfcrepo.postgresql.username=fedora -Dfcrepo.postgresql.password=${FEDORA_DB_PASSWORD} -Dfcrepo.modeshape.configuration=classpath:/config/jdbc-postgresql/repository.json"
exec /docker-entrypoint.sh $@
