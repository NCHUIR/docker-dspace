#!/bin/bash

if [ -f $ENV_FILE_PATH ]; then
    export $(cat $ENV_FILE_PATH);
fi
bash -e $1 || exit $?
rm -rf /tmp/* /var/tmp/*

