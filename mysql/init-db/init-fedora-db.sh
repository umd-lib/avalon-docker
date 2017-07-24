#!/bin/bash
set -e

mysql -uroot -p$MYSQL_ROOT_PASSWORD <<-EOSQL
  CREATE USER 'fedora'@'%' IDENTIFIED BY '$FEDORA_DB_PASSWORD';
  CREATE DATABASE fcrepo CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci; 
  GRANT ALL PRIVILEGES ON fcrepo.* TO 'fedora'@'%';
EOSQL
