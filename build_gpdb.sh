#!/bin/sh
set -e
set -x

yum -y install gcc gcc-c++ git wget ncurses-devel bzip2 bison flex openssl-devel libcurl-devel readline-devel bzip2-devel libyaml libyaml-devel libevent-devel openldap-devel libxml2-devel libxslt-devel apr-devel libffi-devel libxml2-devel python-devel perl-ExtUtils-Embed

rpm -ivh http://dl.fedoraproject.org/pub/epel/6/i386/epel-release-6-8.noarch.rpm
yum -y install python-pip cmake3
pip install --upgrade psutil
pip install --upgrade lockfile
pip install --upgrade paramiko
pip install --upgrade setuptools
pip install --upgrade epydoc
pip install --upgrade pyyaml

mkdir /data
mkdir /root/gpdb_build
chmod 777 /root/gpdb_build/

cat >> /etc/sysctl.conf <<EOF
kernel.shmmax = 500000000
kernel.shmmni = 4096
kernel.shmall = 4000000000
kernel.sem = 250 512000 100 2048
kernel.sysrq = 1
kernel.core_uses_pid = 1
kernel.msgmnb = 65536
kernel.msgmax = 65536
kernel.msgmni = 2048
net.ipv4.tcp_syncookies = 1
net.ipv4.ip_forward = 0
net.ipv4.conf.default.accept_source_route = 0
net.ipv4.tcp_tw_recycle = 1
net.ipv4.tcp_max_syn_backlog = 4096
net.ipv4.conf.all.arp_filter = 1
net.ipv4.ip_local_port_range = 1025 65535
net.core.netdev_max_backlog = 10000
net.core.rmem_max = 2097152
net.core.wmem_max = 2097152
EOF

cat > /etc/security/limits.d/90-nproc.conf <<EOF
* soft nofile 65536
* hard nofile 65536
* soft nproc 131072
* hard nproc 131072
EOF

cd /root/gpdb_build
rm -rf gp-xerces
git clone https://github.com/greenplum-db/gp-xerces.git
cd gp-xerces
mkdir build
cd build
../configure --prefix=/usr/local/gpdb
make -j8
make install

cd /root/gpdb_build
rm -rf gporca
git clone https://github.com/greenplum-db/gporca.git
cd gporca
mkdir build
cd build
cmake3 -DCMAKE_INSTALL_PREFIX=/usr/local/gpdb ..
make -j8
sudo make install

cd /root/gpdb_build
rm -rf gpdb
git clone https://github.com/greenplum-db/gpdb.git
cd gpdb
./configure --with-perl --with-python --with-libxml --enable-mapreduce --enable-orca --prefix=/usr/local/gpdb CFLAGS="-I/usr/local/gpdb/include/ -L/usr/local/gpdb/lib/"
make -j8
make install

useradd -m -r gpadmin -d /home/gpadmin
chown -R gpadmin /usr/local/gpdb
chown -R gpadmin /data/
