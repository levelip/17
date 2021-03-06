
groupadd www
useradd -s /sbin/nologin -g www www
yum -y install gcc gcc-c++ autoconf automake  zlib zlib-devel openssl openssl-devel pcre-devel
wget -c http://nginx.org/download/nginx-1.9.7.tar.gz
tar zxvf nginx*.tar.gz
cd nginx*
if [ -s mod.tar.gz ]; then
echo "mod.tar.gz [found]"
else
echo "Error: mod.tar.gz not found!!!download now......"

wget -c http://soli-10006287.file.myqcloud.com/mod.tar.gz
fi
tar zxvf mod.tar.gz
if [ -s libressl-2.3.1.tar.gz ]; then
echo "libressl-2.3.1.tar.gz [found]"
else
echo "Error: libressl-2.3.1.tar.gz not found!!!download now......"

wget -c http://ftp.openbsd.org/pub/OpenBSD/LibreSSL/libressl-2.3.1.tar.gz
fi
tar zxvf libressl-2.3.1.tar.gz
./configure --user=www --group=www --prefix=/usr/local/nginx --with-http_stub_status_module --with-http_ssl_module --with-http_gzip_static_module --with-ipv6 --with-google_perftools_module --add-module=nginx-accesskey-2.0.3/ --with-openssl=libressl-2.3.1 --with-ld-opt=-lrt --add-module=nginx-http-footer-filter-1.2.2/ --with-http_realip_module --add-module=ngx_http_substitutions_filter_module-master/ --with-http_sub_module --with-http_v2_module
make
make install
#/usr/sbin/groupadd -f www
#/usr/sbin/useradd -g www www
#/usr/local/nginx/sbin/nginx -c /usr/local/nginx/conf/nginx.conf


rm -rf /etc/init.d/nginx
wget -c http://soft.vpser.net/lnmp/ext/init.d.nginx
cp init.d.nginx /etc/init.d/nginx
chmod +x /etc/init.d/nginx
