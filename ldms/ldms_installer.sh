#!/bin/bash

set -e  

echo ">>> Installing Dependencies..."

yum install automake -y
yum install openssl-devel -y
yum install pkg-config -y
yum install libtool -y
yum install python3 -y
yum install python3-devel.x86_64 -y
yum install python3-Cython -y
yum install make -y
yum install bison -y
yum install flex -y
dnf install -y openssl
dnf install -y openssl-devel
dnf install -y swig
dnf install -y libtool
dnf install -y readline
dnf install -y readline-devel
dnf install -y libevent
dnf install -y libevent-devel
dnf install -y glib2
dnf install -y glib2-devel
dnf install -y git
dnf install -y bison
dnf install -y make
dnf install -y byacc
dnf install -y flex 
dnf install -y python3-docutils 
dnf install -y jansson-devel


mkdir $HOME/Source
mkdir $HOME/ovis
cd $HOME/Source
git clone -b v4.4.5 https://github.com/ovis-hpc/ovis.git ovis-445
cd $HOME/Source/ovis-445
./autogen.sh

# Building the Source
mkdir build
cd build
../configure --prefix=/opt/ovis
make
make install