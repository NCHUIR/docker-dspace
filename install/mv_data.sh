#!/bin/bash

echo "move dirs to a volume and link back ..."
function mkln {
    dirs=$(echo ${2//,/ })
    mkdir -p $1
    for dir in $dirs; do
        src=$(echo $DSPACE_INSTALL_PATH/$dir)
        des=$(echo $1/$dir)
        if [ -e $src ]; then
            mv $src $des
        else
            mkdir -p $src
        fi
        ln -s $des $src
    done
}
mkln $DBDATA_VOLUME $VOLUME_DBDATA_DIRS
mkln $DATA_VOLUME $VOLUME_DATA_DIRS

