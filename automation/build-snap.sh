#!/bin/bash

set -x
set -e

: ${SNAP_DIR:=~/snap}
: ${SRC_DIR:=~/rust}
: ${DROPBOX:=dropbox_uploader.sh}

# setup snapshot
cd $SNAP_DIR
rm -rf *
LAST_SNAP=`$DROPBOX list snapshots | tail -n 1 | cut -d ' ' -f 4`
$DROPBOX download snapshots/$LAST_SNAP
tar xzf $LAST_SNAP

# Update source to upstream
cd $SRC_DIR
git checkout master
git pull

SNAP_HASH=$(head src/snapshots.txt | head -n 1 | cut -d ' ' -f 3)

# Optionally checkout older hash
git checkout $SNAP_HASH

# build it
cd build
../configure \
  --disable-inject-std-version \
  --enable-llvm-static-stdcpp \
  --enable-local-rust \
  --local-rust-root=$SNAP_DIR \
  --build=arm-unknown-linux-gnueabihf \
  --host=arm-unknown-linux-gnueabihf \
  --target=arm-unknown-linux-gnueabihf
make clean
make -j$(nproc)
make snap-stage3-H-arm-unknown-linux-gnueabihf

# ship it
$DROPBOX upload rust-stage0-* snapshots
rm rust-stage0-*
