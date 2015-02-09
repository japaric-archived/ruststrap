#!/bin/bash

# cron job to build cargo nightlies
# set to run daily at 02:00:00 UTC

set -x
set -e

env -i \
  HOME=/root \
  PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
  SHELL=/bin/bash \
  TERM=$TERM \
  chroot /chroot/raspbian/cargo /ruststrap/armhf/build-cargo.sh $1
