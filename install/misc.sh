#!/bin/bash

mkdir -p $DSPACE_SOURCE_PATH
mkdir -p $DSPACE_INSTALL_PATH
mkdir -p $DBDATA_VOLUME
mkdir -p $DATA_VOLUME

sed 's/#.*//g' /tmp/env.conf | sed "/^$/d" >> $ENV_FILE_PATH

