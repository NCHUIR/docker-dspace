#!/bin/bash

function set_build.properties {
  sed -i -E "s/^ *$(echo $1 | sed 's/\./\\./g') *=.*$/$1=$(echo $2 | sed 's/\//\\\//g')/" $DSPACE_SOURCE_PATH/build.properties
}
if [ -z "$POSTGRES_URL" ] && [ "$POSTGRES_HOST" ] && [ "$POSTGRES_PORT" ] && [ "$POSTGRES_DB" ]; then
  export POSTGRES_URL="jdbc:postgresql://$POSTGRES_HOST:$POSTGRES_PORT/$POSTGRES_DB"
fi
set_build.properties 'db.url' $POSTGRES_URL

if [ "$POSTGRES_DB" ]; then
  set_build.properties 'db.name' $POSTGRES_DB
fi
if [ "$POSTGRES_USER" ]; then
  set_build.properties 'db.username' $POSTGRES_USER
fi
if [ "$POSTGRES_PASSWORD" ]; then
  set_build.properties 'db.password' $POSTGRES_PASSWORD
fi
if [ "$DSPACE_INSTALL_PATH" ]; then
  set_build.properties 'dspace.install.dir' $DSPACE_INSTALL_PATH
fi

