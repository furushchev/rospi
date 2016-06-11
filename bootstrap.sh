#!/bin/bash

INSTALL_SCRIPT=/home/pi/install.sh

hostname `cat /etc/hostname`
mv /etc/ld.so.preload /etc/ld.so.preload.bak
chown pi:raspberrypi $INSTALL_SCRIPT
chmod a+x $INSTALL_SCRIPT
su - pi -c "$INSTALL_SCRIPT"
mv /etc/ld.so.preload.bak /etc/ld.so.preload

