---
title: "Rust - std::convert::Into and std::convert::From"
date: 2017-01-12
tags:
  - rust
---

I've been spending time recently learning the [Rust Programming Language](https://www.rust-lang.org/) by writing a [Riak Client](https://github.com/shaneutt/riak-rust-client) using [Riak's Protocol Buffers API](https://docs.riak.com/riak/kv/latest/developing/api/protocol-buffers/index.html).

Through [Ownership](https://doc.rust-lang.org/book/ch04-01-what-is-ownership.html) & [Borrowing](https://doc.rust-lang.org/book/ch04-02-references-and-borrowing.html) Rust enables safety that generally comes at the cost of flexibility. Through features like [Traits](https://doc.rust-lang.org/book/ch10-02-traits.html) Rust is able to give some flexibility back to the programmer.

Some traits I've started to use recently include [std::convert::Into](https://doc.rust-lang.org/std/convert/trait.Into.html) and [std::convert::From](https://doc.rust-lang.org/std/convert/trait.From.html).

When the Into trait is applied to a type, it allows it to consume itself to convert to another type.

The [String](https://doc.rust-lang.org/std/string/struct.String.html) type provides conversion into Vec<u8>:

```rust
let bytes: Vec<u8> = String::from("hello").into();
```

One of the things I've been striving for while writing the Rust Riak Client has been clean interfaces where a Vec<u8> is ultimately needed under the hood, but I want to make it easy for the end-users to provide string types where applicable.

By using Into in a [Generic](https://doc.rust-lang.org/book/ch10-01-syntax.html) one can make a very flexible interface to provide a Vec<u8>:

```rust
fn my_function<S: Into<Vec<u8>>>(input: S) {
    let bytes: Vec<u8> = input.into();
    // use bytes...
}
```

This function can now take String, &String, &str making the conversion of a string type to bytes (for the purposes of sending via TCP to Riak) a matter of function definition, which is super sleek.

I really enjoy writing code in Rust. I expect I'll have a lot more write-ups to come as I discover things and learn better ways to do things I had already been doing.

If you've never checked out rust, try the [Rust Playground](https://play.rust-lang.org/)!

Happy coding!
