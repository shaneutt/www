---
title: "The Road to Gateway API Conformance Profiles"
date: 2023-03-15
tags:
  - kubernetes
  - gateway-api
  - conformance
  - networking
  - open-source
---

# The Road to Gateway API Conformance Profiles

Gateway API has a problem most API projects would love:
too many implementations. Over twenty projects implement
some subset of the spec. Envoy Gateway, Istio, Cilium,
Contour, Kong, NGINX, Traefik, GKE, and more all claim
Gateway API support. Great for the API design. Bad for
trust. When a user sees "Gateway API compatible," what does
that mean? Which resources? Which features? At what
correctness level?

I opened [GEP-1709][gep-1709-issue] to answer those
questions. Conformance profiles: named test groupings that
let implementations declare precisely what they support,
prove it with automated tests, and submit results upstream
for certification.

## The Trust Gap

Gateway API's predecessor, Ingress, had a trust problem.
The spec was minimal, every implementation extended it
through annotations, and users could not move between
implementations without rewriting config. "Ingress
compatible" meant almost nothing.

Gateway API was designed to avoid this. [GEP-917][gep-917]
established conformance testing early, and the [initial
conformance PR][pr-969] laid the foundation. But having a
test suite is not a certification program. Implementations could
run tests privately, pass some subset, and claim compliance
without standardized reporting. The tests existed; the trust
mechanism did not.

We needed conformance claims that were specific, verifiable,
and public.

## Designing the Profiles

The first question: what should a profile represent? Early
discussions explored organizing by conformance level or use
case. Community feedback was clear: profiles should map to
API resources.

The reasoning was practical. A UDP-only data plane should
prove conformance without being measured against HTTPRoute.
I had direct experience through [Blixt][blixt], which I
created to mature UDPRoute and TCPRoute upstream.

Two primary categories. Gateway profiles cover north-south
traffic implementations. Mesh profiles cover east-west
traffic implementations using the [GAMMA initiative
(GEP-1686)][gep-1686]. Within each, conformance scopes to
specific route types: Gateway + HTTPRoute, Mesh + HTTPRoute,
Gateway + TLSRoute, etc.

This composability was deliberate. Gateway API's value
depends on implementations adopting the parts that make
sense for their architecture without penalty for the rest.

## The ConformanceReport API

Running tests locally proves nothing to others. I designed
`ConformanceReport` as a structured API type using
kubebuilder tags. A report captures implementation name,
Gateway API version, claimed profiles, core test results,
and opted-in extended features.

The workflow: run the suite with `--conformance-profiles`,
it emits a report file. Submit that file as a PR to the
[conformance reports directory][reports-dir]. CI validates
structure, maintainers review. On merge, the implementation
appears on the [implementations page][impl-page] with
certified profiles.

Reports must be submitted exactly as generated, without
modification. If we allowed hand-editing, we would be back
to the trust problem. The "Reproduce" section lets anyone
re-run and verify.

## Badges and the Implementations Page

Implementations display conformance badges linking to the
implementations page, which is generated from submitted
reports.

This created a positive loop. Implementations want the
badge (trust signal). To get it, pass the tests. To pass,
correctly implement the spec. Conformance went from internal
quality check to visible differentiator.

## What I Learned

**Composability over completeness.** An implementation that
perfectly supports TLSRoute but not HTTPRoute is still
valuable. The profile system acknowledges heterogeneity.

**Machine-readable reports beat attestation.** Human-written
statements scale poorly and degrade. The API makes
conformance a function of test results, not prose.

## Where It Stands

Since this work began, Gateway API reached v1.0 GA and
conformance profiles became the formal certification
mechanism. Mesh conformance has been validated by Istio,
Linkerd, and Kuma. The report format continues to evolve
as the number of conformant implementations grows.

A Gateway API conformance badge now means: this
implementation was tested against this version, for these
profiles, and it passed.

[gep-1709-issue]: https://github.com/kubernetes-sigs/gateway-api/issues/1709
[gep-917]: https://gateway-api.sigs.k8s.io/geps/gep-917/
[pr-969]: https://github.com/kubernetes-sigs/gateway-api/pull/969
[blixt]: https://github.com/kubernetes-retired/blixt
[gep-1686]: https://gateway-api.sigs.k8s.io/geps/gep-1686/
[reports-dir]: https://github.com/kubernetes-sigs/gateway-api/tree/main/conformance/reports
[impl-page]: https://gateway-api.sigs.k8s.io/implementations/
