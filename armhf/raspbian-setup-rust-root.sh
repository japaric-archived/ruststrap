#!/bin/bash

# sets up a raspbian rootfs for rust builds (part I)

#
# run this script in freshly debootstrapped Raspbian rootfs
#
# $ debootstrap --arch=armhf wheezy /chroot/raspbian/rust http://mirrordirector.raspbian.org/raspbian
#
# # systemd-nspawn doesn't work, do a "manual" chroot
# $ mount -o rbind /dev /chroot/raspbian/rust/dev
# $ mount -o bind /sys /chroot/raspbian/rust/sys
# $ mount -t proc none /chroot/raspbian/rust/proc
#
# $ env -i \
#     HOME=/root \
#     PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
#     TERM=$TERM \
#     SHELL=/bin/bash \
#     chroot /chroot/raspbian/rust \
#     /ruststrap/armhf/raspbian-setup-rust.sh
#

set -x
set -e

## install g++
apt-get update -qq
apt-get install -qq build-essential g++-4.7
update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-4.7 50 --slave /usr/bin/g++ g++ /usr/bin/g++-4.7

## install dropbox_uploader.sh
apt-get install -qq curl git
cd ~
git clone https://github.com/andreafabrizi/Dropbox-Uploader
cd /usr/bin
cp /root/Dropbox-Uploader/dropbox_uploader.sh .

## install rust build dependencies
apt-get install -qq ccache file python

## add rustbuild user
useradd -m rustbuild
