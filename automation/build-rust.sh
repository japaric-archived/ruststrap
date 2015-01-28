#!/bin/bash

set -x
set -e

: ${DIST_DIR:=~/dist}
: ${SNAP_DIR:=~/snap}
: ${SRC_DIR:=~/rust}
: ${DROPBOX:=dropbox_uploader.sh}

# setup snapshot
cd $SNAP_DIR
rm -rf *
LAST_SNAP=`$DROPBOX list snapshots | grep -v stage0 | tail -n 1 | cut -d ' ' -f 4`
$DROPBOX -p download snapshots/$LAST_SNAP
tar xzf $LAST_SNAP

# Update source to upstream
cd $SRC_DIR
git checkout master
git pull

# Optionally checkout older hash
git checkout $1

# Get information about HEAD
HEAD_HASH=$(git rev-parse --short HEAD)
HEAD_DATE=$(date -d @$(git show -s --format=%ct HEAD) +'%Y-%m-%d')
TARBALL=rust-${HEAD_DATE}-${HEAD_HASH}-arm-unknown-linux-gnueabihf

# build it
cd build
../configure \
  --enable-local-rust \
  --local-rust-root=$SNAP_DIR \
  --build=arm-unknown-linux-gnueabihf \
  --host=arm-unknown-linux-gnueabihf \
  --target=arm-unknown-linux-gnueabihf
make clean
make -j$(nproc)

# packgae
rm -rf $DIST_DIR/*
DESTDIR=$DIST_DIR make install -j$(nproc)
cd $DIST_DIR/usr/local
tar czf $DIST_DIR/$TARBALL .
cd $DIST_DIR
TARBALL_HASH=$(sha1sum $TARBALL | cut -d ' ' -f 1)
mv $TARBALL $TARBALL-$TARBALL_HASH.tar.gz

# ship it
$DROPBOX -p upload $TARBALL-$TARBALL_HASH.tar.gz .
