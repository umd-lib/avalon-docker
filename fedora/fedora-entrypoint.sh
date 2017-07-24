#!/bin/sh

chown jetty:jetty /data
export JAVA_OPTIONS="${JAVA_OPTIONS} -Dfcrepo.modeshape.configuration=classpath:/config/jdbc-mysql/repository.json"
export JAVA_OPTIONS="${JAVA_OPTIONS} -Dfcrepo.mysql.username=fedora -Dfcrepo.mysql.password=${FEDORA_DB_PASSWORD} -Dfcrepo.mysql.host=db"
exec /docker-entrypoint.sh $@
