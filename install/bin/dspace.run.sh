#!/bin/bash

if [ -f $ENV_FILE_PATH ]; then
    eval $(cat $ENV_FILE_PATH | while read line; do echo $line | sed 's/^\([^=]*\)=\(.*\)$/export \1="\2";/'; done)
fi

psql_connect_params="-h $POSTGRES_HOST -p $POSTGRES_PORT -U $POSTGRES_USER"
success=0

for i in {1..5}
do
    echo "Trying for the $i time(s) to connect to Postgresql server after 3 seconds ..."
    sleep 3
    psql $psql_connect_params -c 'SELECT NULL AS "Postgresql connection ok!";' || continue
    psql $psql_connect_params -tc "SELECT 1 FROM pg_database WHERE datname = '$POSTGRES_DB'" | grep -q 1 || psql $psql_connect_params -ac "CREATE DATABASE $POSTGRES_DB OWNER $POSTGRES_USER ENCODING 'UNICODE'" || continue
    cd "$DSPACE_SOURCE_PATH/dspace/target/dspace-installer/"
    ant test_database
    success=$?
    break
done

if [ $success -eq 0 ]; then
    echo "Postgresql database ok! booting DSpace from '/usr/local/tomcat/bin/catalina.sh run' ..."
    /usr/local/tomcat/bin/catalina.sh run
else
    echo "Postgresql database not ready ... aborting"
    exit 1
fi

