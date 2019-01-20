#!/bin/bash
echo "The script you are running has basename `basename "$0"`, dirname `dirname "$0"`"
echo "The present working directory is `pwd`"

DIR=`dirname "$0"`

sudo mkdir /var/www/dashboard.rpi
sudo chown pi:pi /var/www/dashboard.rpi

git clone https://github.com/BlackrockDigital/startbootstrap-freelancer.git /var/www/dashboard.rpi

cp ${DIR}/index.html /var/www/dashboard.rpi/
sudo cp ${DIR}/dashboard.rpi.conf /etc/apache2/sites-available/
sudo ln -s /etc/apache2/sites-available/dashboard.rpi.conf /etc/apache2/sites-enabled/dashboard.rpi.conf
sudo rm /var/www/html -Rf
sudo ln -s /var/www/dashboard.rpi /var/www/html
