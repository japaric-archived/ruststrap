# `ruststrap`

Unofficial Rust and Cargo nightlies for `arm-unknown-linux-gnueabihf`
(Specifically, the nightlies target the armv7l architecture. These nightlies
*won't* work on armv6 processors like the Raspberry Pi)

This repository contains the build scripts. If you are looking for the actual
nightlies, see the links below.

# Nightlies (Use at your own risk!)

Nightly archive: [Rust][rust] and [Cargo][cargo]

(I plan to host the last three nightlies)

## Installation

Grab the tarball and extract it into `/usr/local`.

(That's enough for me, since my `/usr/local` is usually empty. If you need a
more elaborate (un)installation method, feel free to open an issue)

## Test matrix

These are the results of smoke testing the nightlies on some devices I have at
hand:

| Device/distribution | Debian (sid) | Arch   | Exherbo    |
| ------------------- | :----------: | :----: | :--------: |
| Beaglebone          | -            | OK     | -          |
| Odroid XU           | OK           | OK     | See issues |

If you smoke test these nightlies in some other device, please send a PR to
update this table.

Proper testing is WIP and is being tracked in these issues:

- Rust: Running the full test suite: See [#5][test-rust]
- Cargo: Test suite doesn't pass on the Odroid XU: See [#10][test-cargo]

# Automation

The build process is fully automated. Builds are triggered at the same time the
official nightlies are built. Therefore both (official and unofficial)
nightlies should have the same commit hash.

## How is the Rust nightly built?

The Rust compiler + libraries are [cross bootstrapped][ruststrap] on a x86_64
machine, therefore the test suite is *not* executed.

## How is the Cargo nightly built?

Cargo is [bootstrapped][build-cargo] on an ARM device, and although the test
suite can be executed, it's currently skipped because is [failing][test-cargo].

# Acknowledgment

None of this would have been possible without Riad Wahby's blog post:
["Cross bootstrapping Rust"][blog].

# License

ruststrap (i.e. the script and patches) is licensed under the MIT license.

See LICENSE-MIT for more details.

[blog]: http://github.jfet.org/Rust_cross_bootstrapping.html
[build-cargo]: /build-cargo.sh
[cargo]: http://ftp.floorchan.org/mirror/stages/cargo/
[rust]: http://ftp.floorchan.org/mirror/stages/rust/
[ruststrap]: /ruststrap.sh
[test-cargo]: https://github.com/japaric/ruststrap/issues/10
[test-rust]: https://github.com/japaric/ruststrap/issues/5
