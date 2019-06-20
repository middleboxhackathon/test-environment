#!/bin/bash
sudo apt-get update; sudo apt-get install -y git autoconf clang gettext libpcre2-dev libtool libev-dev pkg-config
git clone https://forge.etsi.org/gitlab/cyber/tlmsp-openssl.git openssl
git clone https://forge.etsi.org/gitlab/cyber/tlmsp-tools.git
mkdir -p ~/install
cd tlmsp-tools/build
./initial-build.sh ~/install
