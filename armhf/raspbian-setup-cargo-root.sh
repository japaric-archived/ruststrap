#!/bin/bash

# sets up a raspbian rootfs for cargo builds (part I)

#
# run this script in a raspbian-2015-05-05 rootfs
#
# # systemd-nspawn doesn't work, do a "manual" chroot
# $ mount -o rbind /dev /chroot/raspbian/cargo/dev
# $ mount -o bind /sys /chroot/raspbian/cargo/sys
# $ mount -t proc none /chroot/raspbian/cargo/proc
#
# $ env -i \
#     HOME=/root \
#     PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
#     TERM=$TERM \
#     SHELL=/bin/bash \
#     chroot /chroot/raspbian/cargo \
#     /ruststrap/armhf/raspbian-setup-cargo-root.sh
#

set -x
set -e

## install g++
apt-get update -qq
apt-get install -qq build-essential g++-4.8
update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-4.8 50 --slave /usr/bin/g++ g++ /usr/bin/g++-4.8

## install dropbox_uploader.sh
apt-get install -qq curl git
cd ~
git clone https://github.com/andreafabrizi/Dropbox-Uploader
cd /usr/bin
cp /root/Dropbox-Uploader/dropbox_uploader.sh .

## install cargo build dependencies
apt-get install -qq cmake file libssl-dev pkg-config python

## add rustbuild user
useradd -m rustbuild
