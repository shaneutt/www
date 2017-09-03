---
title: "Gateway API Reaches GA: What It Took"
date: 2023-10-31
tags:
  - kubernetes
  - gateway-api
  - sig-network
  - conformance
  - open-source
---

# Gateway API Reaches GA: What It Took

Today we released [Gateway API v1.0][ga-blog]. Gateway,
GatewayClass, and HTTPRoute are now generally available.
For anyone following Kubernetes networking, that sentence
carries the weight of four years.

I co-authored the [official announcement][ga-blog]. It
covers the technical details:
what graduated, what moved to experimental, how CEL
validation replaces the webhook. This post is about the
journey.

## The Hotel Lobby in San Diego

It started at [KubeCon San Diego in 2019][kubecon-2019]. A
group of us gathered to discuss the future of Ingress. The
conversation outgrew the meeting room and spilled into a
hotel lobby across the street.

The problem was clear. Ingress had become an annotations
arms race. Every implementation extended it through
annotation keys, and any two Ingress resources were rarely
portable. We had fragmented into dozens of vendor-specific
dialects. The vision: a role-oriented, expressive, extensible
API for L4 and L7 routing. HTTP header manipulation, traffic
weighting, mirroring, TLS configuration, TCP and UDP routing.
Through proper API surface, not annotations.

## The Long Middle

The years between that lobby and today were messy,
iterative, and often slow. Building a multi-vendor API in the
open is a specific kind of hard. Every decision balances
implementations with fundamentally different architectures.
A design elegant for a cloud load balancer might be awkward
for a sidecar proxy.

We made mistakes. We changed direction. Debates dragged on
for months because once an API graduates to GA, you live
with it. Backward compatibility is a promise, and promises
are expensive if you got the shape wrong.

The [GEP process][gep] managed this complexity. Every
significant change went through a written proposal, review,
iteration, and explicit approval. It slowed us down. It also
prevented shipping things we would regret.

## Conformance: The Hardest Problem

The single most important and underappreciated piece of
Gateway API is conformance testing.

An API spec is a promise in YAML. Without verification that
implementations honor it, the spec is aspirational. We saw
this with Ingress: the spec was loose enough that
"conformant" implementations behaved wildly differently.

I spent much of the past year on [conformance profiles
(GEP-1709)][gep-1709] and the testing infrastructure. The
system lets any implementation run a standardized suite,
produce a report, and submit it for certification.
Composable (HTTPRoute without TCPRoute), versioned, with
clear tiers: Core (required), Extended (portable when
supported), Implementation-Specific (no portability
guarantee).

Before release, I landed [conformance tests for static
Gateway addresses (#2412)][pr-2412], filling a gap in
Extended feature verification. The [PartiallyInvalid condition (#2429)][pr-2429]
standardized
what happens when a Route mixes valid and invalid rules:
two permitted behaviors, a status condition to communicate
which one. That precision separates a spec from a
suggestion.

## What GA Actually Means

GA is not a finish line; it is a commitment. When we say
these resources are v1, we are saying: build on this. Deploy
it. Write tooling. We will not break you. New features arrive
through the Experimental channel and graduate when proven.

We also moved from a bundled validating webhook to [CEL
validation][cel] in the CRDs. Kubernetes 1.25+ needs no
webhook. Meaningful operational complexity reduction.

## The Community That Built It

Over [170 people][ga-blog] contributed. Over 20 as
maintainers. Dozens of organizations in the repo, in
meetings, arguing edge cases. No single company controls
the API. Maintainer roles are distributed across
organizations by design.

## What Comes Next

The Experimental channel includes [GRPCRoute][grpcroute],
HTTPRoute timeouts, BackendTLSPolicy, and GAMMA for service
mesh. These will graduate as they mature.

I am invested in conformance evolving: every new feature
needs tests, every route type needs a profile, the
certification system must scale past 20 implementations.

There is also [Blixt][blixt], a Layer 4 Gateway API load
balancer I built with Rust and eBPF. It helps mature
TCPRoute and UDPRoute by exercising those APIs and driving
conformance test development. It exists because of Gateway
API and feeds back into making it better.

## Reflection

Four years ago, a conversation overflowed a meeting room.
Today, every major cloud provider and service mesh vendor
implements the API it produced. That happens because a
community committed to the slow, unglamorous work: specs,
edge cases, test infrastructure, code review, and showing
up week after week.

I am proud of what we shipped. More proud of how: in the
open, across organizations, prioritizing getting it right
over getting it done fast.

Gateway API v1.0 is [available now][release]. The
[getting started guide][getting-started] is the best place
to begin.

[ga-blog]: https://kubernetes.io/blog/2023/10/31/gateway-api-ga/
[kubecon-2019]: https://konghq.com/blog/engineering/gateway-api-from-early-years-to-ga
[gep]: https://gateway-api.sigs.k8s.io/geps/overview/
[gep-1709]: https://gateway-api.sigs.k8s.io/geps/gep-1709/
[pr-2412]: https://github.com/kubernetes-sigs/gateway-api/pull/2412
[pr-2429]: https://github.com/kubernetes-sigs/gateway-api/pull/2429
[cel]: https://kubernetes.io/blog/2023/10/31/gateway-api-ga/
[grpcroute]: https://gateway-api.sigs.k8s.io/
[blixt]: https://github.com/kubernetes-sigs/blixt
[release]: https://github.com/kubernetes-sigs/gateway-api/releases/tag/v1.0.0
[getting-started]: https://gateway-api.sigs.k8s.io/guides/
