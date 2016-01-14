#!/bin/bash

  # Automatic exit on error
  set -e
  
  # availible setting
  # POSTGRES_HOST=/var/run/postgres
  # POSTGRES_USER=postgres
  # POSTGRES_PASSWORD=mysecretpassword
  # SRC_TARGZ_URL=
  # db.url=jdbc:postgresql://localhost:5432/dspace
  # db.username=dspace
  # db.password=dspacesecretpassword
  # dspace.install.dir=/dspace
  # dspace.source.dir=/dspace-src

  # helpers
  function mvar {
    export $2=$(perl -e 'print $ENV{"'$1'"}')
  }

  # remove the "." Envs
  mvar db.url db_url
  mvar db.username db_username
  mvar db.password db_password
  mvar dspace.install.dir dspace_install_dir
  mvar dspace.source.dir source_path

  # variables
  deploy_dir="/deploy"
  source_tgz_path="/tmp/dspace-src.tar.gz"
  postgresqld_home="/etc/service/postgresqld"
  DATA_VOLUME=/data
  DBDATA_VOLUME=/dbdata
  
  # Database (postgresql) setup
  if [ -z "$POSTGRES_HOST" ]; then
    apt-get update
    apt-get install -y postgresql
    mkdir $postgresqld_home

    # fix problem relate to postgresql
    cd /var/lib/postgresql/*/main
    cp /etc/ssl/certs/ssl-cert-snakeoil.pem server.crt
    cp /etc/ssl/private/ssl-cert-snakeoil.key server.key
    chown postgres *
    chmod 640 server.crt server.key

    #conf database before build and installation of dspace
    POSTGRESQL_BIN=$(echo /usr/lib/postgresql/*/bin/postgres)
    POSTGRESQL_CONFIG_FILE=$(echo /etc/postgresql/*/main/postgresql.conf)
    POSTGRESQL_VERSION=$($POSTGRESQL_BIN -V | egrep -o '[0-9]{1,}\.[0-9]{1,}')

    mkdir -p /var/run/postgresql/${POSTGRESQL_VERSION}-main.pg_stat_tmp
    chown postgres /var/run/postgresql/${POSTGRESQL_VERSION}-main.pg_stat_tmp
    chgrp postgres /var/run/postgresql/${POSTGRESQL_VERSION}-main.pg_stat_tmp
  
    /sbin/setuser postgres $POSTGRESQL_BIN --single \
            --config-file=$POSTGRESQL_CONFIG_FILE \
          <<< "UPDATE pg_database SET encoding = pg_char_to_encoding('UTF8') WHERE datname = 'template1'"

    /sbin/setuser postgres $POSTGRESQL_BIN --single \
            --config-file=$POSTGRESQL_CONFIG_FILE \
          <<< "UPDATE pg_database SET encoding = pg_char_to_encoding('UTF8') WHERE datname = 'template1'"
    echo "local all all md5" >> /etc/postgresql/*/main/pg_hba.conf

    # start postgresql server
    /sbin/setuser postgres $POSTGRESQL_BIN -D $ -c config_file=$POSTGRESQL_CONFIG_FILE >>/var/log/postgresd.log 2>&1 &
    sleep 10s

    ##Adding Deamons to containers
    # to add postgresqld deamon to runit
    cp $deploy_dir/bin/postgresqld.sh $postgresqld_home/run
    chmod +x $postgresqld_home/run

    psql="/sbin/setuser postgres psql -w"
  else
    psql="psql -w"
    export PGHOST="$POSTGRES_HOST"
    export PGUSER="$POSTGRES_USER"
    echo "*:*:*:$POSTGRES_USER:$POSTGRES_PASSWORD" > ~/.pgpass
  fi

  # need to install maven3
  wget http://ppa.launchpad.net/natecarlson/maven3/ubuntu/pool/main/m/maven3/maven3_3.2.1-0~ppa1_all.deb
  dpkg -i  maven3_3.2.1-0~ppa1_all.deb
  ln -s /usr/share/maven3/bin/mvn /usr/bin/mvn
  rm maven3_3.2.1-0~ppa1_all.deb

  mv /etc/default/tomcat8 /etc/default/tomcat8.bak
  echo "TOMCAT8_USER=root"  >> /etc/default/tomcat8
  echo "TOMCAT8_GROUP=root" >> /etc/default/tomcat8
  
  # download dspace source if not provided
  if ! [ -d $source_path ]; then
    if [ -z "$SRC_TARGZ_URL" ]; then
        wget https://github.com/DSpace/DSpace/releases/download/dspace-5.3/dspace-5.3-src-release.tar.gz -O $source_tgz_path
    else
        wget $SRC_TARGZ_URL -O $source_tgz_path
    fi
    extracted_path=$(dirname $source_tgz_path)/dspace-src
    mkdir -p $extracted_path
    cd $extracted_path
    tar -zxf $source_tgz_path
    mv $extracted_path/* $source_path
  fi

  # fill up db login parameter for dspace (set env if not provided, or write to the build.properties)
  if [ -z $db_url ]; then
      export db_url=$(grep '^ *db\.url *= *' $source_path/build.properties | sed 's/^ *db\.url *= *//')
  else
      sed -i -E "s/^ *db\\.url *=.*$/db.url=$(echo $db_url | sed 's/\//\\\//g')/" $source_path/build.properties
  fi
  if [ -z $db_username ]; then
      export db_username=$(grep '^ *db\.username *= *' $source_path/build.properties | sed 's/^ *db\.username *= *//')
  else
      sed -i -E "s/^ *db\\.username *=.*$/db.username=$(echo $db_username | sed 's/\//\\\//g')/" $source_path/build.properties
  fi
  if [ -z $db_password ]; then
      export db_password=$(grep '^ *db\.password *= *' $source_path/build.properties | sed 's/^ *db\.password *= *//')
  else
      sed -i -E "s/^ *db\\.password *=.*$/db.password=$(echo $db_password | sed 's/\//\\\//g')/" $source_path/build.properties
  fi
  if [ -z $dspace_install_dir ]; then
      export dspace_install_dir=$(grep '^ *dspace\.install\.dir *= *' $source_path/build.properties | sed 's/^ *dspace\.install\.dir *= *//')
  else
      sed -i -E "s/^ *dspace\\.install\\.dir *=.*$/dspace.install.dir=$(echo $dspace_install_dir | sed 's/\//\\\//g')/" $source_path/build.properties
  fi

  dbname=$(echo $db_url | sed 's/.*\///')

  $psql -c "CREATE USER $db_username PASSWORD '$db_password';"
  $psql -c "CREATE DATABASE $dbname OWNER $db_username ENCODING 'UNICODE';"

  #conf tomcat for dspace
  cp $deploy_dir/conf/tomcat.conf /tmp/tomcat.conf
  sed -i "s/__dspace_dir_/${dspace_install_dir/\//\\\/}/g" /tmp/tomcat.conf
  a=$(cat /etc/tomcat8/server.xml | grep -n "</Host>"| cut -d : -f 1 )
  sed -i "$((a-1))r /tmp/tomcat.conf" /etc/tomcat8/server.xml

  # Add ./bin to the container
  for f in $deploy_dir/bin/*; do
      fd=$(basename $f)
      fd=${fd%.sh}
      cp $f /usr/bin/$fd
      chmod u+x /usr/bin/$fd
  done
  
  # compile the source and install dspace
  dspace.build "package" "fresh_install"
  
  for f in $dspace_install_dir/bin/*; do
      fd=$(basename $f)
      fd=${fd%.sh}
      ln -s $f /usr/bin/$fd
  done
  
  killall postgres
  sleep 10s

  mkdir -p $DBDATA_VOLUME
  POSTGRESQL_DATA=/var/lib/postgresql
  if [ -d $POSTGRESQL_DATA ]; then
      mv $POSTGRESQL_DATA $DBDATA_VOLUME/postgres
      ln -s $DBDATA_VOLUME/postgres $POSTGRESQL_DATA
  fi
  mv $dspace_install_dir/assetstore $DBDATA_VOLUME/assetstore
  ln -s $DBDATA_VOLUME/assetstore $dspace_install_dir/assetstore
  mv $dspace_install_dir/solr $DBDATA_VOLUME/solr
  ln -s $DBDATA_VOLUME/solr $dspace_install_dir/solr
  
  mkdir -p $DATA_VOLUME
  mv $dspace_install_dir/log $DATA_VOLUME/log
  ln -s $DATA_VOLUME/log $dspace_install_dir/log
  mv $dspace_install_dir/webapps $DATA_VOLUME/webapps
  ln -s $DATA_VOLUME/webapps $dspace_install_dir/webapps
  mv $dspace_install_dir/config $DATA_VOLUME/config
  ln -s $DATA_VOLUME/config $dspace_install_dir/config

  apt-get clean
  if ! [ -z $dont_rm_src ]; then
    rm -rf $source_path
  fi
  rm -rf /deploy
  rm -rf /tmp/* /var/tmp/*
  rm -rf /var/lib/apt/lists/*
