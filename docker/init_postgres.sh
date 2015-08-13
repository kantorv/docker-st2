#!/bin/bash

#postgress
mkdir -p /data/main
chmod 700 /data/main

cp /etc/postgresql/9.3/main/postgresql.conf /data/postgresql.conf
cp /etc/postgresql/9.3/main/pg_hba.conf /data/pg_hba.conf
sed -i '/^data_directory*/ s|/var/lib/postgresql/9.3/main|/data/main|' /data/postgresql.conf
sed -i '/^hba_file*/ s|/etc/postgresql/9.3/main/pg_hba.conf|/data/pg_hba.conf|' /data/postgresql.conf
sed -i 's/max_connections = 100/max_connections = 500/'  /data/postgresql.conf

chown postgres /data/*
chgrp postgres /data/*

su postgres --command "/usr/lib/postgresql/9.3/bin/initdb -D /data/main"
supervisorctl start postgres

setup_mistral_db()
{
  cd /var/lib/postgresql 	
  echo "Setting up Mistral DB in PostgreSQL..."
  sudo -u postgres psql -c "DROP DATABASE IF EXISTS mistral;"
  sudo -u postgres psql -c "DROP USER IF EXISTS mistral;"
  sudo -u postgres psql -c "CREATE USER mistral WITH ENCRYPTED PASSWORD 'StackStorm';"
  sudo -u postgres psql -c "CREATE DATABASE mistral OWNER mistral;"

  #echo "Creating and populating DB tables for Mistral..."
  #config=/etc/mistral/mistral.conf
  #cd /opt/openstack/mistral
  #/opt/openstack/mistral/.venv/bin/python ./tools/sync_db.py --config-file ${config}
}


setup_mistral_db