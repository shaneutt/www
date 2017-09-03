---
title: "Why I Founded the Kubernetes AI Gateway Working Group"
date: 2025-03-24
tags:
  - kubernetes
  - ai
  - gateway-api
  - sig-network
  - networking
  - inference
  - open-source
  - governance
---

# Why I Founded the Kubernetes AI Gateway Working Group

AI is transforming networking. Not in some vague,
conference-keynote way. Right now, inference traffic is
breaking the assumptions every proxy, load balancer, and
ingress controller was built on. The Kubernetes ecosystem
needed a place to define how networking adapts. So I built
one.

## The Problem Nobody Was Solving

I have spent years on [Gateway API][gateway-api] and
[SIG Network][sig-network], watching the API mature from an
experimental sketch into the definitive standard for
Kubernetes traffic management, adopted by over 30
implementations. Gateway API's mental model is simple:
requests arrive with headers, a proxy routes, a backend
handles.

LLM inference breaks that model completely.

Models are large, expensive, and slow. Requests are
long-lived. Responses stream token by token. Instances are
not interchangeable; a server with a LoRA adapter loaded in
GPU memory is fundamentally different from one without.

The routing decisions that matter for AI cannot be made from
headers alone. The gateway must inspect the payload: which
model, what priority, whether the prompt is safe. The entire
networking stack was built to avoid exactly that.

By mid-2024, the [Gateway API Inference Extension][gie] had
started addressing model-aware routing. Valuable, but narrow
in scope: it targeted companies already running AI at scale.
The broader community needed standards for token-based rate
limiting, prompt injection guardrails, content filtering,
and egress patterns for third-party providers like OpenAI,
Vertex AI, and Bedrock. None of these had a home.

## What an AI Gateway Actually Is

An AI gateway is a network gateway implementing the Gateway
API spec with capabilities purpose-built for AI workloads.
Three core areas:

**Inference routing and model-aware load balancing.** The
gateway understands which model a request targets, which
servers have that model loaded, and factors in GPU memory,
queue depth, and request criticality. The [InferenceModel
and InferencePool CRDs][gie] introduced this pattern; the
WG builds on it.

**Payload processing.** Inspect and transform full HTTP
bodies: prompt guardrails, content filtering, semantic
routing, caching, RAG integration. The WG's [payload
processing proposal][payload-proposal] defines standards for
declarative processor configuration, ordered pipelines, and
configurable failure modes.

**Egress gateways.** Many organizations route to external AI
services and need secure, policy-controlled egress with
managed auth, token injection, regional compliance, and
provider failover. The [egress gateway
proposal][egress-proposal] addresses this.

## Building It the Kubernetes Way

Working groups require a charter, SIG sponsorship, steering
committee approval, and community consensus. The process
started on the [kubernetes-dev mailing list][mailing-list].
I presented at SIG Architecture for alignment, then
submitted [PR #8521][pr-8521]: the formal request for
wg-ai-gateway.

Two months of collaborative refinement. Reviewers pushed on
scope, governance, relationship to existing efforts. Four
steering committee members approved.

Operational pieces followed: [Slack channel][pr-8598],
[proposal template and README][pr-1],
[user stories][pr-3]. The co-organizers span five
companies. This is not a single-vendor effort.

## Why a Working Group, Not Code

wg-ai-gateway does not own production code. It makes
proposals. Discussions and specifications that, once
consensus is reached, get submitted to the relevant SIGs
for implementation.

The problems span multiple SIGs. Payload processing touches
Gateway API. Egress involves SIG Multicluster. Model-aware
routing ties to the Inference Extension under SIG Network.
A WG is the right unit for cross-cutting concerns.

The charter includes an explicit exit strategy. The WG
concludes after establishing definitions, identifying
needed API support, submitting proposals, and documenting
best practices. The goal is to solve the problem and
dissolve.

## Where This Is Going

The agentic AI wave makes this more urgent. When autonomous
agents call tools and chain actions across services, the
gateway becomes a critical control plane: enforcing
guardrails, inspecting payloads, applying defense-in-depth
before requests reach model servers.

The working group meets weekly, Thursdays at 2PM EST.
Proposals are in active development. If you work on
Kubernetes networking, AI infrastructure, or the
intersection, I want you in the room.

We are defining how AI networking works on Kubernetes. Now.

[wg-ai-gateway]: https://github.com/kubernetes-sigs/wg-ai-gateway
[gateway-api]: https://gateway-api.sigs.k8s.io/
[sig-network]: https://github.com/kubernetes/community/tree/master/sig-network
[gie]: https://gateway-api-inference-extension.sigs.k8s.io/
[payload-proposal]: https://github.com/kubernetes-sigs/wg-ai-gateway/tree/main/proposals/7-payload-processing.md
[egress-proposal]: https://github.com/kubernetes-sigs/wg-ai-gateway/tree/main/proposals/10-egress-gateways.md
[mailing-list]: https://groups.google.com/a/kubernetes.io/g/dev/c/u6I_mCRC4lE
[pr-8521]: https://github.com/kubernetes/community/pull/8521
[pr-8598]: https://github.com/kubernetes/community/pull/8598
[wg-repo]: https://github.com/kubernetes-sigs/wg-ai-gateway
[pr-1]: https://github.com/kubernetes-sigs/wg-ai-gateway/pull/1
[pr-3]: https://github.com/kubernetes-sigs/wg-ai-gateway/pull/3
