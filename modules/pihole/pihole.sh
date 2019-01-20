#!/bin/bash
echo "The script you are running has basename `basename "$0"`, dirname `dirname "$0"`"
echo "The present working directory is `pwd`"

DIR=`dirname "$0"`

sudo mkdir /var/www/pihole.rpi
sudo chown pi:pi /var/www/pihole.rpi

sudo cp ${DIR}/pihole.rpi.conf /etc/apache2/sites-available/
sudo ln -s /etc/apache2/sites-available/pihole.rpi.conf /etc/apache2/sites-enabled/pihole.rpi.conf
