#!/bin/sh
set -e
set -x

ssh-keygen -f $HOME/.ssh/id_rsa -t rsa -N ''
cp ~/.ssh/id_rsa.pub ~/.ssh/authorized_keys

ssh -oStrictHostKeyChecking=no localhost 'uptime'
ssh -oStrictHostKeyChecking=no localhost.localdomain 'uptime'
ssh -oStrictHostKeyChecking=no `hostname` 'uptime'

mkdir /home/gpadmin/gpdb_build
chmod 777 /home/gpadmin/gpdb_build/

cat > gpinitsystem_singlenode <<EOF
ARRAY_NAME="GPDB SINGLENODE"
MACHINE_LIST_FILE=./hostlist
SEG_PREFIX=gpsne
PORT_BASE=40000
declare -a DATA_DIRECTORY=(/data/segments /data/segments)
MASTER_HOSTNAME=localhost
MASTER_DIRECTORY=/data/master
MASTER_PORT=5432
TRUSTED_SHELL=ssh
CHECK_POINT_SEGMENTS=8
ENCODING=UNICODE
DATABASE_NAME=gpadmin
EOF

cat > hostlist <<EOF
localhost
EOF

mkdir /data/master
mkdir /data/segments

source /usr/local/gpdb/greenplum_path.sh
gpinitsystem -a -c gpinitsystem_singlenode
