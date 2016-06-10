FROM ubuntu:trusty
MAINTAINER Yuki Furuta

RUN locale-gen en_US.UTF-8
RUN update-locale LANG=en_US.UTF-8

RUN apt-get -qq update && DEBIAN_FRONTEND=noninteractive apt-get install -y -qq aria2 git sudo qemu-user-static kpartx

# download raspbian os image
# RUN wget https://downloads.raspberrypi.org/raspbian_latest -O raspbian.zip
# RUN unzip raspbian.zip
# RUN export RASPBIAN_IMG=`ls | grep .img`
ADD raspbian.img /root/raspbian.img

# mount raspberry pi file system
RUN kpartx -av -p raspbian raspbian.img
RUN mkdir -p /mnt/pi/boot
RUN mount /dev/loop1raspbian2 /mnt/pi/
RUN mount /dev/loop1raspbian1 /mnt/pi/boot
RUN for d in dev proc sys dev/pts; do mount -o bind /$d /mnt/pi/$d; done
#RUN egrep "rootfs|boot" /etc/mtab | sed 's@/mnt/pi//g' > /mnt/pi/etc/fstab

# change root into raspberry pi image
RUN chroot /mnt/pi/

RUN uname -a
RUN apt-get update
