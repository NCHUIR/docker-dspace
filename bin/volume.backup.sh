#!/bin/bash

DATA_VOLUME=/data
DBDATA_VOLUME=/dbdata
DATA_TARGET=/data_target
BAK_ROOT="$DATA_TARGET/bak"
BAK_TARGET="$BAK_ROOT/$(date +%Y%m%d%H%M)"

function mvar {
    export $2=$(perl -e 'print $ENV{"'$1'"}')
}

mvar dspace.install.dir dspace_install_dir

function help {
    echo "Usage:"
    echo "  $0 all # backup data and dbdata"
    echo "  $0 data # backup data only"
    echo "  $0 dbdata # backup dbdata only"
    exit 255
}

function mak_bak_dir {
    mkdir -p $BAK_TARGET
    chown --reference=$DATA_TARGET $BAK_TARGET
    chown --reference=$DATA_TARGET $BAK_ROOT
}

function data {
    for f in $DATA_VOLUME/*; do
        fb="$(basename $f)"
        fd="$DATA_TARGET/$fb"
        if [ -e "$fd" ]; then
            echo "mv $fd => $BAK_TARGET/$fb"
            mv $fd $BAK_TARGET/$fb
        fi
        echo "cp -r $f => $fd"
        cp -r $f $fd
        chown -R --reference=$DATA_TARGET $fd
    done
}

function dbdata {
    tar=$(echo "$BAK_TARGET/dbdata.tar.gz")
    cd $DBDATA_VOLUME
    tar -czf $tar ./*
    chown --reference=$DATA_TARGET $tar
}

function all {
    data
    dbdata
}

case "$1" in
    all) mak_bak_dir; all; ;;
    data) mak_bak_dir; data; ;;
    dbdata) mak_bak_dir; dbdata; ;;
    *) help ;;
esac

