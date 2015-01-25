#!/bin/bash

# Cross boostraps an arm rust compiler

# Based on the blog post "Cross bootstrapping Rust" by Riad Wahby
# (http://github.jfet.org/Rust_cross_bootstrapping.html)

# Tested on Ubuntu 14.04 chroot

set -e
set -x

: ${SRC_DIR:=/rust}
: ${DIST_DIR:=/dist}
: ${TARGET:=arm-unknown-linux-gnueabihf}
: ${TOOLCHAIN_TARGET:=arm-linux-gnueabihf}

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
TARBALL=rust-${HEAD_DATE}-${HEAD_HASH}-${TARGET}

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
    --target=x86_64-unknown-linux-gnu,${TARGET}
cd x86_64-unknown-linux-gnu
find . -type d -exec mkdir -p ../${TARGET}/\{\} \;

# Building cross LLVM
cd "$SRC_DIR"/build/x86_64-unknown-linux-gnu/llvm
"$SRC_DIR"/src/llvm/configure \
    --enable-targets=x86,x86_64,arm,aarch64,mips,powerpc \
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
cd "$SRC_DIR"/build/${TARGET}/llvm
"$SRC_DIR"/src/llvm/configure \
    --enable-targets=x86,x86_64,arm,aarch64,mips,powerpc \
    --enable-optimized \
    --enable-assertions \
    --disable-docs \
    --enable-bindings=none \
    --disable-terminfo \
    --disable-zlib \
    --disable-libffi \
    --with-python=/usr/bin/python2.7 \
    --build=x86_64-unknown-linux-gnu \
    --host=${TOOLCHAIN_TARGET} \
    --target=${TOOLCHAIN_TARGET}
make -j$(nproc)

# Enable llvm-config for the cross build
cd "$SRC_DIR"/build/${TARGET}/llvm/Release+Asserts/bin
mv llvm-config llvm-config-arm
ln -s ../../BuildTools/Release+Asserts/bin/llvm-config
./llvm-config --cxxflags

# Making Rust Build System use our LLVM build
TGT_STR=`echo ${TARGET} | sed 's/-/\\\\1/g'`
cd "$SRC_DIR"/build/
chmod 0644 config.mk
grep 'CFG_LLVM_[BI]' config.mk |                                          \
    sed "s/x86_64\(.\)unknown.linux.gnu/$TGT_STR/g" \
    >> config.mk

cd "$SRC_DIR"
sed -i.bak 's/\([\t]*\)\(.*\$(MAKE).*\)/\1#\2/' mk/llvm.mk
sed -i.bak 's/^\(CROSS_PREFIX_'${TARGET}'=\)\(.*\)-$/\1'${TOOLCHAIN_TARGET}'-/' mk/platform.mk

# Building a working librustc for the cross architecture
cd "$SRC_DIR"
sed -i.bak \
    's/^CRATES := .*/TARGET_CRATES += $(HOST_CRATES)\nCRATES := $(TARGET_CRATES)/' \
    mk/crates.mk
sed -i.bak \
    's/\(.*call DEF_LLVM_VARS.*\)/\1\n$(eval $(call DEF_LLVM_VARS,'${TARGET}'))/' \
    mk/main.mk
sed -i.bak 's/foreach host,$(CFG_HOST)/foreach host,$(CFG_TARGET)/' mk/rustllvm.mk

cd "$SRC_DIR"
sed -i.bak 's/.*target_arch = .*//' src/etc/mklldeps.py

cd "$SRC_DIR"/build
${TARGET}/llvm/Release+Asserts/bin/llvm-config --libs \
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
    -C linker=${TOOLCHAIN_TARGET}-g++ -C ar=${TOOLCHAIN_TARGET}-ar -C target-feature=+v6,+vfp2                 \
    --cfg debug -C prefer-dynamic --target=${TARGET}                                         \
    -o x86_64-unknown-linux-gnu/stage2/lib/rustlib/${TARGET}/bin/rustc --cfg rustc           \
    $PWD/../src/driver/driver.rs
LD_LIBRARY_PATH=$PWD/x86_64-unknown-linux-gnu/stage2/lib/rustlib/x86_64-unknown-linux-gnu/lib:$LD_LIBRARY_PATH \
    ./x86_64-unknown-linux-gnu/stage2/bin/rustc --cfg stage2 -O --cfg rtopt                                    \
    -C linker=${TOOLCHAIN_TARGET}-g++ -C ar=${TOOLCHAIN_TARGET}-ar -C target-feature=+v6,+vfp2                 \
    --cfg debug -C prefer-dynamic --target=${TARGET}                                         \
    -o x86_64-unknown-linux-gnu/stage2/lib/rustlib/${TARGET}/bin/rustdoc --cfg rustdoc       \
    $PWD/../src/driver/driver.rs

# Ship it
mkdir -p "$DIST_DIR"/lib/rustlib/${TARGET}
cd "$DIST_DIR"
cp -R "$SRC_DIR"/build/x86_64-unknown-linux-gnu/stage2/lib/rustlib/${TARGET}/* \
    lib/rustlib/${TARGET}
mv lib/rustlib/${TARGET}/bin .
cd lib
for i in rustlib/${TARGET}/lib/*.so; do
  ln -s $i .
done
cd ..
tar czf ../${TARBALL}.tar.gz .
cd ..
RUST_HASH=$(sha1sum ${TARBALL}.tar.gz | cut -f 1 -d ' ')
mv ${TARBALL}.tar.gz ${TARBALL}-${RUST_HASH}.tar.gz
