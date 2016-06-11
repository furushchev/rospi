#!/bin/bash

set -e
set -x
set -u
set -o pipefail

SUDO=sudo
#SUDO=echo
TARGET=/mnt/pi
RASPBIAN_IMG=raspbian.img

install_dependencies(){
  $SUDO apt-get -qq update
  DEBIAN_FRONTEND=noninteractive $SUDO apt-get install -y -qq aria2 git qemu-user-static qemu-utils kpartx ssh
}

download_raspbian(){
  aria2c https://downloads.raspberrypi.org/raspbian_latest -c -x 5 -o raspbian.zip
  unzip raspbian.zip
  mv `ls | grep .img` raspbian.img
}

expand_diskimage(){
  qemu-img resize raspbian.img +5G
  START_SECTOR=$(fdisk -l raspbian.img | grep raspbian.img2 | awk '{ print $2 }')
  fdisk raspbian.img <<EOF
p
d
2
n
p
2
$START_SECTOR

p
w
EOF
  sudo kpartx -av -p raspbian raspbian.img
  sudo e2fsck -f /dev/mapper/loop*raspbian2
  sudo resize2fs /dev/mapper/loop*raspbian2
  sudo kpartx -d raspbian.img
}

mount_raspbian(){
  $SUDO kpartx -avp raspbian raspbian.img
  $SUDO mkdir -p $TARGET/boot
  $SUDO mount /dev/mapper/loop*raspbian2 $TARGET/
  $SUDO mount /dev/mapper/loop*raspbian1 $TARGET/boot
  for d in dev proc sys dev/pts; do
    $SUDO mkdir -p $TARGET/$d
    $SUDO mount -o bind /$d $TARGET/$d
  done
}

unmount_raspbian(){
  for d in dev proc sys dev/pts boot .; do
    if mountpoint -q $TARGET/$d; then
      $SUDO umount -dfl $TARGET/$d
    fi
  done
  if [ -e /dev/mapper/loop*raspbian1 ]; then
    $SUDO kpartx -d raspbian.img
  fi
}

chroot_raspbian(){
  if [ ! -e $TARGET/usr/bin/qemu-arm-static ]; then
    $SUDO cp $(which qemu-arm-static) $TARGET/usr/bin/qemu-arm-static
  fi
  $SUDO cp bootstrap.sh $TARGET/root/bootstrap.sh
  $SUDO cp install.sh $TARGET/home/pi/install.sh
  $SUDO chroot $TARGET/ qemu-arm-static /bin/bash -c '/root/bootstrap.sh'
}

prescript(){
  install_dependencies
  if [ ! -e $RASPBIAN_IMG ]; then
    download_raspbian
    expand_diskimage
  fi
  mount_raspbian
}

postscript(){
  unmount_raspbian
}

onerror(){
  echo "Error: $1 at line: $2"
  postscript
}

onexit(){
  postscript
}

trap 'onerror $? $LINENO' ERR
trap 'onexit' EXIT

prescript
chroot_raspbian
