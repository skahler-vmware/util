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

cd /home/gpadmin/gpdb_build
rm -rf gp-xerces
git clone https://github.com/greenplum-db/gp-xerces.git
cd gp-xerces
mkdir build
cd build
../configure --prefix=/usr/local/gpdb
make -j8
make install

cd /home/gpadmin/gpdb_build
rm -rf gporca
git clone https://github.com/greenplum-db/gporca.git
cd gporca
mkdir build
cd build
cmake3 -DCMAKE_INSTALL_PREFIX=/usr/local/gpdb ..
make -j8
sudo make install

cd /home/gpadmin/gpdb_build
rm -rf gpdb
git clone https://github.com/greenplum-db/gpdb.git
cd gpdb
./configure --with-perl --with-python --with-libxml --enable-mapreduce --enable-orca --prefix=/usr/local/gpdb CFLAGS="-I/usr/local/gpdb/include/ -L/usr/local/gpdb/lib/"
make -j8
make install

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
