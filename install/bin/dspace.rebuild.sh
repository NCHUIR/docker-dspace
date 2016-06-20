#!/bin/bash

if [ -f $ENV_FILE_PATH ]; then
    export $(cat $ENV_FILE_PATH);
fi

if [ "$1" ]; then
    mvn_target="$1"
else
    mvn_target="package -P !dspace-lni,!dspace-oai,!dspace-sword,!dspace-swordv2,!dspace-xmlui"
fi
if [ "$2" ]; then
    ant_target="$2"
else
    ant_target="update"
fi

rsync --exclude=.git --exclude=*.swp --exclude=*.swo -urv $DSPACE_OUTSIDE_SOURCE_PATH/ $DSPACE_SOURCE_PATH
dspace.build "$mvn_target" "$ant_target"

