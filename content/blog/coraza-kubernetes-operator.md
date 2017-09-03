---
title: "Coraza Kubernetes Operator: Building a Kubernetes WAF"
date: 2026-02-28
tags:
  - kubernetes
  - rust
  - security
  - waf
  - coraza
  - owasp
  - gateway-api
  - openshift
---

# Coraza Kubernetes Operator: Building a Kubernetes WAF

Earlier this month I pushed the first commit to
[coraza-kubernetes-operator][repo], a Kubernetes operator for
managing [OWASP Coraza][coraza] Web Application Firewalls
declaratively. This post covers where it came from, why I
built [Portkullis][portkullis] in Rust first, how the
operator works, and the testing and release infrastructure.

## The Gap

WAFs have been around for decades, but deploying one on
Kubernetes still involves too much glue. You bolt
ModSecurity onto an ingress controller and hope the config
stays in sync, or hand-manage sidecar proxies. Neither is
declarative. Neither integrates with [Gateway API][gwapi].
Neither gives platform teams a clean API boundary between
"what to protect" and "how to protect it."

People keep asking for it. I found two pieces
that almost fit: [Coraza][coraza], a Go-based,
ModSecurity-compatible WAF engine running the [OWASP CRS][crs]
with full SecLang support; and [coraza-proxy-wasm][proxy-wasm],
a WebAssembly filter embedding Coraza in Envoy's filter
chain. The engine existed. The enforcement mechanism existed.
The control plane was missing.

## Portkullis: Proving It in Rust

Before committing to a full operator, I needed to answer a
harder question: could a WAF do more than signature matching?
I built [Portkullis][portkullis] in Rust with two detection
engines: traditional signatures with ModSecurity rule
compatibility, and anomaly detection using ML for traffic
analysis. Rust was the natural choice: WAF inspection is
hot-path code where latency budgets are microseconds. Zero-cost
abstractions, no GC pauses, and memory safety without trading
performance for correctness.

Portkullis proved three things. First, Rust's type system
catches entire classes of parsing bugs at compile time (the
kind that become CVEs in C-based WAFs). Second, a dual-engine
architecture is viable without blowing the latency budget.
Third, the WASM compilation target means Rust detection logic
can run inside Envoy via proxy-wasm with no extra network hops.

## Operator Architecture

The [operator][repo] follows the standard Kubernetes
controller pattern with a cache layer between rule
compilation and enforcement.

**Custom Resources.** Four CRDs:

- **Engine**: declares a WAF instance bound to a Gateway.
- **RuleSet**: ordered list of rule references.
- **RuleSource**: stores SecLang rules inline or from a
  ConfigMap.
- **RuleData**: supplementary data files consumed by rules.

**Cache server.** RuleSets compile their rules and store
results in a cache. Engines poll by namespace and name,
decoupling rule authoring from enforcement. Rules update
without restarting the proxy.

**Dataplane: proxy-wasm on Envoy.** Traffic inspection
happens inside Envoy via [coraza-proxy-wasm][proxy-wasm].
On Istio, the operator creates a [WasmPlugin][wasm-plugin]
resource; the Envoy sidecar loads the filter and inspects
every inbound request before it reaches the application.
The CRS is embedded in the Wasm binary, so baseline OWASP
Top Ten protection works immediately.

This separation (operator for lifecycle, cache for
distribution, Wasm for enforcement) keeps each layer
independently testable and replaceable.

## Testing with FTW: Proving CRS Compliance

A WAF you cannot test is a WAF you cannot trust. The OWASP
[FTW][ftw] suite has over 1,500 cases exercising every CRS
rule. Each test sends a crafted HTTP request and asserts
the WAF's response.

We integrated [go-ftw][go-ftw] into CI in [PR #92][pr92].
Initially non-enforcing. [Issue #95][issue95] tracked
hardening every failing case: 33 subtasks covering false
positives from Envoy headers, timing-dependent log flushes,
multipart parsing edge cases. Each investigated, each
resolved.

The investment paid off immediately. During v0.3.0,
seemingly innocuous rule ordering changes broke detection
categories. The FTW suite caught the regressions before
review started.

## Check It Out

The [operator][repo] is open source under Apache 2.0. If
you run Istio or OpenShift and want declarative WAF
management with CRS compliance, try the Dev Preview and
[open an issue][issues].

[repo]: https://github.com/networking-incubator/coraza-kubernetes-operator
[portkullis]: https://github.com/shaneutt/portkullis
[coraza]: https://www.coraza.io/
[crs]: https://coreruleset.org/
[gwapi]: https://gateway-api.sigs.k8s.io/
[proxy-wasm]: https://github.com/corazawaf/coraza-proxy-wasm
[wasm-plugin]: https://istio.io/latest/docs/reference/config/proxy_extensions/wasm-plugin/
[ftw]: https://github.com/coreruleset/ftw
[go-ftw]: https://github.com/coreruleset/go-ftw
[pr92]: https://github.com/networking-incubator/coraza-kubernetes-operator/pull/92
[issue95]: https://github.com/networking-incubator/coraza-kubernetes-operator/issues/95
[issues]: https://github.com/networking-incubator/coraza-kubernetes-operator/issues
