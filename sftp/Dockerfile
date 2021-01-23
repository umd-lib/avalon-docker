FROM atmoz/sftp

RUN apt-get update \
    && apt-get install -y curl \
    && apt-get clean

COPY get_authorized_keys.sh  /etc/ssh/get_authorized_keys.sh

COPY init.sh /etc/sftp.d/init.sh
