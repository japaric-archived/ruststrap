#!/bin/bash

# I run this in Raspbian chroot with the following command:
#
# $ env -i \
#     HOME=/root \
#     PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
#     SHELL=/bin/bash \
#     TERM=$TERM chroot \
#     /chroot/raspbian /ruststrap/armhf/build-cargo.sh

set -x
set -e

: ${DIST_DIR:=~/dist}
: ${DROPBOX:=dropbox_uploader.sh}
: ${MAX_NUMBER_OF_NIGHTLIES:=7}
: ${NIGHTLY_DIR:=~/nightly}
: ${SRC_DIR:=~/src}

CARGO_DIST_DIR=$DIST_DIR/cargo
CARGO_NIGHTLY_DIR=$NIGHTLY_DIR/cargo
CARGO_SRC_DIR=$SRC_DIR/cargo
RUST_NIGHTLY_DIR=$NIGHTLY_DIR/rust

# update source to match upstream
cd $CARGO_SRC_DIR
git checkout .
git checkout master
git pull

# optionally checkout older commit
git checkout $1

# apply patch to link statically against libssl
git apply /ruststrap/armhf/static-ssl.patch

# Get information about HEAD
HEAD_HASH=$(git rev-parse --short HEAD)
HEAD_DATE=$(TZ=UTC date -d @$(git show -s --format=%ct HEAD) +'%Y-%m-%d')
TARBALL=cargo-$HEAD_DATE-$HEAD_HASH-arm-unknown-linux-gnueabihf
LOGFILE=cargo-$HEAD_DATE-$HEAD_HASH.test.output.txt

# XXX It's possible that cargo won't build with the latest cargo nightly, so
# I should try all the available nightlies. However, I haven't seen that
# happen in practice yet, so I'll just try the latest cargo nightly for now
# install cargo nightly
cd $CARGO_NIGHTLY_DIR
rm -rf *
CARGO_NIGHTLY=$($DROPBOX list . | grep cargo- | tail -n 1 | tr -s ' ' | cut -d ' ' -f 4)
$DROPBOX -p download $CARGO_NIGHTLY
tar xzf $CARGO_NIGHTLY
rm $CARGO_NIGHTLY

export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$RUST_NIGHTLY_DIR/lib:$CARGO_NIGHTLY_DIR/lib

# cargo doesn't always build with my latest rust nightly, so try all the
# nightlies available.
# FIXME the right way to do this would use the date in the src/rustversion.txt
# file
for RUST_NIGHTLY in $($DROPBOX list . | grep rust- | tr -s ' ' | cut -d ' ' -f 4 | sort -r); do
  ## install nigthly rust
  cd $RUST_NIGHTLY_DIR
  rm -rf *
  $DROPBOX -p download $RUST_NIGHTLY
  tar xzf $RUST_NIGHTLY
  rm $RUST_NIGHTLY

  ## test rust and cargo nightlies
  $RUST_NIGHTLY_DIR/bin/rustc -V
  PATH=$PATH:$RUST_NIGHTLY_DIR/bin $CARGO_NIGHTLY_DIR/bin/cargo -V

  ## build it, if compilation fails try the next nightly
  cd $CARGO_SRC_DIR
  ./configure \
    --disable-verify-install \
    --enable-nightly \
    --enable-optimize \
    --local-cargo=$CARGO_NIGHTLY_DIR/bin/cargo \
    --local-rust-root=$RUST_NIGHTLY_DIR \
    --prefix=/
  make clean
  make || continue

  ## packgae
  rm -rf $CARGO_DIST_DIR/*
  DESTDIR=$CARGO_DIST_DIR make install
  cd $CARGO_DIST_DIR
  # smoke test the produced cargo nightly
  PATH=$PATH:$RUST_NIGHTLY_DIR/bin LD_LIBRARY_PATH=$LD_LIBRARY_PATH:lib bin/cargo -V
  tar czf $DIST_DIR/$TARBALL .
  cd $DIST_DIR
  TARBALL_HASH=$(sha1sum $TARBALL | tr -s ' ' | cut -d ' ' -f 1)
  mv $TARBALL $TARBALL-$TARBALL_HASH.tar.gz
  TARBALL=$TARBALL-$TARBALL_HASH.tar.gz

  # ship it
  $DROPBOX -p upload $TARBALL .
  rm $TARBALL

  # delete older nightlies
  NUMBER_OF_NIGHTLIES=$($DROPBOX list . | grep cargo- | wc -l)
  for i in $(seq `expr $MAX_NUMBER_OF_NIGHTLIES + 1` $NUMBER_OF_NIGHTLIES); do
    OLDEST_NIGHTLY=$($DROPBOX list . | grep rust- | head -n 1 | tr -s ' ' | cut -d ' ' -f 4)
    $DROPBOX delete $OLDEST_NIGHTLY
  done

  # run tests
  if [ -z $DONTTEST ]; then
    cd $CARGO_SRC_DIR
    uname -a > $LOGFILE
    $RUST_NIGHTLY_DIR/bin/rustc -V >> $LOGFILE
    echo >> $LOGFILE
    make test >>$LOGFILE 2>&1
    $DROPBOX -p upload $LOGFILE .
    rm $LOGFILE
  fi

  # cleanup
  cd $CARGO_NIGHTLY_DIR
  rm -rf *
  cd $RUST_NIGHTLY_DIR
  rm -rf *
  cd $CARGO_DIST_DIR
  rm -rf *

  exit 0
done
