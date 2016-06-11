#!/bin/bash

set -e
set -x
set -o pipefail

sudo apt-get update -q
sudo apt-get install -qq -y wget git

sudo sh -c 'echo "deb http://packages.ros.org/ros/ubuntu jessie main" > /etc/apt/sources.list.d/ros-latest.list'
wget https://raw.githubusercontent.com/ros/rosdistro/master/ros.key -O - | sudo apt-key add -
sudo apt-get update -q
sudo apt-get install -qq -y python-pip python-setuptools python-distribute python-catkin-tools python-rosdep python-rosinstall-generator python-wstool
sudo rosdep init
rosdep update

# install collada-dom
install_collada_dom(){
  sudo apt-get install -qq -y checkinstall cmake
  sudo sh -c 'echo "deb-src http://mirrordirector.raspbian.org/raspbian/ testing main contrib non-free rpi" >> /etc/apt/sources.list'
  sudo apt-get update -qq
  sudo apt-get install -qq -y libboost-filesystem-dev libxml2-dev
  cd /tmp
  wget http://downloads.sourceforge.net/project/collada-dom/Collada%20DOM/Collada%20DOM%202.4/collada-dom-2.4.0.tgz -O collada-dom-2.4.0.tgz
  tar -zxf collada-dom-2.4.0.tgz
  cd collada-dom-2.4.0
  cmake .
  sudo checkinstall make install -j <<EOF
y

2
collada-dom-dev
EOF
}

# install ros desktop
mkdir -p /home/pi/ros/indigo_base/src
cd /home/pi/ros/indigo_base/src
rosinstall_generator desktop --rosdistro indigo --deps --wet-only --exclude roslisp --tar > .rosinstall
wstool up -j3 -m 300
while [ $? != 0 ]; do
  wstool up -j3 -m 300
done
cd ..
rosdep install --from-paths src --ignore-src --rosdistro indigo -y -r --os=debian:jessie
catkin init
catkin config --install -i /opt/ros/indigo
sudo catkin build --limit-status-rate 0.017 --summarize
exit 0
