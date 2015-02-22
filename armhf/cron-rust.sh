#!/bin/bash

# cron job to build rust nightlies
# set to run daily at 03:00:00 UTC

set -x
set -e

# build rust nightly
env -i \
  HOME=/root \
  PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
  SHELL=/bin/bash \
  TERM=$TERM \
  chroot /chroot/raspbian/rust \
  su -c "/ruststrap/armhf/build-rust.sh $1" rustbuild
