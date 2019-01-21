#!/bin/bash
echo "The script you are running has basename `basename "$0"`, dirname `dirname "$0"`"
echo "The present working directory is `pwd`"

DIR=`dirname "$0"`

sudo usermod -a -G www-data pi

sudo a2enmod rewrite proxy proxy_http default-ssl headers env dir mime

sudo rm /etc/apache2/sites-enabled/000-default.conf

sudo service apache2 restart