#!/bin/bash

set -o pipefail
if [ -f $ENV_FILE_PATH ]; then
    eval $(cat $ENV_FILE_PATH | while read line; do echo $line | sed 's/^\([^=]*\)=\(.*\)$/export \1="\2";/'; done)
fi

if [ "$1" ]; then
    mvn_target="$1"
else
    mvn_target="package -P !dspace-lni,!dspace-sword,!dspace-swordv2,!dspace-xmlui"
fi
if [ "$2" ]; then
    ant_target="$2"
else
    ant_target="update"
fi

rsync --exclude=.git --exclude=*.swp --exclude=*.swo -urv --exclude=target/ --size-only --delete $DSPACE_OUTSIDE_SOURCE_PATH/ $DSPACE_SOURCE_PATH
dspace.build "$mvn_target" "$ant_target"

