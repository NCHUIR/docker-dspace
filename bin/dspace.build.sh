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
# dspace.build ["mvn_target"] ["ant_target"]
# Ex: 
# rebuild:     dspace.build "-U clean package" "update" or simply dspace.build
# fresh_build: dspace.build "package" "fresh_install"

set -o pipefail
if [ -z "$1" ]; then
    mvn_target="-U clean package"
else
    mvn_target="$1"
fi
if [ -z "$2" ]; then
    ant_target="update"
else
    ant_target="$2"
fi

# helpers
function mvar {
    export $2=$(perl -e 'print $ENV{"'$1'"}')
}

# DATA_VOLUME=/data
mvar dspace.install.dir dspace_dir
mvar dspace.source.dir source_path

log="$DATA_VOLUME/log/build-log/$(date +%Y%m%d%H%M)"
mkdir -p $log

cd $source_path

echo "=========== mvn package ===========" | tee -a $log/mvn.log
eval "mvn $mvn_target | tee -a $log/mvn.log"
if [[ $? -ne 0 ]]; then
	echo "mvn failed!" | tee -a $log/err.log
	exit 1
fi;

cd ${source_path}/dspace/target/dspace-installer/
if [[ $? -ne 0 ]]; then
	echo "cd into ${source_path}/dspace/target/dspace-*-build/ failed!" | tee -a $log/err.log
	exit 1
fi;

echo "=========== ant update ===========" | tee -a $log/ant.log
eval "ant $ant_target | tee -a $log/ant.log"
if [[ $? -ne 0 ]]; then
	echo "ant failed!" | tee -a $log/err.log
	exit 1
fi;

echo "=========== cleaning up ===========" | tee -a $log/cleanup.log
mkdir -p $log/bak $log/config-bak
for k in $(cd $dspace_dir && ls -d *.bak-*);do mv -v $dspace_dir/$k $log/bak/ | tee -a $log/cleanup.log; done;
for k in $(find $dspace_dir/config -name '*.old');do mv -v $k $log/config-bak/ | tee -a $log/cleanup.log; done;
