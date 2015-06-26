#!/bin/bash

# cron job to build rust snapshots
# set to run every four hours starting at 01:00:00 UTC

set -x
set -e

# build snapshot (if necessary)
env -i \
  HOME=/root \
  PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
  SHELL=/bin/bash \
  TERM=$TERM \
  chroot /chroot/raspbian/snap \
  su -c /ruststrap/armhf/build-snap.sh rustbuild
