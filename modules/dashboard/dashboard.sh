#!/bin/bash
echo "The script you are running has basename `basename "$0"`, dirname `dirname "$0"`"
echo "The present working directory is `pwd`"

DIR=`dirname "$0"`

sudo mkdir /var/www/dashboard.pi
sudo chown pi:pi /var/www/dashboard.pi

git clone https://github.com/BlackrockDigital/startbootstrap-freelancer.git /var/www/dashboard.pi

cp ${DIR}/index.html /var/www/dashboard.pi/
sudo cp ${DIR}/dashboard.pi.conf /etc/apache2/sites-available/
sudo ln -s /etc/apache2/sites-available/dashboard.pi.conf /etc/apache2/sites-enabled/dashboard.pi.conf