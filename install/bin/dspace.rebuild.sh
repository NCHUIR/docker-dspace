#!/bin/bash

if [ -f $ENV_FILE_PATH ]; then
    export $(cat $ENV_FILE_PATH);
fi

rsync --exclude=.git --exclude=*.swp --exclude=*.swo -urv $DSPACE_OUTSIDE_SOURCE_PATH/ $DSPACE_SOURCE_PATH
dspace.build "-U clean package" "update"

