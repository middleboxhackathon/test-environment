#!/bin/sh

#
# This script does the following in the directory it is run in:
#   - Creates the installation directory
#   - Clones all repositories into subdirectories
#   - Configures, builds and installs each repository to the
#     installation directory
#

# MSC - install dependencies, assuming apt (is there a better set?)
sudo apt update
sudo apt install -y build-essential git libev4 autoconf libtool libtool-bin python libpcre3-dev libexpat1-dev

openssl_repo=git://git.openssl.org/openssl.git
openssl_branch_or_tag=OpenSSL_1_1_1a
httpd_repo=git://git.apache.org/httpd.git
httpd_branch_or_tag=2.4.39
apr_repo=git://git.apache.org/apr.git
apr_branch_or_tag=1.7.0
apr_util_repo=git://git.apache.org/apr-util.git
apr_util_branch_or_tag=1.6.1
curl_repo=https://github.com/curl/curl.git
curl_branch_or_tag=curl-7_65_0

top_dir=$(pwd)
install_dir=${top_dir}/tlmsp_install

if [ ! -d ${install_dir} ]; then
    mkdir ${install_dir} 
fi

#
# OpenSSL
#
cd ${top_dir}
git clone ${openssl_repo}
cd openssl
git checkout ${openssl_branch_or_tag}
./config --prefix=${install_dir} --openssldir=${install_dir}/ssl
make
make install_sw

#
# Apached HTTPD
#
cd ${top_dir}
git clone ${httpd_repo}
cd httpd
git checkout ${httpd_branch_or_tag}
cd srclib
git clone ${apr_repo}
cd apr
git checkout ${apr_branch_or_tag}
cd ..
git clone ${apr_util_repo}
cd apr-util
git checkout ${apr_util_branch_or_tag}
cd ${top_dir}/httpd
./buildconf
./configure --with-included-apr --with-ssl=${install_dir} --prefix=${install_dir}
make
make install

#
# Curl
#
cd ${top_dir}
git clone ${curl_repo}
cd curl
git checkout ${curl_branch_or_tag}
./buildconf
./configure --with-ssl=${install_dir} --prefix=${install_dir}
make
make install

# MSC fix runtime linking errors (possibly a better way?)
sudo echo "/home/user/tlmsp_install/lib" > tlmsp.conf
sudo mv tlmsp.conf /etc/ld.so.conf.d/
sudo ldconfigsudo 
