Unofficial rust and cargo binaries for the `arm-unknown-linux-gnueabihf`
triple.

Since the `arm-unknown-linux-gnueabihf` triple is not officially supported by
the Rust project, there are no official build bots that enforce the "Never
Break the Build" policy. This means that the nightly builds may break from time
to time, and also that bugs may be unintentionally introduced (or fixed!) in
every PR without the knowledge of the author/reviewers.

However, I do run the full cargo and rust test suite with each nightly, and
unconditionally upload the nightly even if some tests fail (otherwise this
folder would be empty :P). Each uploaded nightly is accompanied by a text file
that contains the whole test suite output, this gives you an idea of what
doesn't work. (Last time I checked 99% of the crate unit tests passed though).

# Tested devices

Not comprehensive and likely outdated list of devices that have passed some
form of smoke test.

Note: The format is $DEVICE + $OS @ $DATE_OF_LAST_SMOKE_TEST

- Odroid XU (ARMv7 SBC) + Raspbian @ hopefully today (this is the build bot)
- Odroid XU + Arch @ 2015-02-05
- Raspberry Pi (ARMv6 SBC) + Raspbian @ 2015-02-04
- Samsung Chromebook 2 (ARMv7 Laptop) + Gentoo @ 2015-02-06

# Installation

I recommend using multirust:

https://github.com/brson/multirust

$ curl -sf https://raw.githubusercontent.com/brson/multirust/master/blastoff.sh | sh

$ cd /path/to/empty/folder

$ wget $CARGO_TARBALL

$ wget $RUST_TARBALL

$ tar xf $CARGO_TARBALL && rm $CARGO_TARBALL

$ tar xf $RUST_TARBALL && rm $RUST_TARBALL

$ multirust update unofficial-nightly --copy-local .

(^ or you could use --link-local)

$ multirust default unofficial-nightly

Alternatively, you could just extract the tarballs wherever and update your
`$PATH` variable and/or `ld.so.conf` file if necessary.

# Disclaimer

THESE BINARIES ARE PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

# Source code and licenses

Rust: https://github.com/rust-lang/rust
Cargo: https://github.com/rust-lang/cargo

Both Rust and Cargo are licensed under the MIT license and the Apache license
(version 2.0), for the exact terms and conditions check their respective
repositories.

# Build scripts

All the bash scripts I use to build these nightlies can be found in the
following repository:

https://github.com/japaric/ruststrap

# Problems with the nightlies?

If running `rustc` or `cargo` or a binary produced by `rustc` yields one of the
following messages:

- "Illegal instruction"
- "rustc: /path/to/libfoo.so.1: version `FOO_1.2.3' not found (required by /path/to/librust_crate-4e7c5e5c.so).`"

Open an issue at:

https://github.com/japaric/ruststrap/issues

Include the full command, its output, and what device and OS you are using

If running some binary produced by these nightlies misbehaves (panics when it
shouldn't) or produces unexpected output, that probably belongs to the
rust-lang/rust issue tracker.
