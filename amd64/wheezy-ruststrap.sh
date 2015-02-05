#!/bin/bash

# Cross compiles an ARM rust compiler (build = host = target = ARM)

# Based on the blog post "Cross bootstrapping Rust" by Riad Wahby
# (http://github.jfet.org/Rust_cross_bootstrapping.html)

# Run this script in a freshly debootstrapped Debian Wheezy rootfs
#
# $ cd /chroot
# $ debootstrap wheezy wheezy
# $ cd wheezy
# $ wget https://raw.githubusercontent.com/japaric/ruststrap/master/amd64/wheezy-ruststrap.sh
# $ chmod +x wheezy-ruststrap.sh
# $ systemd-nspawn ./wheezy-ruststrap.sh
# $ ls rust-*
# rust-2015-01-27-7774359-arm-unknown-linux-gnueabihf-38d44aaf0da4e5c359ff3551f3a88643ef5ca6e2.tar.gz

set -e
set -x

: ${DIST_DIR:=/dist}
: ${SRC_DIR:=/rust}
: ${TARGET:=arm-unknown-linux-gnueabihf}
: ${TOOLCHAIN_TARGET:=arm-linux-gnueabihf}

# install C cross compiler
echo deb http://www.emdebian.org/debian/ unstable main >> /etc/apt/sources.list
apt-get update -qq
apt-get install -qq --force-yes g++-4.7-arm-linux-gnueabihf

# install native C compiler
apt-get install -qq --force-yes build-essential g++-4.7

# set default compilers
update-alternatives \
  --install /usr/bin/gcc gcc /usr/bin/gcc-4.7 50 \
  --slave /usr/bin/g++ g++ /usr/bin/g++-4.7 \
  --slave /usr/bin/arm-linux-gnueabihf-gcc arm-linux-gnueabihf-gcc /usr/bin/arm-linux-gnueabihf-gcc-4.7 \
  --slave /usr/bin/arm-linux-gnueabihf-g++ arm-linux-gnueabihf-g++ /usr/bin/arm-linux-gnueabihf-g++-4.7
gcc -v
g++ -v
arm-linux-gnueabihf-gcc -v
arm-linux-gnueabihf-g++ -v

# install Rust build dependencies
apt-get install -qq --force-yes curl file git python

# fetch rust
git clone --recursive https://github.com/rust-lang/rust $SRC_DIR
cd $SRC_DIR
git checkout $1

# Get information about HEAD
HEAD_HASH=$(git rev-parse --short HEAD)
HEAD_DATE=$(TZ=UTC date -d @$(git show -s --format=%ct HEAD) +'%Y-%m-%d')
TARBALL=rust-${HEAD_DATE}-${HEAD_HASH}-${TARGET}

# configure Rust
mkdir build
cd build
../configure \
    --build=x86_64-unknown-linux-gnu \
    --host=x86_64-unknown-linux-gnu \
    --target=x86_64-unknown-linux-gnu,${TARGET}
cd x86_64-unknown-linux-gnu
find . -type d -exec mkdir -p ../${TARGET}/\{\} \;

# build cross LLVM
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

# enable llvm-config for the cross build
cd "$SRC_DIR"/build/${TARGET}/llvm/Release+Asserts/bin
mv llvm-config llvm-config-arm
ln -s ../../BuildTools/Release+Asserts/bin/llvm-config
./llvm-config --cxxflags

# make Rust Build System use our LLVM build
TGT_STR=`echo ${TARGET} | sed 's/-/\\\\1/g'`
cd "$SRC_DIR"/build/
chmod 0644 config.mk
grep 'CFG_LLVM_[BI]' config.mk |                                          \
    sed "s/x86_64\(.\)unknown.linux.gnu/$TGT_STR/g" \
    >> config.mk

cd "$SRC_DIR"
sed -i.bak 's/\([\t]*\)\(.*\$(MAKE).*\)/\1#\2/' mk/llvm.mk
sed -i.bak 's/^\(CROSS_PREFIX_'${TARGET}'=\)\(.*\)-$/\1'${TOOLCHAIN_TARGET}'-/' mk/platform.mk

# build a working librustc for the cross architecture
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

# build it, part 1
cd "$SRC_DIR"/build
make -j$(nproc)

# build it, part 2
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

# ship it
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
