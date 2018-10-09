+++
date = "2017-03-28T14:27:56-04:00"
title = "Erlang - Simple webapps in Erlang with Cowboy and ErlyDTL"
categories = ["programming", "erlang"]
tags = ["erlang"]
highlight = true

+++

Of all the programming languages I've written web applications in, Erlang is by far my favorite.

Perhaps the functional nature of Erlang, or the modular simplicity of apps and releases, or the easy primitives for concurrency make it most appealing.

Whatever the reason I've gotten in the habit of building new web applications with <a href="https://github.com/ninenines/cowboy">Cowboy</a> for the web server, and <a href="https://github.com/erlydtl/erlydtl">ErlyDTL</a> to provide <a href="https://www.djangoproject.com">Django</a>-like templates.

As such I built a <a href="https://www.rebar3.org/">Rebar3</a> template to make it easy to build these kinds of apps:

<a href="https://github.com/shaneutt/cowboy_erlydtl_rebar3_template">https://github.com/shaneutt/cowboy_erlydtl_rebar3_template</a>

To use this template with your local copy of Rebar3, simple clone the repository to the Rebar3 template directory:
<pre class="lang:sh decode:true ">git clone https://github.com/shaneutt/cowboy_erlydtl_rebar3_template ~/.config/rebar3/templates/cowboy_erlydtl_rebar3_template/</pre>
And now you can use <a href="https://www.rebar3.org/docs/commands#section-new">new</a> to build a base for your new app:
<pre class="lang:sh decode:true">rebar3 new cowboy_erlydtl your_app_here</pre>
And that's it, you should now have a base for your app deployed:
<pre class="lang:sh decode:true">your_app_here/
├── config
│   ├── sys.config
│   └── vm.args
├── Makefile
├── priv
│   ├── static
│   ├── templates
│   │   └── index.dtl
│   ├── templates-compiled
│   └── www
├── rebar.config
└── src
    ├── your_app_here_app.erl
    ├── your_app_here.app.src
    ├── your_app_here_default_router.erl
    ├── your_app_here.erl
    └── your_app_here_sup.erl</pre>
This provides a default DTL template that works right out of the box.

Just run:
<pre class="lang:sh decode:true ">cd your_app_here/
rebar3 shell</pre>
Which will start the web server on <a href="http://localhost:8080">http://localhost:8080</a>:
<pre class="lang:sh decode:true ">$ curl http://localhost:8080
Hello from Cowboy!
</pre>
And that's it, the sky is the limit!

From here you can add a Database like <a href="https://www.postgresql.org/">PostGreSQL</a> with a client like <a href="https://github.com/epgsql/epgsql">ePGSQL</a>, build your HTTP API using <a href="https://github.com/talentdeficit/jsx">JSX</a> for <a href="http://www.json.org/">JSON</a>, maybe even queue up work for another service with <a href="https://www.rabbitmq.com/">RabbitMQ</a>.

Happy coding!
