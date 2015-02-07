#!/bin/bash

# sets up a raspbian build chroot

#
# run this script in freshly debootstrapped Raspbian rootfs
#
# $ debootstrap --arch=armhf wheezy /chroot/raspbian/cargo http://mirrordirector.raspbian.org/raspbian
# # systemd-nspawn doesn't work, do a "manual" chroot
# $ mount -o rbind /dev /chroot/raspbian/cargo/dev
# $ mount -o bind /sys /chroot/raspbian/cargo/sys
# $ mount -t proc none /chroot/raspbian/cargo/proc
# $ cd /chroot/raspbian/cargo/root
# $ wget https://raw.githubusercontent.com/japaric/ruststrap/master/armhf/raspbian-setup-cargo.sh
# $ chmod +x raspbian-setup-cargo.sh
# $ env -i \
#     HOME=/root \
#     PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
#     TERM=$TERM \
#     SHELL=/bin/bash \
#     chroot /chroot/raspbian/cargo /ruststrap/armhf/raspbian-setup-cargo.sh
#

set -x
set -e

: ${DIST_DIR:=~/dist}
: ${NIGHTLY_DIR:=~/nightly}
: ${SRC_DIR:=~/src}

## install g++
apt-get update -qq
apt-get install -qq build-essential g++-4.7
update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-4.7 50 --slave /usr/bin/g++ g++ /usr/bin/g++-4.7

## install dropbox_uploader.sh
apt-get install -qq curl git
cd ~
git clone https://github.com/andreafabrizi/Dropbox-Uploader
cd /usr/bin
ln -s /root/Dropbox-Uploader/dropbox_uploader.sh .
dropbox_uploader.sh

## fetch cargo source
git clone --recursive https://github.com/rust-lang/cargo $SRC_DIR
apt-get install -qq cmake file libssl-dev pkg-config python

## prepare snap and dist folders
mkdir -p $DIST_DIR
mkdir -p $NIGHTLY_DIR/{cargo,rust}
