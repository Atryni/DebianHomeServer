#!/bin/bash
echo "The script you are running has basename `basename "$0"`, dirname `dirname "$0"`"
echo "The present working directory is `pwd`"

DIR=`dirname "$0"`

curl -sSL https://install.pi-hole.net | bash

sudo cp ${DIR}/pihole.pi.conf /etc/apache2/sites-available/
sudo ln -s /var/www/html/admin /var/www/pihole.pi
sudo ln -s /etc/apache2/sites-available/pihole.pi.conf /etc/apache2/sites-enabled/pihole.pi.conf
sudo service apache2 restart