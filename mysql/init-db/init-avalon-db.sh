#!/bin/bash
set -e

mysql -uroot -p$MYSQL_ROOT_PASSWORD <<-EOSQL
  CREATE USER 'avalon'@'%' IDENTIFIED BY '$AVALON_DB_PASSWORD';
  CREATE DATABASE avalon CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci; 
  GRANT ALL PRIVILEGES ON avalon.* TO 'avalon'@'%';
EOSQL
