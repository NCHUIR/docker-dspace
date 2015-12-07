#!/bin/bash
  
  # availible setting
  # POSTGRES_HOST=/var/run/postgres
  # POSTGRES_USER=postgres
  # POSTGRES_PASSWORD=mysecretpassword
  # SRC_TARGZ_URL=
  # db.url=jdbc:postgresql://localhost:5432/dspace
  # db.username=dspace
  # db.password=dspacesecretpassword

  # helpers
  function mvar {
    export $2=$(perl -e 'print $ENV{"'$1'"}')
  }

  # remove the "." Envs
  mvar db.url db_url
  mvar db.username db_username
  mvar db.password db_password

  # variables
  deploy_dir="/deploy"
  source_path="/dspace-src"
  source_tgz_path="/tmp/dspace-src.tar.gz"
  postgresqld_home="/etc/service/postgresqld"
  
  # Database (postgresql) setup
  if [ -z "$POSTGRES_HOST" ]; then
    apt-get update
    apt-get install -y postgresql
    mkdir $postgresqld_home
    cp $deploy_dir/postgresqld.sh $postgresqld_home/run
    chmod +x $postgresqld_home/run

    # fix problem relate to postgresql
    cd /var/lib/postgresql/9.4/main
    cp /etc/ssl/certs/ssl-cert-snakeoil.pem server.crt
    cp /etc/ssl/private/ssl-cert-snakeoil.key server.key
    chown postgres *
    chmod 640 server.crt server.key

    #conf database before build and installation of dspace
    POSTGRESQL_BIN=/usr/lib/postgresql/9.4/bin/postgres
    POSTGRESQL_CONFIG_FILE=/etc/postgresql/9.4/main/postgresql.conf

    mkdir -p /var/run/postgresql/9.4-main.pg_stat_tmp
    chown postgres /var/run/postgresql/9.4-main.pg_stat_tmp
    chgrp postgres /var/run/postgresql/9.4-main.pg_stat_tmp
  
    /sbin/setuser postgres $POSTGRESQL_BIN --single \
            --config-file=$POSTGRESQL_CONFIG_FILE \
          <<< "UPDATE pg_database SET encoding = pg_char_to_encoding('UTF8') WHERE datname = 'template1'" &>/dev/null

    /sbin/setuser postgres $POSTGRESQL_BIN --single \
            --config-file=$POSTGRESQL_CONFIG_FILE \
          <<< "UPDATE pg_database SET encoding = pg_char_to_encoding('UTF8') WHERE datname = 'template1'" &>/dev/null
    echo "local all all md5" >> /etc/postgresql/9.4/main/pg_hba.conf
    /sbin/setuser postgres /usr/lib/postgresql/9.4/bin/postgres -D  /var/lib/postgresql/9.4/main -c config_file=/etc/postgresql/9.4/main/postgresql.conf >>/var/log/postgresd.log 2>&1 &
    sleep 10s

    ##Adding Deamons to containers
    # to add postgresqld deamon to runit
    mkdir /etc/service/postgresqld
    cp $deploy_dir/postgresqld.sh /etc/service/postgresqld/run
    chmod +x /etc/service/postgresqld/run

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
    tar -zxvf $source_tgz_path
    mv $extracted_path/* $source_path
  fi

  # fill up db login parameter for dspace (set env if not provided, or write to the build.properties)
  if [ -z $db_url ]; then
      export db_url=$(grep '^ *db\.url *= *' $source_path/build.properties | sed 's/^ *db\.url *= *//')
  else
      sed -i -E "s/^ *db\\.url *=.*$/db.url=$db_url/" $source_path/build.properties
  fi
  if [ -z $db_username ]; then
      export db_username=$(grep '^ *db\.username *= *' $source_path/build.properties | sed 's/^ *db\.username *= *//')
  else
      sed -i -E "s/^ *db\\.username *=.*$/db.username=$db_username/" $source_path/build.properties
  fi
  if [ -z $db_password ]; then
      export db_password=$(grep '^ *db\.password *= *' $source_path/build.properties | sed 's/^ *db\.password *= *//')
  else
      sed -i -E "s/^ *db\\.password *=.*$/db.password=$db_password/" $source_path/build.properties
  fi

  dbname=$(echo $db_url | sed 's/.*\///')
  dspace_install_dir=$(cat $source_path/build.properties | grep 'dspace\.install\.dir' | sed 's/.*=//')

  $psql -c "CREATE USER $db_username PASSWORD '$db_password';"
  $psql -c "CREATE DATABASE $dbname OWNER $db_username ENCODING 'UNICODE';"

  #conf tomcat7 for dspace
  cp $deploy_dir/dspace_tomcat8.conf /tmp/dspace_tomcat8.conf
  sed -i "s/__dspace_dir_/${dspace_install_dir/\//\\\/}/g" /tmp/dspace_tomcat8.conf
  a=$(cat /etc/tomcat8/server.xml | grep -n "</Host>"| cut -d : -f 1 )
  sed -i "$((a-1))r /tmp/dspace_tomcat8.conf" /etc/tomcat8/server.xml

  # compile the source
  cd $source_path
  mvn package
        
  # build dspace and install
  cd $source_path/dspace/target/dspace-installer
  ant fresh_install
  chown tomcat8:tomcat8 $dspace_install_dir -R
  killall postgres
  sleep 10s

  # TODO
  # Add ./bin to the container

  apt-get clean
  rm -rf /deploy
  rm -rf /tmp/* /var/tmp/*
  rm -rf /var/lib/apt/lists/*
