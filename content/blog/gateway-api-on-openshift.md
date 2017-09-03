---
title: "Delivering Gateway API on OpenShift: CRD Lifecycle at Platform Scale"
date: 2024-11-15
tags:
  - kubernetes
  - gateway-api
  - openshift
  - crd-lifecycle
  - platform-engineering
  - security
---

# Delivering Gateway API on OpenShift: CRD Lifecycle at Platform Scale

As a Gateway API maintainer and SIG Network Technical Lead,
I helped build the API. As a Red Hat engineer, I then had to
ship it as a first-class platform capability on OpenShift.
These are different problems. The upstream API defines
resource shapes; the platform must decide who installs them,
who owns them, how they upgrade safely across thousands of
clusters, and what happens when they conflict.

## Why CRD Management Is a Platform Problem

Gateway API is built on CRDs. That is a strength: it
decouples from the Kubernetes release cycle. But someone has
to manage those CRDs, and at platform scale, "someone"
cannot be "the user ran `kubectl apply`."

On a managed platform, CRDs are highly-privileged,
cluster-scoped resources defining the API shape. If a CRD
version drifts from its controller, resources silently lose
fields, validation breaks, or the control plane degrades.
Helm does not handle CRD upgrades. OLM handles them better,
but Gateway API's multi-implementation relationship is more
complex than a single operator's CRDs.

The [upstream discussion][crd-discussion] captured this:
multiple implementations coexisting, each expecting different
CRD versions. The question was never "should platforms ship
these?" It was: who owns them, how do they upgrade, and what
happens when ownership changes?

I authored the [CRD Lifecycle Management enhancement][ep-1756].
The Ingress Operator owns standard-channel Gateway API CRDs
using Server-Side Apply for field-level ownership tracking.
It installs, reconciles on every sync, and prevents drift.
Experimental CRDs are blocked entirely to keep the support
surface manageable.

## The Upgrade Safety Problem

The hard part is not installation; it is upgrades. What
happens when a cluster already has Gateway API CRDs that
were not installed by the platform?

OpenShift 4.18 did not manage Gateway API CRDs. Users
installed them manually, via OLM, or through a mesh
operator. When upgrading to 4.19, the Ingress Operator
wants to own them. Blindly overwriting could downgrade
versions, remove fields workloads depend on, or conflict
with another operator.

Two mechanisms solve this.

First, a [pre-upgrade compatibility check][pr-1193] on
4.18.z clusters. Before the upgrade proceeds, existing CRDs
are validated: only standard-channel CRDs, no experimental
APIs, versions compatible with what 4.19 ships (v1.2.1). If
checks fail, `Upgradeable` is set to `False` with a clear
message.

Second, an [admin gate][pr-1196] requiring explicit
acknowledgment. Even if CRDs are compatible, the admin must
consent to platform ownership via a ConfigMap-based gate.
No "I upgraded and something unexpected changed."

## Security Policy: Topology and RBAC

Gateway API introduces primitives that do not map directly
onto OpenShift's RBAC model. I authored the [security
policy enhancement][ep-1741] and [revision][ep-1771]:

**Shared Gateway Topology.** Single load balancer serving
routes across namespaces. Mirrors OpenShift's router model.
Default. Cluster operator creates the Gateway; developers
attach HTTPRoutes.

**Dedicated Gateway Topology.** Individual load balancers per
namespace for stricter isolation.

[Aggregated ClusterRoles][pr-1206] map Gateway API
permissions onto OpenShift's admin, edit, and view roles.
Developers with edit can create HTTPRoutes. Only cluster
admins create GatewayClasses or Gateways. ReferenceGrant
restricted to cluster-admin initially.

The revision removed support for Istio's "Gateway Merging"
and "Manual Deployment" modes, which are off by default in
OSSM 3.x. Fewer deployment modes, fewer security boundaries
to reason about.

## Conclusions

Shipping an upstream API as a platform capability is a
specific discipline. Upstream optimizes for flexibility.
Platforms optimize for safety and predictability. The
tension is where the interesting engineering lives.

The pre-upgrade gate pattern will recur. Any time a platform
assumes resource ownership, you need both technical
compatibility checks and explicit human acknowledgment.

None of these pieces (CRD lifecycle, security policy,
upgrade gates, RBAC, OSSM pinning, e2e tests) are
individually glamorous. Together they represent what
shipping an API at platform scale actually takes: not
just available, but safe, predictable, and supportable
across thousands of production clusters.

[crd-discussion]: https://github.com/kubernetes-sigs/gateway-api/discussions/2655
[ep-1756]: https://github.com/openshift/enhancements/pull/1756
[ep-1741]: https://github.com/openshift/enhancements/pull/1741
[ep-1771]: https://github.com/openshift/enhancements/pull/1771
[pr-1193]: https://github.com/openshift/cluster-ingress-operator/pull/1193
[pr-1196]: https://github.com/openshift/cluster-ingress-operator/pull/1196
[pr-1206]: https://github.com/openshift/cluster-ingress-operator/pull/1206
