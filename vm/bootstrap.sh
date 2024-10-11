#!/usr/bin/env bash

set -ex

apt-get update
apt-get install -y vim tmux htop nano
apt-get install -y python3 python3-pip python3-dev python3-venv
apt-get install -y gcc-14 g++-14
apt-get install -y llvm-18 clang-18
apt-get install -y opam
apt-get install -y libpcre2-dev libpcre3-dev

ln -s /bin/clang-18 /bin/clang
ln -s /bin/clang++-18 /bin/clang++

apt-get install -y git ninja-build cmake

AE_HOME=/home/popl/

git clone https://github.com/AnyDSL/popl25.git ${AE_HOME}/popl25
cd ${AE_HOME}/popl25

cd vm
./setup_venv.sh

source ./env/bin/activate

# make the python environment available to the user by default
echo "source ${AE_HOME}/popl25/vm/env/bin/activate" >> ${AE_HOME}/.bashrc
cd ..


