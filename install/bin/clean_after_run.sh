#!/bin/bash

if [ -f $ENV_FILE_PATH ]; then
    eval $(cat $ENV_FILE_PATH | while read line; do echo $line | sed 's/^\([^=]*\)=\(.*\)$/export \1="\2";/'; done)
fi
bash -e $1 || exit $?
rm -rf /tmp/* /var/tmp/*

