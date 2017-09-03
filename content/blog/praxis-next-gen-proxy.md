---
title: "Praxis: Why We're Building a Next-Generation Proxy for AI Workloads"
date: 2026-03-15
tags:
  - praxis
  - proxy
  - ai
  - inference
  - rust
  - pingora
  - kubernetes
  - gateway-api
  - networking
  - architecture
---

# Praxis: Why We're Building a Next-Generation Proxy for AI Workloads

I have spent years working with proxies. As a SIG Network
Technical Lead and Gateway API maintainer, I have pushed
Envoy, HAProxy, and nginx into places their designers never
anticipated. Benchmarked them head to head, profiled hot
paths, investigated bottlenecks, etc.

One conclusion became inescapable: the proxies we rely on
were not designed for AI traffic patterns. They can be
adapted, but adaptation has limits. Praxis is what happens
when you stop adapting and start designing for AI workloads
from first principles.

## The Problem Is Structural

Traditional proxies were built for web traffic. Short-lived
connections, small payloads, stateless request/response.
Buffer management, load balancing algorithms, filter chains:
all assume a request arrives and completes in milliseconds.

AI inference violates every one of those assumptions. A
single LLM query streams tokens for minutes over a
persistent connection. Response payloads dwarf requests. The
decode phase is sequential and memory-bound. Sessions are
stateful (KV cache in GPU memory). A single request can
saturate a GPU.

I have seen it firsthand. Envoy exhibits a ~1,500x latency
increase when payload sizes grow from 3KB to 3MB. Not a
tuning problem; structural, rooted in how the write path
handles large buffers. The Envoy/HAProxy comparison and
io_uring evaluation showed the same pattern: these proxies
optimize for stateless because that was the world they were
built for.

## What AI Traffic Needs

Working on the Gateway API Inference Extension, the AI
Gateway WG, and llm-d's networking stack taught me what
proxies need to become.

**Payload processing.** Traditional proxies treat payloads
as opaque bytes. AI workloads require the data plane to
parse request bodies for model names, inspect prompts for
guardrails, transform payloads for RAG, cache responses
by semantic content. I authored the payload processing
proposal for the AI Gateway WG because this capability does
not exist in any shipping proxy. Body-based routing is the
basic version; production needs far more.

**Streaming-native architecture.** LLM inference produces
SSE streams running for minutes. Bidirectional streaming for
multi-turn conversations, voice agents, real-time
transcription demands persistent connections with
simultaneous bidirectional data flow. A proxy built for
streaming handles backpressure, partial reads, and
connection lifecycle differently than one where streaming
was bolted onto request/response.

**Model-aware routing.** Round-robin assumes
interchangeable backends. For inference, each backend
carries unique state: KV cache, LoRA adapters, queue depth.
KV-cache-aware routing has demonstrated 87% cache hit rates
and 88% TTFT improvements. No hardware compensates for
sending requests to the wrong backend.

## Why Praxis

Praxis is a high-performance, security-first proxy
purpose-built for AI and cloud-native workloads. Written in
Rust, built on Cloudflare's Pingora framework, designed from
day one for these traffic patterns.

Pingora was built to replace nginx after hitting the same
walls: C memory safety, process-model limitations preventing
connection pool sharing, extensibility constraints.
Multi-threaded async Rust, 70% less CPU and 67% less memory
than nginx under equivalent load, over 40 million RPS in
production.

But Pingora is a framework, not an AI proxy. Praxis adds
the domain layer: filter and extension architecture for
payload inspection/transformation, first-class streaming,
model-aware routing primitives, security hardening for AI
workloads. TLS built-in, a Kubernetes operator, and
configuration for inference serving topologies.

## The Agentic Dimension

As Architect of [MCP Gateway] I have been designing the
networking layer for agentic AI. Agents fan out concurrent
requests to models, tools, and data sources, each with
different latency, security policies, and failure modes.
MCP and A2A protocols are standardizing agent communication,
but the proxy layer must be prepared to handle it.

This is not something you bolt onto an existing proxy. The
security model, connection lifecycle, and observability
requirements are different. Praxis is designed with these
patterns from the start.

## Where Praxis Fits

Praxis does not aim to replace Envoy, ztunnel, or any proxy
wholesale.

Praxis takes a lesson from other proxies: design for a specific
domain. Where ztunnel is purpose-built for L4 mesh security,
Praxis is purpose-built for AI data plane processing: payload
inspection, streaming management, model-aware routing.

## Looking Forward

The proxy landscape is undergoing a generational shift. Rust
replacing C/C++ in production networking. Purpose-built
proxies replacing monolithic ones. AI workloads demanding
fundamentally new architectures.

Praxis is open source under MIT. It reflects everything I
have learned building proxy infrastructure: Gateway API,
Ambient Mesh, llm-d, the AI Gateway WG. AI traffic patterns
are intensifying as models grow, agents become autonomous,
and inference dominates data center workloads.

We need proxies designed to _thrive_ in the AI Era, not
adapted to _survive_ in it.

Praxis is at [github.com/praxis-proxy/praxis](https://github.com/praxis-proxy/praxis).

[MCP Gateway]: https://github.com/kuadrant/mcp-gateway
