# `ruststrap`

Rust and Cargo for `arm-unknown-linux-gnueabihf`

This repository contains the build scripts used to create rust and cargo
nightlies. If you are looking for the nightlies, click the link below.

# [Unofficial "nightlies"][nightlies]

(Use at your own risk!)

I plan to store the last three nightlies of rust and cargo.

At the moment, I haven't setup automation yet, so I'm uploading the nightlies
manually. For that reason, these nightlies won't match the exact commit hash of
the official nightlies.

# Test matrix

(I've only done smoke testing at this point, but I'd like to run the full test
suite at some point.)

| Device/distribution | Debian (sid) | Arch   | Exherbo    |
| ------------------- | :----------: | :----: | :--------: |
| Beaglebone          | -            | OK     | -          |
| Odroid XU           | OK           | OK     | See issues |

# Building Rust

You have two options:

- If your ARM device is "fast", has plenty of RAM (like 2GB), and you have
  plenty of time you can [build rust using a stage-0 snapshot](#from-snapshot)
- Otherwise, you should [cross bootstrap rust](#cross-bootstrap) (preferred)

## Cross bootstrap

Based on the blog post ["Cross bootstrapping Rust"][blog] by Riad Wahby.

Last successful build: See [nightlies]

Produced compiler successfully tested on: See [Test matrix](#test-matrix)

This produces an ARM rust compiler on a x86_64 machine.

### Instructions

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

## From snapshot

Successfully tested on a Odroid XU (quad core + 2G RAM)

This is the process normally used to build Rust on a x86_64 machine, where the
compiler is bootstrapped from a stage-0 snapshot. The problem is that the
Rust team doesn't provide a stage-0 snapshot for ARM, so you'll have to use a
[snapshot I've previously created][nightlies].

Apart from the snapshot, the Rust Build System needs minimal patching:

- Add an "arm-linux" entry to `snapshot.txt`
- Modify "get-snapshot.py" to download the unofficial snapshot

The `rbs.patch` contains the necessary changes.

### Instructions

On an ARM device:

```
$ git clone --recursive https://github.com/rust-lang/rust
$ cd rust
$ curl -s https://raw.githubusercontent.com/japaric/ruststrap/master/rbs.patch | patch -p1
$ mkdir build && cd build
$ ../configure && make -j$(nproc)
```

# Building cargo

Last successful build: See [nightlies]

See issues.

# Build a stage-0 snapshot

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

# License

ruststrap (i.e. the script and patches) is licensed under the MIT license.

See LICENSE-MIT for more details.

[blog]: http://github.jfet.org/Rust_cross_bootstrapping.html
[nightlies]: http://ftp.floorchan.org/mirror/stages/rust/
