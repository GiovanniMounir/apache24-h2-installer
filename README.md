# Introduction
This is a BASH script developed for CentOS 7 to minimize the time spent on compiling Apache 2.4 with HTTP2 and SSL support.
# What does it do?
1. Downloads the necessary packages for Apache 2.4.34 with HTTP2 support (optionally including Google's brotli) under /tmp/_sources
2. Compiles the downloaded packages and installs them
3. Logs are stored under /tmp/_sources/[package_name]/log. For example, you can find logs while compiling apr under /tmp/_sources/apr-1.6.3/log
4. Installs Apache 2.4.34 into /usr/local/apache2 
5. Loads the SSL (optional) and HTTP2 module by modifying the Apache configuration file and optionally adds a VirtualHost entry with SSL.
6. Creates an "httpd" service which can be used with "service httpd start/stop" 

###### Packages Included
- OpenSSL 1.1.0h
- apr 1.6.3
- apr-util 1.6.1
- nghttp2 1.32.0
- brotli v1.0 (optional)

# How to run?
Execute the following in your terminal to run installer.sh (URL shortened): `bash <(curl -s -L https://git.io/fNXVq)`
# License
This work is available under the GNU GPLv3 license.
# Support
For suggestions or bug reports, please feel free to [open a new issue](https://github.com/GiovanniMounir/apache24-h2-installer/issues/new)

If you would like to modify the script so it supports more distributions/offers more enhancements, please feel free to create a pull request and I will merge it.

Notes: this script assumes that the HTML directory is /var/www/html - this can be modified later from /usr/local/apache2/conf/httpd.conf
