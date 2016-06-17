#!/bin/bash

# Automatic exit on error
set -e

mv /etc/default/tomcat8 /etc/default/tomcat8.bak
echo "TOMCAT8_USER=root"  >> /etc/default/tomcat8
echo "TOMCAT8_GROUP=root" >> /etc/default/tomcat8

sed -i "s/__dspace_dir_/${DSPACE_INSTALL_PATH/\//\\\/}/g" /tmp/tomcat.conf
a=$(cat /etc/tomcat8/server.xml | grep -n "</Host>"| cut -d : -f 1 )
sed -i "$((a-1))r /tmp/tomcat.conf" /etc/tomcat8/server.xml

