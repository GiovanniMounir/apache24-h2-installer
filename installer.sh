#!/bin/bash
if [[ ! $(cat /etc/*-release | grep "CentOS Linux 7") ]]; then
    echo "This script only supports CentOS Linux 7 distributions."
	exit
fi
if [[ "$EUID" -ne 0 ]]; then
    echo "This script might install additional packages that are necessary for the compilation of Apache with HTTP2. Please re-run as root."
    exit
fi
if [ -f /etc/httpd/conf/httpd.conf ]
then
    read -p "You seem to have Apache already installed.
	
It is recommended that you remove the Apache package then re-run this script to prevent conflicts.
Would you still like to continue? (not recommended) [Y/N]: " -n 1 -r
	echo 
	if [[ $REPLY =~ ^[Nn]$ ]]
	then
		echo "Aborting based on user's request."
		exit
	fi

fi
if [ -f /usr/local/apache2/conf/httpd.conf ]
then
    read -p "You seem to have Apache 2 installed inside /usr/local/apache2. Proceeding might overwrite these files. Would you still like to proceed (not recommended) [Y/N]: " -n 1 -r
	echo 
	if [[ $REPLY =~ ^[Nn]$ ]]
	then
		echo "Aborting based on user's request."
		exit
	fi

fi
if [ -d "/tmp/_sources" ]; then 
  read -p "/tmp/_sources already exists. This directory is generated when you run this script for the first time, so it could be a left over if you ran this  script earlier.
	
Would you like to remove it and continue? Answering 'N' will continue without removing the contents of the directory (not recommended) [Y/N]: " -n 1 -r
	echo 
	if [[ $REPLY =~ ^[Nn]$ ]]
	then
		rm -r -f /tmp/_sources
	fi

fi
_brotli=false
read -p "Brotli is a generic-purpose lossless compression algorithm that compresses data using a combination of a modern variant of the LZ77 algorithm, Huffman coding and 2nd order context modeling, with a compression ratio comparable to the best currently available general-purpose compression methods.

Would you like to install brotli? This is not necessary for HTTP2 but recommended for performance improvements [Y/N]: " -n 1 -r
echo 
if [[ $REPLY =~ ^[Yy]$ ]]
then
    _brotli=true
fi
echo "Preparing to install packages.. this step might take a while depending on your internet speed."
yum -y install epel-release
yum -y install wget perl zlib-devel gcc gcc-c++ pcre-devel libxml2-devel openssl-devel expat-devel cmake git automake autoconf libtool python libcurl curl jansson jansson-devel libcurl-devel python-devel
echo 
echo 
function die() {
  echo "$1"
  echo "Please check the log file at `pwd`/log"
  exit 1 #error
}
function certfile()
{
	read -p "Please enter the path to your SSL certificate file (.cer/.crt): " _crtfile
	if [ ! -f $_crtfile ]; then
		echo "- File does not exist."
		certfile
	fi
}
function keyfile()
{
	read -p "Please enter the path to your SSL key file (.key): " _keyfile
	if [ ! -f $_keyfile ]; then
		echo "- File does not exist."
		keyfile
	fi
}
mkdir /tmp/_sources
cd /tmp/_sources
echo "- Working directory is now /tmp/_sources"
echo "1. Downloading OpenSSL 1.1.0h..."
wget https://www.openssl.org/source/openssl-1.1.0h.tar.gz
echo "1.1 Extracting OpenSSL 1.1.0h..."
tar xf openssl-1.1.0h.tar.gz
cd openssl-1.1.0h
echo "- Working directory is now /tmp/_sources/openssl-1.1.0h"
echo "1.2 Preparing OpenSSL 1.1.0h for compilation..."
./config shared zlib-dynamic --prefix=/usr/local/ssl >> log || die "OpenSSL configuration failed."
echo "1.3 Compiling OpenSSL 1.1.0h..."
make  >> log || die "OpenSSL compilation failed."
echo "1.4 Installing OpenSSL 1.1.0h..."
make install >> log || die "OpenSSL installation failed."
cd /tmp/_sources
echo "- Working directory is now /tmp/_sources"
if [ -d "/usr/local/lib64/python2.7/site-packages/" ]; then 
  export PYTHONPATH="/usr/local/lib64/python2.7/site-packages/"
else
  export PYTHONPATH="/usr/lib64/python2.7/site-packages/"
fi
echo "2. Downloading nghttp2 1.32.0"
wget https://github.com/nghttp2/nghttp2/releases/download/v1.32.0/nghttp2-1.32.0.tar.gz
echo "2.1 Extracting nghttp2 1.32.0..."
tar xf nghttp2-1.32.0.tar.gz
cd nghttp2-1.32.0
echo "- Working directory is now /tmp/_sources/nghttp2-1.32.0"
echo "2.2 Preparing nghttp2 1.32.0 for compilation..."
./configure >> log || die "nghttp2 configuration failed."
echo "2.3 Compiling nghttp2 1.32.0..."
make >> log || die "nghttp2 compilation failed."
echo "2.4 Installing nghttp2 1.32.0..."
make install >> log || die "nghttp2 installation failed."
cd /tmp/_sources
echo "- Working directory is now /tmp/_sources"
echo "3. Downloading APR 1.6.3..."
wget http://www-us.apache.org/dist//apr/apr-1.6.3.tar.gz
echo "3.1 Extracting APR 1.6.3..."
tar xf apr-1.6.3.tar.gz
cd apr-1.6.3
echo "- Working directory is now /tmp/_sources/apr-1.6.3"
echo "3.2 Preparing APR 1.6.3 for compilation..."
./configure >> /log | die "APR 1.6.3 configuration failed."
echo "3.3 Compiling APR 1.6.3..."
make >> log || die "APR 1.6.3 compilation failed."
echo "3.4 Installing APR 1.6.3..."
make install >> log || die "APR 1.6.3 installation failed."
cd /tmp/_sources
echo "- Working directory is now /tmp/_sources"
echo "4. Downloading apr-util 1.6.1..."
wget http://mirrors.whoishostingthis.com/apache/apr/apr-util-1.6.1.tar.gz
echo "4.1 Extracting apr-util 1.6.1..."
tar xf apr-util-1.6.1.tar.gz
cd apr-util-1.6.1
echo "- Working directory is now /tmp/_sources/apr-util-1.6.1"
echo "4.2 Preparing apr-util 1.6.1 for compilation..."
./configure --with-apr=/usr/local/apr >> log || die "apr-util configuration failed."
echo "4.3 Compiling apr-util 1.6.1..."
make >> log || die "apr-util compilation failed."
echo "4.4 Installing apr-util 1.6.1..."
make install >> log || die "apr-util installation failed."
cd /tmp/_sources
echo "- Working directory is now /tmp/_sources"

if [[ $_brotli ]]
then
	echo "You have selected to install brotli. Cloning the brotli repository.."
    git clone https://github.com/google/brotli.git
	cd brotli/
	echo "- Working directory is now /tmp/_sources/brotli"
	git checkout v1.0
	mkdir out && cd out
	echo "- Working directory is now /tmp/_sources/brotli/out"
	echo "- Preparing for compilation"
	../configure-cmake >> log || die "brotli configuration failed."
	echo "- Compiling.."
	make >> log || die "brotli compilation failed."
	make test >> log
	echo "- Installing.."
	make install >> log || die "brotli installation failed."
fi

cd /tmp/_sources
echo "- Working directory is now /tmp/_sources"

echo "Downloading Apache 2.4.34.."
wget https://www.apache.org/dist/httpd/httpd-2.4.34.tar.gz
echo "Extracting Apache 2.4.34..."
tar xf httpd-2.4.34.tar.gz
cd httpd-2.4.34
echo "- Working directory is now /tmp/_sources/httpd-2.4.34"
echo "Copying APR into srclib/apr"
cp -r ../apr-1.6.3 srclib/apr
echo "Copying apr-util into srclib/apr-util"
cp -r ../apr-util-1.6.1 srclib/apr-util
if [[ $_brotli ]]
then
./configure --with-ssl=/usr/local/ssl --with-pcre=/usr/bin/pcre-config --enable-unique-id --enable-ssl --enable-so --with-included-apr --enable-http2 --enable-brotli --with-brotli=/usr/local/brotli >> log || die "Apache configuration failed."
else
./configure --with-ssl=/usr/local/ssl --with-pcre=/usr/bin/pcre-config --enable-unique-id --enable-ssl --enable-so --with-included-apr --enable-http2 >> log || die "Apache configuration failed."
fi
echo "Compiling Apache 2.4.34.."
make >> log || die "Apache compilation failed."
echo "Installing Apache 2.4.34.."
make install >> log || die "Apache installation failed."

echo "Finalizing.."
sudo groupadd www
sudo useradd httpd -g www --no-create-home --shell /sbin/nologin
echo "User httpd" >> /usr/local/apache2/conf/httpd.conf
echo "Group www" >> /usr/local/apache2/conf/httpd.conf
mkdir /var/www
mkdir /var/www/html
sed -i -e 's/\/usr\/local\/apache2\/htdocs/\/var\/www\/html/g' /usr/local/apache2/conf/httpd.conf

echo "LoadModule http2_module modules/mod_http2.so" >> /usr/local/apache2/conf/httpd.conf
echo "Protocols h2 h2c http/1.1" >> /usr/local/apache2/conf/httpd.conf
cat > /etc/systemd/system/httpd.service <<EOF
[Unit]
Description=The Apache HTTP Server
After=network.target

[Service]
Type=forking
ExecStart=/usr/local/apache2/bin/apachectl -k start
ExecReload=/usr/local/apache2/bin/apachectl -k graceful
ExecStop=/usr/local/apache2/bin/apachectl -k graceful-stop
PIDFile=/usr/local/apache2/logs/httpd.pid
PrivateTmp=true

[Install]
WantedBy=multi-user.target

EOF
 read -p "Some browsers, such as Google Chrome and Mozilla Firefox, support HTTP2 only if served over SSL/TLS. Would you like to enable SSL? (recommended) [Y/N]: " -n 1 -r
	echo 
	if [[ $REPLY =~ ^[Yy]$ ]]
	then
		echo "LoadModule ssl_module modules/mod_ssl.so" >> /usr/local/apache2/conf/httpd.conf
		echo "Listen 443" >> /usr/local/apache2/conf/httpd.conf
		read -p "Do you have your own SSL certificate? [Y/N]: " -n 1 -r
		echo 
		if [[ $REPLY =~ ^[Yy]$ ]]; then
		certfile
		keyfile
		
		else
		echo "Generating self-signed certificate and key pair inside /usr/local/apache2/ssl/.."
		mkdir /usr/local/apache2/ssl
		mkdir /usr/local/apache2/ssl/private
		mkdir /usr/local/apache2/ssl/certs
		
		sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /usr/local/apache2/ssl/private/apache-selfsigned.key -out /usr/local/apache2/ssl/certs/apache-selfsigned.crt
		_crtfile=/usr/local/apache2/ssl/certs/apache-selfsigned.crt
		_keyfile=/usr/local/apache2/ssl/private/apache-selfsigned.key
		fi
		read -p "Please enter the domain/common name: " _domain
				cat >> /usr/local/apache2/conf/httpd.conf <<EOF
<VirtualHost *:443>
    ServerName $_domain
    DocumentRoot /var/www/html
    SSLEngine on
    SSLCertificateFile $_crtfile
    SSLCertificateKeyFile $_keyfile
</VirtualHost>
EOF
	fi


systemctl daemon-reload
systemctl enable httpd

echo "Congratulations! If all went well, you should have your new Apache 2.4.34 installed inside /usr/local/apache2. Please run 'service httpd start' to start the Apache HTTP server."
