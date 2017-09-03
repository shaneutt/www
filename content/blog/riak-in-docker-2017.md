+++
date = "2017-02-21T14:35:52-04:00"
title = "Docker - Riak in Docker"
categories = ["systems", "docker"]
tags = ["docker", "riak"]

+++

<a href="https://basho.com/products">Riak</a> was designed to be deployed and run on dedicated infrastructure, as opposed to containers or virtualization platforms.

Nonetheless, being able to quickly deploy a Riak cluster for testing and development purposes can be very useful.

I've created a repository today that enables the user to build <a href="https://docker.com">Docker</a> images for most versions of Riak KV, TS, and CS ever produced:

<a href="https://github.com/shaneutt/riak-docker">https://github.com/shaneutt/riak-docker</a>

The <a href="https://docs.docker.com/engine/reference/builder/">dockerfile</a> is relatively simple:
<pre class="lang:sh decode:true " title="A Riak KV Dockerfile">FROM centos:7

ARG major_version

ARG minor_version

RUN yum install -y -q iproute

RUN yum install -y -q http://s3.amazonaws.com/downloads.basho.com/riak/${major_version}/${major_version}.${minor_version}/rhel/7/riak-${major_version}.${minor_version}-1.el7.centos.x86_64.rpm

ADD riak-kv-docker.sh /usr/bin/riak-docker

CMD riak-docker</pre>
The script used to start the Riak service takes care of some basic configuration and then tails the logs:
<pre class="lang:sh decode:true" title="Riak Docker Script">#!/bin/bash

# remove stale entries
sed -i '/nodename/d' /etc/riak/riak.conf
sed -i '/listener.http.internal/d' /etc/riak/riak.conf
sed -i '/listener.protobuf.internal/d' /etc/riak/riak.conf

# configure the node
IPV4=$(ip -4 addr show eth0 | grep -oP '(?&lt;=inet\s)\d+(\.\d+){3}')
NODENAME="riak@${IPV4}"
cat &lt;&lt; EOF &gt;&gt; /etc/riak/riak.conf
# Added By riak-docker
nodename = $NODENAME
listener.http.internal = $IPV4:8098
listener.protobuf.internal = $IPV4:8087
EOF

# start Riak
riak start

# trap signals
trap "riak stop" SIGTERM SIGINT

# follow the logs
tail -f /var/log/riak/* &amp;
JOB=$!

# wait for signals
wait $!</pre>
Using these images, creation of a node becomes a breeze:
<pre class="lang:sh decode:true" title="Creating a node with docker">docker run -d --name riak-kv-2-2-0-1 shaneutt/riak-kv:2.2.0</pre>
Then you can simply add enough nodes to make a five node cluster (and wait for them to come up):
<pre class="lang:sh decode:true" title="Create several nodes to create a Riak cluster">for i in $(seq 2 5); do docker run -d --name riak-kv-2-2-0-$i shaneutt/riak_kv:2.2.0; done
for i in $(seq 2 5); do docker exec riak-kv-2-2-0-$i riak-admin wait_for_service riak_kv; done</pre>
And then join all the nodes together, plan, and commit!
<pre class="lang:sh decode:true " title="Join, plan, and commit">export NODEIP=$(docker inspect riak-kv-2-2-0-1 |awk -F '"' '/"IPAddress"/{print$4}'|head -1)
for i in $(seq 2 5); do docker exec riak-kv-2-2-0-$i riak-admin cluster join riak@${NODEIP}; done
docker exec riak-kv-2-2-0-1 riak-admin cluster plan
docker exec riak-kv-2-2-0-1 riak-admin cluster commit</pre>
Now you have a Riak test environment to test your apps against, woohoo!

Happy Coding!

&nbsp;
