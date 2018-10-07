+++
date = "2018-10-07T18:57:00-04:00"
title = "Rust - Fast + Small Docker Image Builds"
categories = ["programming", "rust"]
tags = ["rust", "docker", "alpine", "musl"]

+++

# Fast + Small Docker Image Builds for Rust Apps

In this post I'm going to demonstrate how to create small, quickly built [Docker Images][0] for [Rust][1] applications.

We'll start by creating a simple test application, and then building and iterating on a [Dockerfile][2].

## Requirements

Ensure you have the following installed:

* [rustup][3] v1.14.0+
* [docker][4] v17.06.2+

## Setup: demo app setup

Make sure you have and are using the latest stable Rust with `rustup`:

```
rustup default stable
rustup update
```

Create a new project called "myapp":

```
cargo new myapp
cd myapp/
```

## Setup: initial dockerfile

The following is a starting place we'll use for our [docker build][5], create a file named `Dockerfile` in the current directory:

```dockerfile
FROM rust:latest

WORKDIR /usr/src/myapp

COPY . .

RUN cargo build --release

RUN cargo install --path .

CMD ["/usr/local/cargo/bin/myapp"]
```

And also create a `.dockerignore` file with the following contents:

```
target/
Dockerfile
```

You can test building and running the app with:

```
docker build -t myapp .
docker run --rm -it myapp
```

If everything is working properly, you should see the response `Hello, world!`.

## Problems with our initial docker build

At the time of writing this blog post, Rust's package manager [cargo][6] has an issue where [it does not have a --depedencies-only option to build depedencies independently][7].

The lack of an option with `cargo` to build the depedencies separately leads to a problem of having the dependencies for the application rebuilt on every change of the `src/` contents, when we really only want dependencies to be rebuilt if the `Cargo.toml` or `Cargo.lock` files are changed (e.g. when dependencies are added or updated).

As an additional problem, while the [rust:latest][8] Docker image is great for building, it's a fairly large image coming in at over 1.5GB in size.

### Improving builds so that dependencies don't rebuild on src/ file changes

To avoid this problem and enable docker build cache so that builds are quicker, let's start by modifying our `Cargo.toml` to add a dependency:

```toml
[package]
name = "myapp"
version = "0.1.0"

[dependencies]
rand = "0.5.5"
```

We've added a new [crate][9] as a dependency to our project named [rand][10] which provides convenient random number generation utilities.

Now if we run:

```
docker build -t myapp .
```

It will build the `rand` dependency and add it to the cache, but changing `src/main.rs` will invalidate the cache for the next build:

```rust
cat <<EOF > src/main.rs
fn main() {
    println!("I've been updated!");
}
EOF
docker build -t myapp .
```

Notice that this build again had to rebuild the `rand` dependency.

While we're waiting on a `--dependencies-only` build options for `cargo`, we can overcome this problem by changing our `Dockerfile` to have a default `src/main.rs` with which the dependencies are built before we `COPY` any of our code into the build:

```dockerfile
FROM rust:latest

WORKDIR /usr/src/myapp

COPY Cargo.toml Cargo.toml

RUN mkdir src/

RUN echo "fn main() {println!(\"if you see this, the build broke\")}" > src/main.rs

RUN cargo build --release

RUN rm -f target/release/deps/myapp*

COPY . .

RUN cargo build --release

RUN cargo install --path .

CMD ["/usr/local/cargo/bin/myapp"]
```

The following line from the above `Dockerfile` will cause the following `cargo build` to rebuild only our application:

```
RUN rm -f target/release/deps/myapp*
```

So now if we build:

```
docker build -t myapp .
```

And then make another change to `src/main.rs`:

```
cat <<EOF > src/main.rs
fn main() {
    println!("I've been updated yet again!");
}
EOF
```

We'll find that subsequent `docker build` runs only rebuild `myapp` and the depedencies have been cached for quicker builds.

### Reducing the size of the image

The [rust:latest][8] image has all the tools we need to build our project, but is over 1.5GB in size. We can improve the image size by using [Alpine Linux][11] which is an excellent small Linux distribution.

The Alpine team provides [a docker image][13] which is only several megabytes in size and still has some shell functionality for debugging and can be used as a small base image for our Rust builds.

Using [multi-stage docker build][12]s we can use [rust:latest][8] to do our build work, but then simply copy the app into a final build stage based on [alpine:latest][13]:

```dockerfile
# ------------------------------------------------------------------------------
# Cargo Build Stage
# ------------------------------------------------------------------------------

FROM rust:latest as cargo-build

WORKDIR /usr/src/myapp

COPY Cargo.toml Cargo.toml

RUN mkdir src/

RUN echo "fn main() {println!(\"if you see this, the build broke\")}" > src/main.rs

RUN cargo build --release

RUN rm -f target/release/deps/myapp*

COPY . .

RUN cargo build --release

RUN cargo install --path .

# ------------------------------------------------------------------------------
# Final Stage
# ------------------------------------------------------------------------------

FROM alpine:latest

COPY --from=cargo-build /usr/local/cargo/bin/myapp /usr/local/bin/myapp

CMD ["myapp"]
```

Now if you run:

```
docker build -t myapp .
docker images |grep myapp
```

You should see something like:

```
myapp               latest              03a3838a37bc        7 seconds ago       8.54MB
```

## Next: Follow up - fixing and further improving our build

If you tried to run the above example with `docker run --rm -it myapp`, you probably got an error like:

```
standard_init_linux.go:187: exec user process caused "no such file or directory"
```

If you're familiar with [ldd][15] you can run the following to see that we're missing shared libraries for our application:

```
docker run --rm -it myapp ldd /usr/local/bin/myapp
```

In the above examples we show how to avoid rebuilding depdencies on every `src/` file change, and how to reduce our image footprint from 1.5GB+ to several megabytes, however our build doesn't currently work because we need to build against [MUSL Libc][14] which is a lightweight, fast standard library available as the default in `alpine:latest`.

Beyond that, we also want to make sure that our application runs as an unprivileged user inside the container so as to adhere to the [principle of least privilege][16].

### Building for MUSL Libc

To build for MUSL libc we'll need to install the `x86_64-unknown-linux-musl` [target][17] so that `cargo` can be flagged to build for it with `--target`. We'll also need to flag Rust to use the `musl-gcc` linker.

The `rust:latest` image will come with `rustup` pre-installed. `rustup` allows you to install new targets with `rustup target add $NAME`, so we can modify our `Dockerfile` as such:

```dockerfile
# ------------------------------------------------------------------------------
# Cargo Build Stage
# ------------------------------------------------------------------------------

FROM rust:latest as cargo-build

RUN apt-get update

RUN apt-get install musl-tools -y

RUN rustup target add x86_64-unknown-linux-musl

WORKDIR /usr/src/myapp

COPY Cargo.toml Cargo.toml

RUN mkdir src/

RUN echo "fn main() {println!(\"if you see this, the build broke\")}" > src/main.rs

RUN RUSTFLAGS=-Clinker=musl-gcc cargo build --release --target=x86_64-unknown-linux-musl

RUN rm -f target/x86_64-unknown-linux-musl/release/deps/myapp*

COPY . .

RUN RUSTFLAGS=-Clinker=musl-gcc cargo build --release --target=x86_64-unknown-linux-musl

# ------------------------------------------------------------------------------
# Final Stage
# ------------------------------------------------------------------------------

FROM alpine:latest

COPY --from=cargo-build /usr/src/myapp/target/x86_64-unknown-linux-musl/release/myapp /usr/local/bin/myapp

CMD ["myapp"]
```

Note the following line which shows the new way in which we're building the app for MUSL Libc:

```
RUSTFLAGS=-Clinker=musl-gcc cargo build --release --target=x86_64-unknown-linux-musl
```

Do a fresh build of the app and run it:

```
docker build -t myapp .
docker run --rm -it myapp
```

If everything worked properly you should again see `I've been updated yet again!`.

### Running as an unprivileged user

To follow [principle of least privilege][16], let's create a user named "myapp" which we'll use to run `myapp` as instead of as the `root` user.

Change the `Final Stage` docker build stage to the following:

```dockerfile
# ------------------------------------------------------------------------------
# Final Stage
# ------------------------------------------------------------------------------

FROM alpine:latest

RUN addgroup -g 1000 myapp

RUN adduser -D -s /bin/sh -u 1000 -G myapp myapp

WORKDIR /home/myapp/bin/

COPY --from=cargo-build /usr/src/myapp/target/x86_64-unknown-linux-musl/release/myapp .

RUN chown myapp:myapp myapp

USER myapp

CMD ["./myapp"]
```

Update `src/main.rs`:

```
cat <<EOF > src/main.rs
use std::process::Command;

fn main() {
    let mut user = String::from_utf8(Command::new("whoami").output().unwrap().stdout).unwrap();
    user.pop();
    println!("I've once more been updated, and now I run as the user {}!", user)
}
```

And now build the image and run:

```
docker build -t myapp .
docker run --rm -it myapp
```

If everything worked properly you should see `I've once more been updated, and now I run as the user myapp!`.

## Wrapup!

The complete `Dockerfile` we have now for building our app while we're working on it now looks like:

```dockerfile
# ------------------------------------------------------------------------------
# Cargo Build Stage
# ------------------------------------------------------------------------------

FROM rust:latest as cargo-build

RUN apt-get update

RUN apt-get install musl-tools -y

RUN rustup target add x86_64-unknown-linux-musl

WORKDIR /usr/src/myapp

COPY Cargo.toml Cargo.toml

RUN mkdir src/

RUN echo "fn main() {println!(\"if you see this, the build broke\")}" > src/main.rs

RUN RUSTFLAGS=-Clinker=musl-gcc cargo build --release --target=x86_64-unknown-linux-musl

RUN rm -f target/x86_64-unknown-linux-musl/release/deps/myapp*

COPY . .

RUN RUSTFLAGS=-Clinker=musl-gcc cargo build --release --target=x86_64-unknown-linux-musl

# ------------------------------------------------------------------------------
# Final Stage
# ------------------------------------------------------------------------------

FROM alpine:latest

RUN addgroup -g 1000 myapp

RUN adduser -D -s /bin/sh -u 1000 -G myapp myapp

WORKDIR /home/myapp/bin/

COPY --from=cargo-build /usr/src/myapp/target/x86_64-unknown-linux-musl/release/myapp .

RUN chown myapp:myapp myapp

USER myapp

CMD ["./myapp"]
```

From here see my demo on [deploying Rust to Kubernetes on DC/OS with Skaffold][18]. Utilizing some of the techniques in that demo, you could automate deployment of your application to [Kubernetes][19] for testing on a local [minikube][20] system using [Skaffold][21].

Happy coding!

[0]:https://hub.docker.com/explore/
[1]:https://www.rust-lang.org/
[2]:https://docs.docker.com/engine/reference/builder/
[3]:https://rustup.rs
[4]:https://docker.com
[5]:https://docs.docker.com/engine/reference/commandline/build/
[6]:https://github.com/rust-lang/cargo
[7]:https://github.com/rust-lang/cargo/issues/2644
[8]:https://hub.docker.com/r/library/rust/tags/
[9]:https://crates.io
[10]:https://crates.io/crates/rand
[11]:https://alpinelinux.org/
[12]:https://docs.docker.com/develop/develop-images/multistage-build/
[13]:https://hub.docker.com/_/alpine/
[14]:https://www.musl-libc.org/
[15]:https://en.wikipedia.org/wiki/Ldd_(Unix)
[16]:https://en.wikipedia.org/wiki/Principle_of_least_privilege
[17]:https://doc.rust-lang.org/rustc/targets/built-in.html
[18]:https://github.com/shaneutt/dcos-k8s-rust-skaffold-demo
[19]:https://kubernetes.io
[20]:https://kubernetes.io/docs/setup/minikube/
[21]:https://github.com/GoogleContainerTools/skaffold
