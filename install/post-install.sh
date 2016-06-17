#!/bin/bash

# Get env
export $(cat $ENV_FILE_PATH);

echo "set PGPASSWORD env for psql ..."
echo "PGPASSWORD=$POSTGRES_PASSWORD" >> $ENV_FILE_PATH
# More info: https://www.postgresql.org/docs/current/static/libpq-envars.html

echo "let interactive shell (bash) has env ..."
echo 'export $(cat $ENV_FILE_PATH)' >> ~/.bashrc

echo "shell scripts as command ..."
for f in /tmp/bin/*; do 
  fd=$(basename $f)
  fd=${fd%.sh}
  mv $f /usr/bin/$fd
  chmod u+x /usr/bin/$fd
done

echo "shim for dspace bins ..."
for f in $DSPACE_INSTALL_PATH/bin/*; do
  fd="/usr/bin/$(basename $f)"
  echo "#!/bin/sh" >> $fd
  echo "cd $DSPACE_INSTALL_PATH/bin" >> $fd
  echo "$f "'$@' >> $fd
  chmod +x $fd
done

