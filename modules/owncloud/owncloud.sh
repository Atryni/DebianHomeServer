#!/bin/bash
echo "The script you are running has basename `basename "$0"`, dirname `dirname "$0"`"
echo "The present working directory is `pwd`"

DIR=`dirname "$0"`

sudo cp ${DIR}/owncloud.pi.conf /etc/apache2/sites-available/
sudo ln -s /etc/apache2/sites-available/owncloud.pi.conf /etc/apache2/sites-enabled/owncloud.pi.conf
sudo service apache2 restart

sudo apt-get install -y \
    apache2 mariadb-server libapache2-mod-php \
    openssl php-imagick php-common php-curl php-gd \
    php-imap php-intl php-json php-ldap php-mbstring \
    php-mysql php-pgsql php-smbclient php-ssh2 \
    php-sqlite3 php-xml php-zip

sudo wget -nv https://download.owncloud.org/download/repositories/production/Debian_9.0/Release.key -O Release.key
sudo apt-key add - < Release.key
sudo echo 'deb http://download.owncloud.org/download/repositories/production/Debian_9.0/ /' | sudo tee /etc/apt/sources.list.d/owncloud.list
sudo apt-get update
sudo apt-get install owncloud-files