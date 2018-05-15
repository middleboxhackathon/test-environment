#!/bin/bash

# OpenSSL dependencies
sudo apt-get install -y make gcc

# Clone Repos
git clone https://forge.etsi.org/gerrit/CYBER.MSP-OpenSSL

cd ~/CYBER.MSP-OpenSSL
./config
make
sudo make install
