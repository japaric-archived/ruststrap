#!/bin/bash

# cron job to update the readme
# set to run daily at 02:00:00 UTC

set -x
set -e

env -i \
  HOME=/root \
  PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
  SHELL=/bin/bash \
  TERM=$TERM \
  chroot /chroot/wheezy/snap \
  su -c /ruststrap/armhf/update-docs.sh rustbuild
