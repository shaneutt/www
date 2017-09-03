---
title: "Blixt: The First Rust+eBPF Gateway API Implementation"
date: 2023-09-15
tags:
  - kubernetes
  - gateway-api
  - rust
  - ebpf
  - networking
  - open-source
---

# Blixt: The First Rust+eBPF Gateway API Implementation

As a Gateway API maintainer I have worked to mature the spec
across every layer of the networking stack. Layer 7 got most
of the community's attention: HTTPRoute went GA,
implementations multiplied, conformance tests solidified.
But Layer 4 (TCPRoute and UDPRoute) remained stuck in alpha.
Not because the designs were wrong, but because nobody had
built a vendor-neutral implementation to develop and run
conformance tests against. So I built one:
[Blixt][blixt] (Swedish for "lightning"), the first
official Kubernetes project written in Rust.

## The Problem: L4 Was Stalled

Gateway API conformance testing depends on having at least
one implementation that exercises the spec. For HTTP,
several production implementations filled that role. For TCP
and UDP, nothing. No implementation, no conformance tests.
No conformance tests, no API graduation. Deadlock, persisting
over a year.

Around KubeCon Detroit in late 2022, the other maintainers
and I realized a purpose-built, non-production L4 load
balancer could break it. It did not need to compete with
production systems. It needed to be correct, vendor-neutral,
and simple enough for CI on [Kind][kind] or Minikube. That
constraint shaped every technical decision.

## Why Rust and eBPF

The dataplane needed kernel-level TCP and UDP forwarding.
eBPF was the natural choice: small programs attached to
kernel hooks without writing a kernel module, with XDP and
TC providing programmable packet processing at the earliest
points in the network stack. No userspace proxy overhead,
no complex configuration; just direct packet manipulation.

The original prototype used C for the eBPF programs. But
several contributors were experienced Rust developers
watching [Aya][aya] mature rapidly. Aya provides a
pure-Rust eBPF toolchain: Rust's type system safety,
cargo-based builds, no dependency on libbpf or C headers.
We rewrote the dataplane in Rust, and the resulting code was
substantially more maintainable than the C version.

The control plane initially used [kube-rs][kube-rs], keeping
the whole stack in Rust. We later migrated it to Go with
Operator SDK to leverage the mature Kubernetes controller
ecosystem. Pragmatic call: the control plane watches Gateway
API resources and programs eBPF maps, and Go's
controller-runtime handles watch/reconcile with less
friction. The dataplane, where Rust's performance and safety
matter most, stayed in Rust.

## Architecture

Deliberately minimal:

- **Control plane** (Go): watches GatewayClass, Gateway,
  TCPRoute, UDPRoute. Updates shared eBPF maps with backend
  configuration on route changes.
- **Dataplane** (Rust + Aya): eBPF programs via XDP and TC
  that read maps and forward matching packets. No userspace
  forwarding; packets redirect entirely within the kernel.
- **Communication**: control plane and dataplane share state
  through eBPF maps, no RPC or sidecar overhead.

Explicitly not designed for production traffic. Target
environments are Kind and Minikube, running as a DaemonSet
alongside the control plane.

## The GPL Question

Donating to Kubernetes hit an unexpected blocker. eBPF
programs calling kernel helpers are [required to be
GPL-licensed][gpl-issue]. The rest of Blixt is Apache-2.0,
but the eBPF bytecode must carry a GPL-compatible license.
The CNCF had no blanket exception for this, and Kubernetes
could not accept GPL code without one.

I worked with the CNCF and Kubernetes steering to resolve
it. The result: a [CNCF Governing Board vote][cncf-474] on
August 31, 2023, approving a blanket exception for in-kernel
eBPF programs under GPL-2.0-only or GPL-2.0-or-later. This
unblocked not just Blixt but every future CNCF project
shipping eBPF programs. Interestingly enough, this ended up
unblocking [Cilium] which had made it into CNCF with GPL
code without being noticed, and had to retroactively resolve
this.

## Donating to kubernetes-sigs

Kong donated the repository. The [migration
request][org-3875] moved `kong/blixt` to
`kubernetes-sigs/blixt` under SIG Network. The scope:

- Layer 4 Gateway API functionality (GatewayClass, Gateway,
  UDPRoute, TCPRoute).
- A sigs-owned implementation for Gateway API CI
  [conformance tests][conformance-issue].
- Reference control plane for L4 route types.

## What This Meant for Gateway API

With Blixt in `kubernetes-sigs`, Gateway API has a
vendor-neutral L4 implementation wired into CI. PRs
modifying TCPRoute or UDPRoute get conformance tests run
automatically. That feedback loop is what moved HTTPRoute
from experimental to GA; L4 needs the same machinery.

Gateway API's conformance framework, which I [designed and
built][conformance-profiles], depends on implementations
running the tests. A sigs-owned implementation removes the
dependency on any vendor's release cycle. Spec and tests
evolve together in the same CI pipeline.

## Reflections

Blixt confirmed that Rust is ready for Kubernetes
infrastructure. Aya made eBPF development genuinely
pleasant, and Rust's safety properties caught real bugs
during the C rewrite. The Kubernetes community has been a
Go monoculture for good reasons, but for dataplane work
needing zero-copy packet manipulation and kernel-level
performance, Rust is the better tool.

The project also reinforced building the right thing at the
right scope. Blixt is not Cilium or Calico. It is a test
fixture with a focused mission. That constraint made it
possible to build with a small team and donate within a
year. Sometimes the most impactful contribution is the
infrastructure that makes production systems provably
correct.

The repository is at [kubernetes-sigs/blixt][blixt]. Come
find us on [#sig-network-gateway-api][slack] on Kubernetes
Slack.

[blixt]: https://github.com/kubernetes-sigs/blixt
[kind]: https://kind.sigs.k8s.io/
[aya]: https://aya-rs.dev/
[kube-rs]: https://kube.rs/
[gpl-issue]: https://github.com/cncf/foundation/issues/474
[Cilium]: https://github.com/cilium/cilium
[cncf-474]: https://github.com/cncf/foundation/issues/474
[org-3875]: https://github.com/kubernetes/org/issues/3875
[conformance-issue]: https://github.com/kubernetes-sigs/blixt/issues/81
[conformance-profiles]: https://gateway-api.sigs.k8s.io/geps/gep-1709/
[slack]: https://kubernetes.slack.com/channels/sig-network-gateway-api
