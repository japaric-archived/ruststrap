# `ruststrap`

Cross bootstraps an arm-unknown-linux-gnueabihf rust compiler. (i.e. the
produced compiler will run on ARM and will be capable of building ARM binaries)

Based on the blog post ["Cross bootstrapping Rust"][blog] by Riad Wahby.

Tested on a freshly [deboostrap]ped Ubuntu 14.04 LTS chroot

Last successful build: `rustc 0.12.0-pre (4d69696ff 2014-09-24 20:35:52 +0000)`

Produced compiler successfully tested on: Odroid-XU

(**Note** The produced compiler **won't** work on a Raspberry Pi)

# How to cross bootstrap rustc

(Friendly advice: Don't execute bash scripts you don't understand)

On a x86_64 machine:

```
$ sudo su
$ cd /mnt
$ debootstrap --variant=buildd --arch=amd64 trusty ubuntu http://archive.ubuntu.com/ubuntu/
$ cd ubuntu
$ systemd-nspawn
> apt-get update && apt-get -qq install wget
> wget https://raw.githubusercontent.com/japaric/ruststrap/master/ruststrap.sh
> ./ruststrap.sh
> logout
```

The final product (compiler + libraries) will be located at:

`/mnt/ubuntu/root/toolchains/src/rust/build/rust_arm-unknown-linux-gnueabihf_dist.tbz2`

# TODO

- Create a script to build a stage-0 rustc with the cross bootstrapped rustc
  (obviously, this script must be executed on an ARM device)
- Patch the Rust Build System to build Rust from the stage-0 generated in the
  previous step
- Maintain arm-unknown-linux-gnueabihf snapshots

# License

ruststrap is licensed under the MIT license.

See LICENSE-MIT for more details.

[blog]: http://github.jfet.org/Rust_cross_bootstrapping.html
[deboostrap]: https://wiki.debian.org/Debootstrap
