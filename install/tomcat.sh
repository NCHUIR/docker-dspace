#!/bin/bash

# Automatic exit on error
set -e

sed -i "s/__dspace_dir_/${DSPACE_INSTALL_PATH/\//\\\/}/g" /tmp/tomcat.conf
a=$(cat /usr/local/tomcat/conf/server.xml | grep -n "</Host>"| cut -d : -f 1 )
sed -i "$((a-1))r /tmp/tomcat.conf" /usr/local/tomcat/conf/server.xml

