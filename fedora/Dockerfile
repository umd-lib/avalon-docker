FROM        jetty:alpine
MAINTAINER  Michael B. Klein <michael.klein@northwestern.edu>
ARG         FEDORA_VERSION=4.7.5
ARG         FEDORA_DB_PASSWORD
ADD         https://github.com/fcrepo4/fcrepo4/releases/download/fcrepo-${FEDORA_VERSION}/fcrepo-webapp-${FEDORA_VERSION}.war ${JETTY_BASE}/fedora/fedora.war
ADD         fedora.xml ${JETTY_BASE}/webapps/fedora.xml
USER        root
RUN         /bin/chown -R jetty:jetty ${JETTY_BASE}/fedora/ 
ADD         fedora-entrypoint.sh /
ADD         repository.json /conf/repository.json
ENV         FEDORA_MODESHAPE_CONFIGURATION=file:/conf/repository.json
ENV         FEDORA_DB_HOST=db
ENV         FEDORA_DB_PORT=5432
ENV         FEDORA_DB_NAME=fcrepo
ENV         FEDORA_DB_USER=fedora
ENTRYPOINT  "/fedora-entrypoint.sh"
