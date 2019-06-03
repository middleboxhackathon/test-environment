#!/bin/bash
echo "Build server script v0.1e"

# OpenSSL dependencies
sudo apt-get install -y make gcc

# Go get the source
git clone https://forge.etsi.org/gitlab/cyber/MSP-OpenSSL

# Build and install it
cd MSP-OpenSSL
./config
make
sudo make install

cd evaluation/client_server
make all

cd ../demonstration
make client

if [ "$1" != "local" ]
then
    # For Azure builds, put this somewhere less obscure
    cd ../
    mkdir /opt/middlebox-test-environment
    cp -R * /opt/middlebox-test-environment
    chown -R azureuser:azureuser /opt/middlebox-test-environment/*
    chmod -R +rw /opt/middlebox-test-environment/*
fi
