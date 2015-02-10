#!/bin/bash

# sets up a raspbian rootfs for cargo builds (part II)

#
# $ env -i \
#     HOME=/root \
#     PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
#     TERM=$TERM \
#     SHELL=/bin/bash \
#     chroot /chroot/raspbian/cargo \
#     su -c /ruststrap/armhf/raspbian-setup-cargo.sh rustbuild
#

set -x
set -e

: ${DIST_DIR:=~/dist}
: ${NIGHTLY_DIR:=~/nightly}
: ${SRC_DIR:=~/src}

## setup dropbox_uploader.sh
dropbox_uploader.sh

## fetch cargo source
git clone --recursive https://github.com/rust-lang/cargo $SRC_DIR

## prepare snap and dist folders
mkdir -p $DIST_DIR
mkdir -p $NIGHTLY_DIR/{cargo,rust}
