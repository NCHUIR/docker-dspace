#!/bin/bash

# need to install maven3
wget http://ppa.launchpad.net/natecarlson/maven3/ubuntu/pool/main/m/maven3/maven3_3.2.1-0~ppa1_all.deb
dpkg -i  maven3_3.2.1-0~ppa1_all.deb
ln -s /usr/share/maven3/bin/mvn /usr/bin/mvn
rm maven3_3.2.1-0~ppa1_all.deb

