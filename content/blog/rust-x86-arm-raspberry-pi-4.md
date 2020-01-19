---
title: "Rust - X86 to ARM builds for Raspberry Pi 4"
date: 2020-01-19T14:51:55-05:00
---

Rust x86 to ARM for Raspberry Pi 4
===

Recently the [Raspberry Pi 4](https://www.raspberrypi.org/products/raspberry-pi-4-model-b/) was released and I purchased several of them to replace my previous [Raspberry Pi 3's](https://www.raspberrypi.org/products/raspberry-pi-3-model-b-plus/) and [RockPro64's](https://store.pine64.org/?product=rockpro64-4gb-single-board-computer) which had made up my previous home cluster (but are now re-purposed for other tasks).

My initial deployment of six Pi4's was all on [Manjaro Linux's Arm Edition](https://manjaro.org/download/#raspberry-pi-4) which was functional for the purposes of deploying a [K3s kubernetes cluster](https://github.com/rancher/k3s/), but I soon decided that I wanted to run an operating system with more of a security focus.

Since then I've redeployed all machines with [CentOS 7's ARMHFP Release](https://wiki.centos.org/SpecialInterestGroup/AltArch/armhfp) for stability and out-of-the-box SELinux functionality as these machines are intended to manage some sensitive data and applications.

I'm using this cluster to work on a couple of different projects of mine in [Rust](https://www.rust-lang.org/), but had to overcome a couple of small hurdles to get to the point where I could build from my local [Manjaro Linux](https://manjaro.org/) workstation and [cross-compile for ARM](https://www.linux.com/tutorials/cross-compiling-arm/).

In this small post I'll walk through quickly cross-compiling your programs to Raspberry Pi4 from an [x86](https://en.wikipedia.org/wiki/X86) host given the environment described above.

# Project Template

To start, let's create a new project with [Cargo](https://doc.rust-lang.org/cargo/) which we'll use for this demo:

```shell
cargo new testpi --bin
cd testpi/
```

A "hello world" example is templated by default, which you can test:

```shell
$ cargo run
   Compiling testpi v0.1.0 (/home/shane/Code/testpi)
    Finished dev [unoptimized + debuginfo] target(s) in 0.52s
     Running `target/debug/testpi`
Hello, world!
```

Now we're compiling for the local x86 system and it's time to setup our build toolchain for cross-compiling to ARM.

# Cross-Compile Build Toolchain

We need to install a toolchain capable of building for ARM, for many operating systems this is the `arm-linux-gnueabihf-gcc` package available via your package manager.

For instance if you're on [Arch Linux](https://archlinux.org/) or [Manjaro Linux](https://manjaro.org/) and you have [pamac](https://aur.archlinux.org/packages/pamac-aur/) available on your system you can install the toolchain from the [AUR](https://aur.archlinux.org/) with the following line:

```shell
pamac build arm-linux-gnueabihf-gcc
```

This will install the [AUR arm-linux-gnueabihf-gcc package](https://aur.archlinux.org/packages/arm-linux-gnueabihf-gcc/).

## Avoiding GLIBC

In this post I'm going to avoid [GLIBC](https://www.gnu.org/software/libc/) altogether by using a [MUSL](https://www.musl-libc.org/) based arm build target to emit statically linked binaries using MUSL libc instead, since [CentOS 7](https://centos.org) only provides a very old version of GLIBC.

# Cargo Setup

Now that you have the build toolchain you'll need to configure Rust to use it. The best way to persistently configure cargo to build for your target appropriately is to add lines to the `~/.cargo/config` file (create it if it doesn't exist):

```toml
[target.armv7-unknown-linux-musleabihf]
linker = "arm-linux-gnueabihf-gcc"
```

This configures `cargo` to use our arm compiler installed in the previous step and utilize that for managing libc. Using the `armv7-unknown-linux-musleabihf` target with this compiler will handle automatically statically linking [MUSL LIBC](https://www.musl-libc.org/) instead of dynamically linking GLIBC so that we don't have to manage dynamic libraries for our binaries.

# Building

Everything should be all set! Build your Raspberry Pi 4 binary with:

```shell
cargo build --target armv7-unknown-linux-musleabihf --release
```

For a quick test you can use `scp` to copy the binary over to your Pi and run it:

```shell
scp target/armv7-unknown-linux-musleabihf/release/testpi root@${SERVER_IP}:/usr/local/bin/testpi
ssh root@${SERVER_IP} testpi
```

From here you can expand upon this to build and deploy your Rust software to your Pi4's, happy coding!
