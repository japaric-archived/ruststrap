#!/bin/bash

# Cross boostraps an arm-unknown-linux-gnueabihf rust compiler

# Based on the blog post "Cross bootstrapping Rust" by Riad Wahby
# (http://github.jfet.org/Rust_cross_bootstrapping.html)

# Tested on a freshly `debootstrap`ed Ubuntu 14.04 chroot
# Last successful build: rustc 0.12.0-pre (4d69696ff 2014-09-24 20:35:52 +0000)
# Produced compiler successfully tested on: Odroid-XU

set -e
set -x

# ARM cross-compiler
apt-get update
apt-get install -qq g++-arm-linux-gnueabihf

# Rust dependencies
apt-get install -qq curl file git python

# Prepare build folder
mkdir -p $HOME/toolchains/src
cd $HOME/toolchains/src

# Fetch Rust
git clone --recursive https://github.com/rust-lang/rust
cd rust

# Configure Rust
mkdir build
cd build
mkdir -p $HOME/toolchains/var/lib
mkdir $HOME/toolchains/etc
../configure \
    --prefix=$HOME/toolchains \
    --build=x86_64-unknown-linux-gnu \
    --host=x86_64-unknown-linux-gnu \
    --disable-llvm-assertions \
    --target=x86_64-unknown-linux-gnu,arm-unknown-linux-gnueabihf \
    --localstatedir=$HOME/toolchains/var/lib \
    --sysconfdir=$HOME/toolchains/etc
cd x86_64-unknown-linux-gnu
find . -type d -exec mkdir -p ../arm-unknown-linux-gnueabihf/\{\} \;

# Building cross LLVM
cd $HOME/toolchains/src/rust/build/x86_64-unknown-linux-gnu/llvm
$HOME/toolchains/src/rust/src/llvm/configure \
    --enable-target=x86_64,arm \
    --enable-optimized \
    --disable-assertions \
    --disable-docs \
    --enable-bindings=none \
    --disable-terminfo \
    --disable-zlib \
    --disable-libffi \
    --with-python=/usr/bin/python2.7
make -j$(nproc)
cd $HOME/toolchains/src/rust/build/arm-unknown-linux-gnueabihf/llvm
$HOME/toolchains/src/rust/src/llvm/configure \
    --enable-target=arm \
    --enable-optimized \
    --disable-assertions \
    --disable-docs \
    --enable-bindings=none \
    --disable-terminfo \
    --disable-zlib \
    --disable-libffi \
    --with-python=/usr/bin/python2.7 \
    --build=x86_64-unknown-linux-gnu \
    --host=arm-linux-gnueabihf \
    --target=arm-linux-gnueabihf
make -j$(nproc)

# Enable llvm-config for the cross build
cd $HOME/toolchains/src/rust/build/arm-unknown-linux-gnueabihf/llvm/Release/bin
mv llvm-config llvm-config-arm
ln -s ../../BuildTools/Release/bin/llvm-config
./llvm-config --cxxflags

# Making Rust Build System use our LLVM build
cd $HOME/toolchains/src/rust/build/
chmod 0644 config.mk
grep 'CFG_LLVM_[BI]' config.mk |                                          \
    sed 's/x86_64\(.\)unknown.linux.gnu/arm\1unknown\1linux\1gnueabihf/g' \
    >> config.mk

cd $HOME/toolchains/src/rust
sed -i.bak 's/\([\t]*\)\(.*\$(MAKE).*\)/\1#\2/' mk/llvm.mk

# Building a working librustc for the cross architecture
cd $HOME/toolchains/src/rust
sed -i.bak \
    's/^CRATES := .*/TARGET_CRATES += $(HOST_CRATES)\nCRATES := $(TARGET_CRATES)/' \
    mk/crates.mk
sed -i.bak \
    's/\(.*call DEF_LLVM_VARS.*\)/\1\n$(eval $(call DEF_LLVM_VARS,arm-unknown-linux-gnueabihf))/' \
    mk/main.mk
sed -i.bak 's/foreach host,$(CFG_HOST)/foreach host,$(CFG_TARGET)/' mk/rustllvm.mk

cd $HOME/toolchains/src/rust
sed -i.bak 's/.*target_arch = .*//' src/etc/mklldeps.py

cd $HOME/toolchains/src/rust/build
arm-unknown-linux-gnueabihf/llvm/Release/bin/llvm-config --libs \
    | tr '-' '\n' | sort > arm
x86_64-unknown-linux-gnu/llvm/Release/bin/llvm-config --libs \
    | tr '-' '\n' | sort > x86
diff arm x86 >/dev/null

# Build it, part 1
cd $HOME/toolchains/src/rust/build
make -j$(nproc)

# Build it, part 2
cd $HOME/toolchains/src/rust/build
LD_LIBRARY_PATH=$PWD/x86_64-unknown-linux-gnu/stage2/lib/rustlib/x86_64-unknown-linux-gnu/lib:$LD_LIBRARY_PATH \
    ./x86_64-unknown-linux-gnu/stage2/bin/rustc --cfg stage2 -O --cfg rtopt                                    \
    -C linker=arm-linux-gnueabihf-g++ -C ar=arm-linux-gnueabihf-ar -C target-feature=+v6,+vfp2                 \
    --cfg debug -C prefer-dynamic --target=arm-unknown-linux-gnueabihf                                         \
    -o x86_64-unknown-linux-gnu/stage2/lib/rustlib/arm-unknown-linux-gnueabihf/bin/rustc --cfg rustc           \
    $PWD/../src/driver/driver.rs
LD_LIBRARY_PATH=$PWD/x86_64-unknown-linux-gnu/stage2/lib/rustlib/x86_64-unknown-linux-gnu/lib:$LD_LIBRARY_PATH \
    ./x86_64-unknown-linux-gnu/stage2/bin/rustc --cfg stage2 -O --cfg rtopt                                    \
    -C linker=arm-linux-gnueabihf-g++ -C ar=arm-linux-gnueabihf-ar -C target-feature=+v6,+vfp2                 \
    --cfg debug -C prefer-dynamic --target=arm-unknown-linux-gnueabihf                                         \
    -o x86_64-unknown-linux-gnu/stage2/lib/rustlib/arm-unknown-linux-gnueabihf/bin/rustdoc --cfg rustdoc       \
    $PWD/../src/driver/driver.rs

# Ship it!
cd $HOME/toolchains/src/rust/build/
mkdir -p cross-dist/lib/rustlib/arm-unknown-linux-gnueabihf
cd cross-dist
cp -R ../x86_64-unknown-linux-gnu/stage2/lib/rustlib/arm-unknown-linux-gnueabihf/* \
    lib/rustlib/arm-unknown-linux-gnueabihf
mv lib/rustlib/arm-unknown-linux-gnueabihf/bin .
cd lib
for i in rustlib/arm-unknown-linux-gnueabihf/lib/*.so; do ln -s $i .; done
cd ../
tar cjf ../rust_arm-unknown-linux-gnueabihf_dist.tbz2 .

echo Hooray!
