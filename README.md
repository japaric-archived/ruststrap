# `ruststrap`

Bootstrap an `arm-unknown-linux-gnueabihf` compiler

The produced compiler will run on ARM and will produce ARM binaries

You have two options:

- If your ARM device is "fast" and has plenty of RAM, you can
  [build rust using a stage-0 snapshot]
- Otherwise, you should [cross bootstrap rust]

# cross bootstrap rust

Based on the blog post ["Cross bootstrapping Rust"][blog] by Riad Wahby.

Last successful build: `rustc 0.12.0-pre (5d653c17a 2014-09-26 11:44:01 +0000)`

Produced compiler successfully tested on: Odroid-XU, Beaglebone

This produces an ARM rust compiler on a x86_64 machine.

## How-to

(Friendly advice: Don't execute bash scripts you haven't read)

(Note: I've decided to use an Ubuntu chroot for reproducibility purposes, and
also because the chroot can be easily removed afterwards)

On a x86_64 machine:

```
$ sudo su
$ cd /mnt
$ debootstrap --variant=buildd --arch=amd64 trusty ubuntu http://archive.ubuntu.com/ubuntu/
$ cd ubuntu && systemd-nspawn
> apt-get update && apt-get -qq install curl
> curl -s https://raw.githubusercontent.com/japaric/ruststrap/master/ruststrap.sh | sh
> logout
```

The final product (compiler + libraries in a tarball) will be located at:

`/mnt/ubuntu/root/toolchains/src/rust/build`

# build rust using a stage-0 snapshot

Successfully tested on a Odroid XU (quad core + 2G RAM)

This is the process normally used to build Rust on a x86_64 machine, where the
compiler is bootstrapped from a stage-0 snapshot. The problem is that the
Rust team doesn't provide a stage-0 snapshot for ARM, so you'll have to use a
[snapshot I've previously created][floorchan] (if you trust me).

Apart from the snapshot, the Rust Build System needs minimal patching:

- Add an "arm-linux" entry to `snapshot.txt`
- Modify "get-snapshot.py" to download the unofficial snapshot

The `rbs.patch` contains the necessary changes.

## How-to

On an ARM device:

```
$ git clone --recursive https://github.com/rust-lang/rust
$ cd rust
$ curl -s https://raw.githubusercontent.com/japaric/ruststrap/master/rbs.patch | patch -p1
$ mkdir build && cd build
$ ../configure && make -j$(nproc)
```

# Create a stage-0 snapshot

Last successful build: `2014-09-22 437179e`

This is how I built the first stage-0 snapshot and is kept here for historical
reasons

## How-to

On an ARM device:

```
$ sudo su
$ cd /mnt
$ debootstrap --variant=buildd --arch=armhf sid debian
$ cd debian/root
$ cp $CROSS_BOOTSTRAPPED_RUSTC_TARBALL .
$ tar xvjf $CROSS_BOOTSTRAPPED_RUSTC_TARBALL
$ rm $CROSS_BOOTSTRAPPED_RUSTC_TARBALL
$ cd .. && systemd-nspawn
> export PATH=$PATH:/root/bin
> export LD_LIBRARY_PATH=$PATH:/root/lib
> rustc -v
> apt-get update && apt-get -qq install wget
> wget https://raw.githubusercontent.com/japaric/ruststrap/master/make-stage0.sh
> chmod +x make-stage0.sh
> ./make-stage0.sh $SNAPSHOT_REV
> logout
```

The final product (stage-0 tarball) will be located at:

`/mnt/debian/root/toolchains/src/rust/build`

# TODO

- Get cargo working on arm

# License

ruststrap (i.e. the script and patches) is licensed under the MIT license.

See LICENSE-MIT for more details.

[blog]: http://github.jfet.org/Rust_cross_bootstrapping.html
[floorchan]: http://ftp.floorchan.org/mirror/stages/rust/
