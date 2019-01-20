#!/bin/bash
echo "The script you are running has basename `basename "$0"`, dirname `dirname "$0"`"
echo "The present working directory is `pwd`"

DIR=`dirname "$0"`

sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get dist-upgrade -y
