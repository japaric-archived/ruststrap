#!/bin/bash

# Cross boostraps an arm-unknown-linux-gnueabihf rust compiler

# Based on the blog post "Cross bootstrapping Rust" by Riad Wahby
# (http://github.jfet.org/Rust_cross_bootstrapping.html)

# Tested on Ubuntu 14.04 chroot

set -e
set -x

: ${SRC_DIR:=/rust}

# Make sure timezone is UTC (just like bors)
ln -sf /usr/share/zoneinfo/UTC /etc/localtime

# Fetch Rust (or update existing repository)
apt-get update -qq
apt-get install -qq git
git clone --recursive https://github.com/rust-lang/rust "$SRC_DIR" && cd "$SRC_DIR" || \
  cd "$SRC_DIR" && git pull

# Optionally checkout older commit
if [ ! -z $1  ]; then
  git checkout $1
fi

# Get information about HEAD
HEAD_HASH=$(git rev-parse --short HEAD)
HEAD_DATE=$(date -d @$(git show -s --format=%ct HEAD) +'%Y-%m-%d')
TARBALL=rust-${HEAD_DATE}-${HEAD_HASH}-arm-unknown-linux-gnueabihf

# Install ARM cross-compiler
apt-get install -qq g++-arm-linux-gnueabihf

# Install Rust build dependencies
apt-get install -qq curl file python

# Configure Rust
mkdir build
cd build
../configure \
    --build=x86_64-unknown-linux-gnu \
    --host=x86_64-unknown-linux-gnu \
    --target=x86_64-unknown-linux-gnu,arm-unknown-linux-gnueabihf
cd x86_64-unknown-linux-gnu
find . -type d -exec mkdir -p ../arm-unknown-linux-gnueabihf/\{\} \;

# Building cross LLVM
cd "$SRC_DIR"/build/x86_64-unknown-linux-gnu/llvm
"$SRC_DIR"/src/llvm/configure \
    --enable-targets=x86,x86_64,arm,mips \
    --enable-optimized \
    --enable-assertions \
    --disable-docs \
    --enable-bindings=none \
    --disable-terminfo \
    --disable-zlib \
    --disable-libffi \
    --with-python=/usr/bin/python2.7 \
    --build=x86_64-unknown-linux-gnu \
    --host=x86_64-unknown-linux-gnu \
    --target=x86_64-unknown-linux-gnu
make -j$(nproc)
cd "$SRC_DIR"/build/arm-unknown-linux-gnueabihf/llvm
"$SRC_DIR"/src/llvm/configure \
    --enable-targets=x86,x86_64,arm,mips \
    --enable-optimized \
    --enable-assertions \
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
cd "$SRC_DIR"/build/arm-unknown-linux-gnueabihf/llvm/Release+Asserts/bin
mv llvm-config llvm-config-arm
ln -s ../../BuildTools/Release+Asserts/bin/llvm-config
./llvm-config --cxxflags

# Making Rust Build System use our LLVM build
cd "$SRC_DIR"/build/
chmod 0644 config.mk
grep 'CFG_LLVM_[BI]' config.mk |                                          \
    sed 's/x86_64\(.\)unknown.linux.gnu/arm\1unknown\1linux\1gnueabihf/g' \
    >> config.mk

cd "$SRC_DIR"
sed -i.bak 's/\([\t]*\)\(.*\$(MAKE).*\)/\1#\2/' mk/llvm.mk

# Building a working librustc for the cross architecture
cd "$SRC_DIR"
sed -i.bak \
    's/^CRATES := .*/TARGET_CRATES += $(HOST_CRATES)\nCRATES := $(TARGET_CRATES)/' \
    mk/crates.mk
sed -i.bak \
    's/\(.*call DEF_LLVM_VARS.*\)/\1\n$(eval $(call DEF_LLVM_VARS,arm-unknown-linux-gnueabihf))/' \
    mk/main.mk
sed -i.bak 's/foreach host,$(CFG_HOST)/foreach host,$(CFG_TARGET)/' mk/rustllvm.mk

cd "$SRC_DIR"
sed -i.bak 's/.*target_arch = .*//' src/etc/mklldeps.py

cd "$SRC_DIR"/build
arm-unknown-linux-gnueabihf/llvm/Release+Asserts/bin/llvm-config --libs \
    | tr '-' '\n' | sort > arm
x86_64-unknown-linux-gnu/llvm/Release+Asserts/bin/llvm-config --libs \
    | tr '-' '\n' | sort > x86
diff arm x86 >/dev/null

# Build it, part 1
cd "$SRC_DIR"/build
make -j$(nproc)

# Build it, part 2
cd "$SRC_DIR"/build
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

# Ship it
mkdir -p /dist/lib/rustlib/arm-unknown-linux-gnueabihf
cd /dist
cp -R "$SRC_DIR"/build/x86_64-unknown-linux-gnu/stage2/lib/rustlib/arm-unknown-linux-gnueabihf/* \
    lib/rustlib/arm-unknown-linux-gnueabihf
mv lib/rustlib/arm-unknown-linux-gnueabihf/bin .
cd lib
for i in rustlib/arm-unknown-linux-gnueabihf/lib/*.so; do
  ln -s $i .
done
cd ..
tar czf ../${TARBALL}.tar.gz .
cd ..
RUST_HASH=$(sha1sum ${TARBALL}.tar.gz | cut -f 1 -d ' ')
mv ${TARBALL}.tar.gz ${TARBALL}-${RUST_HASH}.tar.gz
