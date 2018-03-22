#!/bin/bash

# Install Forward Proxy
#
#
#

sudo apt-get update

sudo apt-get install -y make gcc libpcre3-dev libexpat1-dev

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
./configure --prefix=/usr/local/apache2proxy --enable-module=proxy --with-included-apr --enable-ssl
make
sudo make install

sudo /usr/local/apache2proxy/bin/apachectl stop

/bin/cat <<EOM | sudo tee /usr/local/apache2proxy/conf/httpd.conf
ServerRoot "/usr/local/apache2proxy"
Listen 3128
LoadModule authn_file_module modules/mod_authn_file.so
LoadModule authn_core_module modules/mod_authn_core.so
LoadModule authz_host_module modules/mod_authz_host.so
LoadModule authz_groupfile_module modules/mod_authz_groupfile.so
LoadModule authz_user_module modules/mod_authz_user.so
LoadModule authz_core_module modules/mod_authz_core.so
LoadModule access_compat_module modules/mod_access_compat.so
LoadModule auth_basic_module modules/mod_auth_basic.so
LoadModule reqtimeout_module modules/mod_reqtimeout.so
LoadModule filter_module modules/mod_filter.so
LoadModule mime_module modules/mod_mime.so
LoadModule log_config_module modules/mod_log_config.so
LoadModule env_module modules/mod_env.so
LoadModule headers_module modules/mod_headers.so
LoadModule setenvif_module modules/mod_setenvif.so
LoadModule version_module modules/mod_version.so
LoadModule proxy_module modules/mod_proxy.so
LoadModule proxy_connect_module modules/mod_proxy_connect.so
LoadModule proxy_ftp_module modules/mod_proxy_ftp.so
LoadModule proxy_http_module modules/mod_proxy_http.so
LoadModule proxy_fcgi_module modules/mod_proxy_fcgi.so
LoadModule proxy_scgi_module modules/mod_proxy_scgi.so
LoadModule proxy_fdpass_module modules/mod_proxy_fdpass.so
LoadModule proxy_wstunnel_module modules/mod_proxy_wstunnel.so
LoadModule proxy_ajp_module modules/mod_proxy_ajp.so
LoadModule proxy_balancer_module modules/mod_proxy_balancer.so
LoadModule proxy_express_module modules/mod_proxy_express.so
LoadModule proxy_hcheck_module modules/mod_proxy_hcheck.so
LoadModule unixd_module modules/mod_unixd.so
LoadModule status_module modules/mod_status.so
LoadModule autoindex_module modules/mod_autoindex.so
LoadModule dir_module modules/mod_dir.so
LoadModule alias_module modules/mod_alias.so
LoadModule slotmem_shm_module modules/mod_slotmem_shm.so
LoadModule watchdog_module modules/mod_watchdog.so
LoadModule ssl_module modules/mod_ssl.so

<IfModule unixd_module>
User daemon
Group daemon
</IfModule>
ServerAdmin you@yourdomain.com

ProxyRequests On
SSLProxyEngine On

ErrorLog "logs/error_log"
LogLevel warn
<IfModule log_config_module>
    LogFormat "%h %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-Agent}i\"" combined
    LogFormat "%h %l %u %t \"%r\" %>s %b" common
    <IfModule logio_module>
      LogFormat "%h %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-Agent}i\" %I %O" combinedio
    </IfModule>
    CustomLog "logs/access_log" common
</IfModule>

<IfModule headers_module>
    RequestHeader unset Proxy early
</IfModule>
<IfModule mime_module>
    TypesConfig conf/mime.types
    AddType application/x-compress .Z
    AddType application/x-gzip .gz .tgz
</IfModule>
<IfModule proxy_html_module>
Include conf/extra/proxy-html.conf
</IfModule>
<IfModule ssl_module>
SSLRandomSeed startup builtin
SSLRandomSeed connect builtin
</IfModule>
EOM

sudo /usr/local/apache2proxy/bin/apachectl restart
