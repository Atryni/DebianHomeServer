#!/bin/bash
echo "The script you are running has basename `basename "$0"`, dirname `dirname "$0"`"
echo "The present working directory is `pwd`"

DIR=`dirname "$0"`


#https://getgrav.org/blog/raspberrypi-nginx-php7-dev
sudo apt-get install -y apache2 mariadb-server libapache2-mod-php \
    openssl php-imagick php-common php-curl php-gd \
    php-imap php-intl php-json php-ldap php-mbstring \
    php-mysql php-pgsql php-smbclient php-ssh2 \
    php-sqlite3 php-xml php-zip