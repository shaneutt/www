+++
date = "2017-04-11T14:30:44-04:00"
categories = ["programming", "rust"]
tags = ["rust"]
title = "Rust - Coveralls.io for Rust"
highlight = true

+++

While looking for a way to provide code coverage with <a href="https://coveralls.io">https://coveralls.io</a> for Rust, I stumbled upon a solution while reading through <a href="https://github.com/hyperium/hyper">Iron</a>.

The solution involves a tool called <a href="https://github.com/SimonKagstrom/kcov/">kcov</a> which is a Linux/OSX code coverage tester for compiled languages.

This tool can be implemented inside a <strong>.travis.yml</strong> file to push coverage data from a <a href="https://travis-cs.org">Travis CI </a> build.

Here is an example <strong>.travis.yml </strong>file:
<pre class="lang:yaml decode:true" title=".travis.yml">sudo: required

language: rust

rust:
  - stable
  - beta
  - nightly

matrix:
  allow_failures:
    - rust: nightly

services:
  - docker

script:
- make test-docker-env

cache:
    apt: true
    directories:
        - target/debug/deps
        - target/debug/build

addons:
  apt:
    packages:
      - libcurl4-openssl-dev
      - libelf-dev
      - libdw-dev

after_success: |
    [ $TRAVIS_RUST_VERSION = stable ] &amp;&amp;
    wget https://github.com/shaneutt/kcov/archive/master.tar.gz &amp;&amp;
    tar xzf master.tar.gz &amp;&amp; mkdir kcov-master/build &amp;&amp; cd kcov-master/build &amp;&amp; cmake .. &amp;&amp; make &amp;&amp; make install DESTDIR=../tmp &amp;&amp; cd ../.. &amp;&amp;
    ls target/debug &amp;&amp;
    ./kcov-master/tmp/usr/local/bin/kcov --coveralls-id=$TRAVIS_JOB_ID --exclude-pattern=/.cargo target/kcov target/debug/riak-*
</pre>
Basically all you have to do is run:
<pre class="lang:sh decode:true ">./kcov-master/tmp/usr/local/bin/kcov --coveralls-id=$TRAVIS_JOB_ID --exclude-pattern=/.cargo target/kcov target/debug/riak-*</pre>
Changing "riak-*" for your own project, and everything before that is just to compiled kcov inside the Travis CI environment.

This configuration was used for my <a href="https://github.com/shaneutt/riak-rust-client">Riak Rust Client</a>.

Since the above example uses <strong>master.tar.gz</strong>, I recommend you fork the original repo and use your fork for stability.

Happy Coding!
