#!/bin/bash
echo "The script you are running has basename `basename "$0"`, dirname `dirname "$0"`"
echo "The present working directory is `pwd`"

DIR=`dirname "$0"`

curl -s https://packages.gitlab.com/install/repositories/gitlab/raspberry-pi2/script.deb.sh | sudo bash

sudo apt-get install gitlab-ce

sed -i 's/gitlab.example.com/gitlab.pi/g' /etc/gitlab/gitlab.rb
sudo gitlab-ctl reconfigure