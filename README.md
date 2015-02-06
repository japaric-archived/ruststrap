# `ruststrap`

**Unofficial** Rust and Cargo nightlies for `arm-unknown-linux-gnueabihf`.

This repository contains the build/automation scripts. If you are looking for
the binaries see the link below.

# [Nightlies]

Use at your own risk!

At the moment, no one is running CI tests for the `arm-unknown-linux-gnueabihf`
triple, so the nightlies may break, and/or bugs may be introduced on a daily
basis.

# Installation

Sorry, no [un]installation scripts, simply unpack the tarballs wherever it
makes sense to you and update your `$PATH` variable and/or `ld.so.conf` file if
necessary.

(FWIW, I usually just unpack the tarballs in my `/usr/local` folder)

# Tested devices/OSes

Format is $DEVICE $OS ($DATE_OF_LAST_SMOKE_TEST)

- Odroid XU (ARMv7) in a Raspbian chroot. (today ;-), because I use it to build
  the nightlies)
- Odroid XU running Arch. (2015-02-05)
- Raspberry Pi (ARMv6) running Raspbian. (2015-02-04)

Note: This is list is not comprehensive not regularly updated, but gives you an
idea of the supported devices and OSes.

Feel free to send a PR adding your device to the list!

# License

All the scripts/patches in this repository are licensed under the MIT license.

See LICENSE-MIT for more details.

[Nightlies]: https://www.dropbox.com/sh/qfbt03ys2qkhsxs/AACxFoD1OrxDXURzj5wX0IYUa?dl=0
