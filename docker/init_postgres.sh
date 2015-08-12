#!/bin/bash

#postgress
mkdir -p /data/main
chmod 700 /data/main

cp /etc/postgresql/9.3/main/postgresql.conf /data/postgresql.conf
cp /etc/postgresql/9.3/main/pg_hba.conf /data/pg_hba.conf
sed -i '/^data_directory*/ s|/var/lib/postgresql/9.3/main|/data/main|' /data/postgresql.conf
sed -i '/^hba_file*/ s|/etc/postgresql/9.3/main/pg_hba.conf|/data/pg_hba.conf|' /data/postgresql.conf

chown postgres /data/*
chgrp postgres /data/*

su postgres --command "/usr/lib/postgresql/9.3/bin/initdb -D /data/main"
supervisorctl start postgres

