---
title: "Docker - Riak in Docker"
date: 2017-02-21
tags:
  - docker
  - riak
---

[Riak](https://riak.com/) was designed to be deployed and run on dedicated infrastructure, as opposed to containers or virtualization platforms.

Nonetheless, being able to quickly deploy a Riak cluster for testing and development purposes can be very useful.

I've created a repository today that enables the user to build [Docker](https://docker.com/) images for most versions of Riak KV, TS, and CS ever produced:

<https://github.com/shaneutt/riak-docker>

The dockerfile is relatively simple:

<!-- NOTE: Original Dockerfile content was lost during Hugo goldmark migration -->

The script used to start the Riak service takes care of some basic configuration and then tails the logs:

<!-- NOTE: Original start script content was lost during Hugo goldmark migration -->

Using these images, creation of a node becomes a breeze:

```console
docker run -d --name riak1 riak
```

Then you can simply add enough nodes to make a five node cluster (and wait for them to come up):

```console
docker run -d --name riak2 riak
docker run -d --name riak3 riak
docker run -d --name riak4 riak
docker run -d --name riak5 riak
```

And then join all the nodes together, plan, and commit!

```console
docker exec -it riak2 riak-admin cluster join riak1@172.17.0.2
docker exec -it riak3 riak-admin cluster join riak1@172.17.0.2
docker exec -it riak4 riak-admin cluster join riak1@172.17.0.2
docker exec -it riak5 riak-admin cluster join riak1@172.17.0.2
docker exec -it riak1 riak-admin cluster plan
docker exec -it riak1 riak-admin cluster commit
```

Now you have a Riak test environment to test your apps against, woohoo!

Happy Coding!
