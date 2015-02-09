You can see this document rendered at:

https://github.com/japaric/ruststrap/blob/master/1-how-to-cross-compile.md


"Compiling 'Hello, world!' on my (single core) ARM device takes more than 5
seconds!"

If developing on your ARM device is intolerable due to the long compilation
times, there's an alternative for you: cross compilation (which comes with its
own set of problems, btw).

Cross compilation in Rust *almost* works out of the box, this how-to gives you
the missing bits of information needed to make it work.

Note: In this how-to I'll use `arm-unknown-linux-gnueabihf` as the target
triple (the cross compilation target), and `x86_64-unknown-linux-gnu` as the
host triple (my PC, where everything is compiled). But, it should be possible
to use different target/host triples with a little tweak of the instructions
outlined here.

# Cross compiling with rustc

## First attempt

Cross compiling should be as easy as passing the `--target=$TRIPLE` flag to
`rustc`, right?

``` rust
// frestanding.rs
#![crate_type = "lib"]
#![feature(no_std)]
#![no_std]
```

```
$ rustc --target=arm-unknown-linux-gnueabihf freestanding.rs && echo OK
OK
```

It worked! Because it has no dependencies, but that's not an interesting crate
unless you want to build your own `core` crate. If you then try the classic
"Hello, world!":

``` rust
// hello.rs
fn main() {
    println!("Hello, world!");
}
```

```
$ rustc --target=arm-unknown-linux-gnueabihf hello.rs
hello.rs:1:1: 1:1 error: can't find crate for `std`
hello.rs:1 // hello.rs
```

It doesn't work!

What the compiler really wants to say here is that there isn't a `std` crate
*for the arm-unknown-linux-gnueabihf triple*. In other words, you need to have
a `std` crate that was compiled for ARM installed somewhere in your system. But
the nightly you have installed only comes with native crates.

## Installing the ARM crates

You can cross compile the ARM version of `std` and friends from Rust's source
code, you just need to pass an extra flag to the `configure` script:

```
$ ./configure --target=arm-unkonwn-linux-gnueabihf,x86_64-unknown-linux-gnu
$ make -j$(nproc)
$ sudo make install
```

If you don't feel like spending 1 hour or more bootstrapping the compiler, I
got good news for you. My unofficial ARM nightlies contain the ARM crates you
need. And the official i686 nightly contains the i686 crates needed to cross
compile to i686, etc.

You only need to install the static (`.rlib`) libraries from the foreign
nightly into your native installation:

```
$ tree /usr/local/lib
.
|-- bin
|   `-- rustc
`-- lib
    |-- libstd-deadbeef.so
    |-- (..)
    `-- rustlib
        |-- arm-unknown-linux-gnueabihf <-- Copy this folder from the foreign nightly
        |   `-- lib
        |       |-- libstd-deadbeef.rlib
        |       `-- (..)
        `-- x86_64-unknown-linux-gnu <-- This comes with the native nightly
            `-- lib
                |-- libstd-deadbeef.rlib
                `-- (..)
```

(If you are using multirust, your toolchain is installed at
`~/.multirust/toolchains/nightly`)

## Cross compiling a static library

Once you've installed the ARM crates, you can now cross compile static
libraries:

``` rust
// lib.rs
#![crate_type = "lib"]

pub fn hello() {
    println!("Hello, world!");
}
```

```
$ rustc --target=arm-uknown-linux-gnueabihf lib.rs && ls lib*
liblib.rlib
```

## Cross compiling a binary

But, if you try the "Hello, world!" crate again:

```
$ rustc --target=arm-unknown-linux-gnueabihf hello.rs
error: linking with `cc` failed: exit code: 1
note: "cc" '"-Wl,--as-needed"' (plus a bunch of other flags)
note: /usr/bin/ld: hello.o: Relocations in generic ELF (EM: 40)
/usr/bin/ld: hello.o: Relocations in generic ELF (EM: 40)
hello.o: error adding symbols: File in wrong format
collect2: error: ld returned 1 exit status

error: aborting due to previous error
```

It still doesn't work!

What went wrong this time is that `rustc` is using `cc` to link the binary,
and this doesn't work because `cc` is a symlink to your native compiler
(`gcc`).

The solution is to tell `rustc` to use the right linker:

```
# install an ARM cross-compiler, if you don't have one installed already
# this command is for Ubuntu/Debian, use whatever is appropiate for your OS
$ apt-get install gcc-arm-linux-gnueabihf

# tell rustc the name of the cross-compiler (which must be in your PATH)
$ rustc -C linker=arm-linux-gnueabihf-gcc-4.8 --target=arm-unknown-linux-gnueabihf hello.rs

# check that the produced binary is really an ARM binary
$ file hello
hello: ELF 32-bit LSB  shared object, ARM, EABI5 version 1 (SYSV), (..)

# sanity check: the binary should work on an ARM device
$ scp hello me@arm:~
$ ssh me@arm ./hello
Hello, world!
```

# Cross compiling with cargo

To tell cargo to cross compile you also have to pass the `--target` flag to the
`build` command. But, there is something you need to change before it will
Just Work.

By default, `cargo` (just like `rustc`) will use `cc` as the default linker for
native and cross compilation. You can override this behavior using Cargo's
[configuration file](http://doc.crates.io/config.html).

```
# you can set a different linker for each target
$ cat ~/.cargo/config
[target.arm-unknown-linux-gnueabihf]
linker = "arm-linux-gnueabihf-gcc-4.8"

# sanity check
$ cargo new --bin hello
$ cd hello
$ cargo build --target=arm-unknown-linux-gnueabihf
$ file target/arm-unknown-linux-gnueabihf
hello: ELF 32-bit LSB  shared object, ARM, EABI5 version 1 (SYSV), (..)
```
