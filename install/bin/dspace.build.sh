#!/bin/bash

########################################
# dspace.build
########################################
# this will Full Build/Refresh/Rebuild DSpace
# more info please visit: https://wiki.duraspace.org/display/DSDOC3x/Rebuild+DSpace
# This assume that you use a symlink to the webapp

#######################################
# Usage
#######################################
# dspace.build <mvn_target> <ant_target>
# Ex: 
# rebuild:     dspace.build "-U clean package" "update"
# fresh_build: dspace.build "package" "fresh_install"
# mvn only:    dspace.build "package"
# ant only?:   dspace.build "" "update"

set -o pipefail
mvn_target="$1"
ant_target="$2"

log="$DATA_VOLUME/log/build-log/$(date +%Y%m%d%H%M)"
mkdir -p $log

if [ "$mvn_target" ]; then
  echo "=========== mvn package ===========" | tee -a $log/mvn.log
  cd $DSPACE_SOURCE_PATH
  eval "mvn $mvn_target | tee -a $log/mvn.log"
  if [[ $? -ne 0 ]]; then
    echo "mvn failed!" | tee -a $log/err.log
    exit 1
  fi
fi

if [ "$ant_target" ]; then
  cd "$DSPACE_SOURCE_PATH/dspace/target/dspace-installer/"
  if [[ $? -ne 0 ]]; then
    echo "cd into $DSPACE_SOURCE_PATH/dspace/target/dspace-installer/ failed!" | tee -a $log/err.log
    exit 1
  fi;

  if [ -f "$BUILD_MORE_TARGETS_PATH" ]; then
    if ! [ "$(cat build.xml | grep BUILD_MORE_TARGETS_ADDED )" ]; then
      echo ">>> add more targets to build.xml"
      sed -i "/<project.*>/r $BUILD_MORE_TARGETS_PATH" build.xml
      sed -i '/<project.*>/i <!-- BUILD_MORE_TARGETS_ADDED -->' build.xml
    fi
  fi

  echo "=========== ant update ===========" | tee -a $log/ant.log
  eval "ant $ant_target | tee -a $log/ant.log"
  if [[ $? -ne 0 ]]; then
    echo "ant failed!" | tee -a $log/err.log
    exit 1
  fi

  echo "=========== cleaning up ===========" | tee -a $log/cleanup.log
  mkdir -p $log/bak $log/config-bak
  for k in $(cd $DSPACE_INSTALL_PATH && ls -d *.bak-*);do mv -v $DSPACE_INSTALL_PATH/$k $log/bak/ | tee -a $log/cleanup.log; done;
  for k in $(find $DSPACE_INSTALL_PATH/config -name '*.old');do mv -v $k $log/config-bak/ | tee -a $log/cleanup.log; done;
fi

