---
title: "AI Networking Topologies: How Inference Traffic Differs from Everything Else"
date: 2025-09-22
tags:
  - ai
  - networking
  - kubernetes
  - gateway-api
  - inference
  - rdma
  - architecture
---

# AI Networking Topologies: How Inference Traffic Differs from Everything Else

I have spent over a decade working on Kubernetes networking:
SIG Network leadership, Gateway API, and more recently
networking infrastructure for OpenShift. I thought I
understood traffic patterns.
Then I started designing networks for AI inference, and things
got a bit weird.

## AI Traffic Is Not Web Traffic

Traditional web services process stateless requests in
milliseconds. A load balancer picks a backend, the backend
responds, the connection closes. Every proxy, service mesh,
and ingress controller was designed around that pattern.

LLM inference violates all of those assumptions
simultaneously.

**Request/response asymmetry.** A prompt might be a few
kilobytes. The response can be orders of magnitude larger,
streamed token by token over seconds or minutes. Output
generation is 20 to 400 times slower than input processing
because the decode phase is sequential and memory-bound. A
single output token costs roughly what 100 input tokens cost
in compute. Your network has to sustain long-lived,
unidirectional streaming flows that look nothing like HTTP
request/response pairs.

**Statefulness.** An inference session is not stateless. The
model builds a KV cache during prefill (attention key/value
pairs encoding the conversation context) that lives in GPU
memory. If a follow-up request lands on a different backend,
the cache is gone and the model recomputes from scratch.
That is the difference between sub-second and multi-second
first-token latency.

**Resource intensity.** A single LLM query can saturate an
entire GPU. There is no analogy in traditional web serving.
Inference latencies range from seconds to minutes, and the
relationship between prompt size and response time is
non-linear in ways that confound capacity planning.

## Why Traditional Load Balancing Fails

Round-robin assumes backends are interchangeable. For
inference, they are not. Each backend carries unique state:
KV cache of active sessions, loaded LoRA adapters, current
queue depth. Sending a request to the wrong backend means
recomputing context or missing a cache hit.

The metrics that matter are different too. Traditional load
balancers look at connection count, CPU, or response
latency. For inference, routing quality depends on KV cache
occupancy, queue depth, time to first token, and
inter-token latency. None of these are visible to a
standard L4 or L7 proxy.

This is the problem that led to the Gateway API Inference
Extension and the AI Gateway Working Group. An inference
gateway needs to be model-aware: what model a request
targets, which backends have warm caches, what queue depth
looks like, and whether the request should go to a prefill
or decode instance.

The Inference Extension introduces InferencePool (a set of
model-serving pods with shared compute) and InferenceModel
(mapping a public model name to serving infrastructure).
The Endpoint Picker routes based on real-time model metrics
rather than generic connection counts. In the payload
processing proposal I authored for the AI Gateway WG, I
focused on gateways inspecting and transforming full
payloads for caching, semantic routing, guardrails, and RAG
integration. These capabilities do not exist in any
traditional proxy architecture.

The results: KV-cache-aware routing has demonstrated 87%
cache hit rates and time-to-first-token improvements of
88%, translating to response times up to 57x faster on
identical hardware.

## Prefill/Decode Disaggregation

A particularly consequential architectural shift in inference
serving is separating prefill and decode into independent
pools. Prefill is compute-bound: full input sequence in one
forward pass, massive FLOPS. Decode is memory-bound: tokens
generated one at a time, constrained by memory bandwidth.
Running both on the same GPU wastes whichever resource is
not the bottleneck.

Disaggregation means dedicated prefill and decode instances,
each tuned for its workload. Prefill gets high-compute GPUs.
Decode runs on hardware optimized for memory bandwidth. You
can tune time to first token without affecting inter-token
latency, and vice versa.

The networking challenge is moving the KV cache from prefill
to decode fast enough. For large models with long contexts,
the KV cache can be gigabytes per request. TCP is too slow.
You need RDMA.

## RDMA and the Inter-Node Reality

RDMA (Remote Direct Memory Access) lets one machine write
directly into another's memory without involving CPU or OS.
No context switches, no kernel overhead, no intermediate
copies. For AI workloads where GPU-to-GPU data movement is
the critical path, RDMA is a requirement, not an
optimization.

InfiniBand delivers consistent ultra-low latency and is the
standard for training clusters. RoCE (RDMA over Converged
Ethernet) runs over standard Ethernet at lower cost but
needs more careful congestion management. The Ultra Ethernet
Consortium's 1.0 spec, released mid-2025, narrows that gap
with congestion signaling designed for AI workloads.

NVIDIA's NIXL library (open-sourced at GTC 2025) handles KV
cache transfer for disaggregated inference across five
backends: RDMA/InfiniBand, RoCE via UCX, TCP fallback,
NVMe-oF, and S3-compatible object storage.

Getting RDMA right on Kubernetes is its own challenge, which
is why I initiated work on RDMA network lifecycle
management. RDMA networks need dedicated configuration,
device plugins, and careful lifecycle management beyond what
a standard CNI plugin provides.

## Topology Patterns That Work

**Separate north-south and east-west concerns.** Inference
API traffic (user requests) and inter-node GPU traffic (KV
cache transfers, collectives) have fundamentally different
characteristics. API traffic is bursty, lower bandwidth, and
needs model-aware routing. GPU traffic is sustained,
extremely high bandwidth, and needs RDMA. Different network
planes, different hardware, different protocols, different
failure domains.

**Model-aware ingress.** The gateway layer must understand
models, not HTTP paths. Route based on model identity, KV
cache locality, queue depth, and request criticality using
the Gateway API Inference Extension with real-time telemetry.

**Disaggregated serving with RDMA interconnect.** Separate
prefill and decode pools connected by RDMA fabric. Size the
ratio based on your workload: long-context, large-model
workloads benefit most. Short prompts with high prefix cache
hit rates may be better served colocated.

**Hybrid interconnect for cost efficiency.** Allocate RDMA
fabric for latency-critical KV transfers and training
collectives; run storage and management traffic on standard
Ethernet.

## The Landscape Is Moving Fast

Twelve months ago, prefill/decode disaggregation was
research. Today it is the default in every major inference
framework: vLLM, SGLang, NVIDIA Dynamo, and llm-d. The
Gateway API Inference Extension went from proposal to
multi-vendor implementation in under a year.

Building architectures that address the actual characteristics
of AI traffic is the work, and proxy technologies are at the
center of this. At least for the moment, no existing
technology seems up for the task and only time will tell how
that may change.
