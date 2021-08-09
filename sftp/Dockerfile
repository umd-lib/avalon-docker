FROM atmoz/sftp

RUN apt-get update \
    && apt-get install -y curl rsync \
    && apt-get clean

RUN groupadd --gid 1000 group_1000 \
    && useradd --no-user-group --non-unique --uid 1000 --gid 1000 app \
    && mkdir -p /home/app \
    && chown root:root /home/app \
    && chmod 755 /home/app \
    && usermod -p "*" app

RUN chr=/home/app \
    && mkdir -p $chr/bin \
    && cd $chr \
    && cp -v /bin/sh $chr/bin \
    && cp -v /usr/bin/rsync $chr/bin \
    && list="$(ldd /bin/sh | egrep -o '/lib.*\.[0-9]')" \
    && for i in $list; do cp -v --parents "$i" "${chr}"; done \
    && list="$(ldd /usr/bin/rsync | egrep -o '/usr/lib.*\.[0-9]')" \
    && for i in $list; do cp -v --parents "$i" "${chr}"; done \
    && chown root:root -R /home/app

COPY get_authorized_keys.sh  /etc/ssh/get_authorized_keys.sh
COPY sshd_config  /etc/ssh/sshd_config

COPY init.sh /etc/sftp.d/init.sh
