#!/bin/bash

set -e
set -x

SNAPSHOT_REV=$1

if [ -z $SNAPSHOT_REV ]; then
    echo Expected hash of the snapshot as first argument
    exit 1
fi

# Rust dependencies
apt-get update
apt-get install -qq curl file git python

# Prepare build folder
mkdir -p $HOME/toolchains/src
cd $HOME/toolchains/src

# Fetch Rust
git clone --recursive https://github.com/rust-lang/rust
cd rust
git checkout $SNAPSHOT_REV

# Configure Rust
mkdir build
cd build
mkdir -p $HOME/toolchains/var/lib
mkdir $HOME/toolchains/etc
../configure \
    --prefix=$HOME/toolchains \
    --enable-local-rust \
    --local-rust-root=$HOME \
    --localstatedir=$HOME/toolchains/var/lib \
    --sysconfdir=$HOME/toolchains/etc

# Build it
make snap-stage3 -j$(nproc)

echo Hooray!
