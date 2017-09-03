---
title: "Rust - Coveralls.io for Rust"
date: 2017-04-11
tags:
  - rust
---

While looking for a way to provide code coverage with [coveralls.io](https://coveralls.io) for Rust, I stumbled upon a solution while reading through [Iron](https://github.com/iron/iron).

The solution involves a tool called [kcov](https://github.com/SimonKagworktree/kcov) which is a Linux/OSX code coverage tester for compiled languages.

This tool can be implemented inside a `.travis.yml` file to push coverage data from a [Travis CI](https://travis-ci.org/) build.

Here is an example `.travis.yml` file:

<!-- NOTE: Original .travis.yml content was lost during Hugo goldmark migration -->

Basically all you have to do is run:

```console
./kcov-master/build/src/kcov --coveralls-id=$TRAVIS_JOB_ID --exclude-pattern=/.cargo target/kcov target/debug/riak-*
```

Changing "riak-*" for your own project, and everything before that is just to compiled kcov inside the Travis CI environment.

This configuration was used for my [Riak Rust Client](https://github.com/shaneutt/riak-rust-client).

Since the above example uses `master.tar.gz`, I recommend you fork the original repo and use your fork for stability.

Happy Coding!
