#!/bin/bash

# sets up a raspbian rootfs for rust builds (part II)

#
# run this script in a raspbian-2015-05-05 rootfs
#
# $ env -i \
#     HOME=/root \
#     PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
#     TERM=$TERM \
#     SHELL=/bin/bash \
#     chroot /chroot/raspbian/rust \
#     su -c /ruststrap/armhf/raspbian-setup-rust.sh rustbuild
#

: ${DIST_DIR:=~/dist}
: ${SNAP_DIR:=~/snap}
: ${SRC_DIR:=~/src}

## setup dropbox_uploader.sh
dropbox_uploader.sh

## fetch rust source
git clone --recursive https://github.com/rust-lang/rust $SRC_DIR
cd $SRC_DIR
mkdir build
cd build
# sanity check
../configure  --enable-ccache

## prepare snap and dist folders
mkdir -p $DIST_DIR
mkdir -p $SNAP_DIR
