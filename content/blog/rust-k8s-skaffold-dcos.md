+++
date = "2018-06-01T12:50:13-04:00"
categories = ["programming", "rust", "kubernetes"]
tags = ["rust", "kubernetes", "dc/os", "skaffold"]
title = "Programming - Deploying Rust Webapps on Kubernetes on DC/OS using Skaffold"

+++

Deploying Rust Webapps on Kubernetes on DC/OS using Skaffold
===

Since my last post I've joined as an engineer at [Mesosphere](https://mesosphere.com/) and have been developing data pipeline software for cluster diagnostics.

During this same time I've been deploying the software I've been working on using [Kubernetes on DC/OS](https://docs.mesosphere.com/services/kubernetes/), and I've been keeping up my interest in the [Rust](https://www.rust-lang.org), so I put together a demo of deploying webapps in Rust to Kubernetes on DC/OS using [Skaffold](https://github.com/GoogleContainerTools/skaffold):

https://github.com/shaneutt/dcos-k8s-rust-skaffold-demo

It's a step-by-step guide showing how to build a webapp in Rust using [Rocket](https://rocket.rs/) and continuously deploy your changes up to a Kubernetes cluster during development.

The guide in the repository can easily be fitted to other languages and tools, but in general Skaffold seems like a solid tool for continuous deployments during the development stages of an app.
