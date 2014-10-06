#!/bin/bash

# Tested on:
#   - Fresh Debian "sid" chroot
#   - Odroid XU

set -e
set -x

# Update library paths
ldconfig

# Verify that cargo and rust are working
cargo -V
rustc -v

# Fetch cargo
apt-get update -qq
apt-get install -qq git
git clone https://github.com/rust-lang/cargo
cd cargo

# Optionally checkout older commit
if [ ! -z $1 ]; then
  git checkout $1
fi

# Get information about HEAD
HEAD_HASH=$(git rev-parse --short HEAD)
HEAD_DATE=$(date -d @$(git show -s --format=%ct HEAD) +'%Y-%m-%d')
TARBALL=cargo-${HEAD_DATE}-${HEAD_HASH}-arm-unknown-linux-gnueabihf

# Cargo build dependencies
apt-get install -qq cmake file libssl-dev pkg-config python wget

# FIXME (upstream must update lockfile) locked dependencies don't build on ARM
rm Cargo.lock

# Build cargo
./configure --enable-nightly --local-cargo=/usr/local/bin/cargo --prefix=/
make
#make test
make distcheck
DESTDIR=/dist make install

# Ship it
cd /dist
tar czf ../${TARBALL}.tar.gz .
cd ..
CARGO_HASH=$(sha1sum ${TARBALL}.tar.gz | cut -f 1 -d ' ')
mv ${TARBALL}.tar.gz ${TARBALL}-${CARGO_HASH}.tar.gz
