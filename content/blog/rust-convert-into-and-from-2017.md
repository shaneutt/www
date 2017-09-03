+++
date = "2017-01-12T14:34:10-04:00"
title = "Rust - std::convert::Into and std::convert::From"
categories = ["programming", "rust"]
tags = ["rust"]

+++

I've been spending time recently learning the <a href="https://www.rust-lang.org/">Rust Programming Language</a> by writing a <a href="https://github.com/shaneutt">Riak Client</a> using <a href="https://docs.basho.com/riak/kv/latest/developing/api/protocol-buffers/">Riak's Protocol Buffers API</a>.

Through <a href="https://doc.rust-lang.org/book/ownership.html">Ownership</a> &amp; <a href="https://doc.rust-lang.org/book/references-and-borrowing.html">Borrowing</a> Rust enables safety that generally comes at the cost of flexibility. Through features like <a href="https://doc.rust-lang.org/book/traits.html">Traits</a> Rust is able to give some flexibility back to the programmer.

Some traits I've started to use recently include <a href="https://doc.rust-lang.org/std/convert/trait.Into.html">std::convert::Into</a> and <a href="https://doc.rust-lang.org/std/convert/trait.From.html">std::convert::From</a>.

When the Into trait is applied to a type, it allows it to consume itself to convert to another type.

The <a href="https://doc.rust-lang.org/std/string/struct.String.html">String</a> type provides conversion into Vec&lt;u8&gt;:
<pre class="lang:rust decode:true ">fn is_hello&lt;T: Into&lt;Vec&lt;u8&gt;&gt;&gt;(s: T) {
   let bytes = b"hello".to_vec();
   assert_eq!(bytes, s.into());
}

let s = "hello".to_string();
is_hello(s);</pre>
One of the things I've been striving for while writing the Rust Riak Client has been clean interfaces where a Vec&lt;u8&gt; is ultimately needed under the hood, but I want to make it easy for the end-users to provide string types where applicable.

By using Into in a <a href="https://doc.rust-lang.org/beta/book/generics.html">Generic</a> one can make a very flexible interface to provide a Vec&lt;u8&gt;:
<pre class="lang:rust decode:true">fn myfunc&lt;T: Into&lt;Vec&lt;u8&gt;&gt;&gt;(data: T) {
   // ...
}</pre>
This function can now take String, &amp;String, &amp;str making the conversion of a string type to bytes (for the purposes of sending via TCP to Riak) a matter of function definition, which is super sleek.

I really enjoy writing code in Rust. I expect I'll have a lot more write-ups to come as I discover things and learn better ways to do things I had already been doing.

If you've never checked out rust, try the <a href="https://play.rust-lang.org/">Rust Playground</a>!

Happy coding!
