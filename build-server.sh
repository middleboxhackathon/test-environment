#!/bin/bash

# Install Server

# Add repo for letsencrypt
sudo add-apt-repository -y ppa:certbot/certbot

sudo apt-get update

sudo apt-get install -y make gcc libpcre3-dev libexpat1-dev openssl libssl-dev certbot

# Apache
wget http://www.mirrorservice.org/sites/ftp.apache.org//httpd/httpd-2.4.29.tar.gz
tar zxvf httpd-2.4.29.tar.gz

# APR
wget http://apache.mirror.anlx.net//apr/apr-1.6.3.tar.gz
mkdir httpd-2.4.29/srclib/apr
tar -xvzf apr-1.6.3.tar.gz --strip 1 -C httpd-2.4.29/srclib/apr/

# APR Util
wget http://apache.mirror.anlx.net//apr/apr-util-1.6.1.tar.gz
mkdir httpd-2.4.29/srclib/apr-util
tar -xvzf apr-util-1.6.1.tar.gz --strip 1 -C httpd-2.4.29/srclib/apr-util/

cd httpd-2.4.29
./configure --prefix=/usr/local/apache2 --with-included-apr --enable-ssl
make
sudo make install

sudo /usr/local/apache2/bin/apachectl -k restart

sudo certbot certonly --register-unsafely-without-email --agree-tos --webroot -w /usr/local/apache2/htdocs/ -d $1
# Certificate chain ends up somewhere like: /etc/letsencrypt/live/domain.com/fullchain.pem
# Private key is somewhere like:            /etc/letsencrypt/live/domain.com/privkey.pem

/bin/cat <<EOM | sudo tee /etc/letsencrypt/options-ssl-apache.conf
SSLEngine on
SSLProtocol             all -SSLv2 -SSLv3
SSLCipherSuite          ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA:ECDHE-RSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-RSA-AES256-SHA256:DHE-RSA-AES256-SHA:ECDHE-ECDSA-DES-CBC3-SHA:ECDHE-RSA-DES-CBC3-SHA:EDH-RSA-DES-CBC3-SHA:AES128-GCM-SHA256:AES256-GCM-SHA384:AES128-SHA256:AES256-SHA256:AES128-SHA:AES256-SHA:DES-CBC3-SHA:!DSS
SSLHonorCipherOrder     on
SSLCompression          off
SSLOptions +StrictRequire
LogFormat "%h %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-agent}i\"" vhost_combined
LogFormat "%v %h %l %u %t \"%r\" %>s %b" vhost_common
EOM

/bin/cat <<EOM | sudo tee /usr/local/apache2/conf/extra/ssl.conf
<IfModule mod_ssl.c>
Listen 443
<VirtualHost *:443>
        ServerAdmin webmaster@localhost
        DocumentRoot /usr/local/apache2/htdocs
        ServerName $1
        Include /etc/letsencrypt/options-ssl-apache.conf
        SSLCertificateFile /etc/letsencrypt/live/$1/fullchain.pem
        SSLCertificateKeyFile /etc/letsencrypt/live/$1/privkey.pem
        Include /etc/letsencrypt/options-ssl-apache.conf
</VirtualHost>
</IfModule>
EOM

sudo sed -i '/#Include conf\/extra\/httpd-ssl.conf/c\Include conf\/extra\/ssl.conf' /usr/local/apache2/conf/httpd.conf
sudo sed -i '/#LoadModule\ ssl_module\ modules\/mod_ssl.so/c\LoadModule\ ssl_module\ modules\/mod_ssl.so' /usr/local/apache2/conf/httpd.conf

sudo /usr/local/apache2/bin/apachectl -k restart
