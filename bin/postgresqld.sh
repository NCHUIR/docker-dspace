#!/bin/sh
### In postgresd.sh (make sure this file is chmod +x):
# `/sbin/setuser postgres` runs the given command as the user `postgres`.
# If you omit that part, the command will be run as root.

POSTGRESQL_BIN=$(echo /usr/lib/postgresql/*/bin/postgres)
POSTGRESQL_HOME=$(echo /var/lib/postgresql/*/main)
POSTGRESQL_CONFIG_FILE=$(echo /etc/postgresql/*/main/postgresql.conf)

exec /sbin/setuser postgres $POSTGRESQL_BIN -D $POSTGRESQL_HOME -c config_file=$POSTGRESQL_CONFIG_FILE >>/var/log/postgresd.log 2>&1

