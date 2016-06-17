#!/bin/bash

# variables
source_tgz_path="/tmp/dspace-src.tar.gz"

mkdir -p $DSPACE_SOURCE_PATH
# download dspace source if not provided
if [ -z "$(ls $DSPACE_SOURCE_PATH)" ]; then
  rm -r $DSPACE_SOURCE_PATH
  
  if [ -z "$SRC_TARGZ_URL" ]; then
      wget https://github.com/DSpace/DSpace/releases/download/dspace-5.3/dspace-5.3-src-release.tar.gz -O $source_tgz_path
  else
      wget $SRC_TARGZ_URL -O $source_tgz_path
  fi
  extracted_path=$(dirname $source_tgz_path)/dspace-src
  mkdir -p $extracted_path
  cd $extracted_path
  tar -zxf $source_tgz_path
  mv $extracted_path/* $DSPACE_SOURCE_PATH
fi

