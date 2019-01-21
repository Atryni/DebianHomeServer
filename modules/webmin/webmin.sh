#!/bin/bash
echo "The script you are running has basename `basename "$0"`, dirname `dirname "$0"`"
echo "The present working directory is `pwd`"

DIR=`dirname "$0"`

wget https://www.webmin.com/download/deb/webmin-current.deb
chmod +x webmin-current.deb
sudo dpkg -i webmin-current.deb
rm webmin-current.deb

sudo cp ${DIR}/webmin.pi.conf /etc/apache2/sites-available/
sudo ln -s /etc/apache2/sites-available/webmin.pi.conf /etc/apache2/sites-enabled/webmin.pi.conf
