# Platform and Restricted Ingress Segmentation Design

> **Public release rewrite note:** This file was rewritten with public-safe cluster, realm, DNS, path, and IP placeholders. It preserves the platform design intent but is not a live deployment inventory.

**Reference Architecture Environment**  
**Version:** 1.5  
**Date:** May 22, 2026

## Executive Summary

The platform now separates ingress exposure into two intentionally different ingress planes:

| Plane | Namespace | IngressClass | Address space | Intended use |
| --- | --- | --- | --- | --- |
| platform-ingress | `platform-ingress` | `platform-ingress` | `198.51.100.0/24` MetalLB VIPs | Core platform, management, shared platform, and standard developer access |
| restricted-ingress | `restricted-ingress` | `restricted-ingress` | `198.51.100.0/24` restricted VIPs | Segmented workload exposure and higher-risk test paths |

This is not just naming hygiene. It gives the environment a cleaner security boundary between normal platform services and segmented traffic paths. The big win is blast-radius control: a bad route, overly broad host rule, or broken backend on `restricted-ingress` should not land on the same Envoy service or namespace as the standard `platform-ingress` ingress plane.

## Security Model

### Control Objectives

1. Keep management and standard platform ingress separate from segmented workload ingress.
2. Prevent accidental default routing into the wrong ingress controller.
3. Make application exposure explicit by requiring `spec.ingressClassName` on every Ingress or HTTPProxy.
4. Preserve independent MetalLB VIP assignment by cluster and ingress plane.
5. Keep NetworkPolicy and future WAF/policy enforcement options clean by namespace.

### Required Guardrails

- `platform-ingress` remains the only default IngressClass in the cluster.
- `restricted-ingress` must not be marked default.
- All segmented Ingress objects must explicitly set:

```yaml
spec:
  ingressClassName: restricted-ingress
```

- All standard platform Ingress objects must explicitly set:

```yaml
spec:
  ingressClassName: platform-ingress
```

Kubernetes allows only one practical default IngressClass. More than one default class causes admission ambiguity for Ingress objects that omit `ingressClassName`, so the repo now leaves `restricted-ingress` non-default by design.

## Current VIP Assignments

| Cluster | platform-ingress VIP | restricted-ingress VIP |
| --- | ---: | ---: |
| mgmt-cluster | `198.51.100.15` | `198.51.100.114` |
| app-cluster-a | `198.51.100.25` | `198.51.100.124` |
| app-cluster-b | `198.51.100.35` | `198.51.100.134` |
| app-cluster-c | `198.51.100.45` | `198.51.100.144` |

## Operational Rules

1. Do not share one hostname across platform-ingress and restricted-ingress unless the DNS split-horizon behavior is deliberate and documented.
2. Prefer clear segmented names such as `app-cluster-a-restricted.platform.example.internal` or a future `restricted-ingress.platform.example.internal` suffix for segmented ingress routes.
3. Keep Kiali, Grafana, Prometheus, Alertmanager, and other control-plane services on `platform-ingress` unless there is a hard requirement to expose them through `restricted-ingress`.
4. Treat `restricted-ingress` as a more constrained ingress plane. It should get stricter policy first, not last.
5. Add NetworkPolicies by namespace, not by wishful thinking. Namespace separation only becomes real security when policy enforcement follows.

## Validation Commands

```bash
for ctx in mgmt-cluster app-cluster-a app-cluster-b app-cluster-c; do
  echo "--- ${ctx} ---"
  kubectl --context "${ctx}" get ingressclass
  kubectl --context "${ctx}" get svc -n platform-ingress
  kubectl --context "${ctx}" get svc -n restricted-ingress
  kubectl --context "${ctx}" get ingress -A
  kubectl --context "${ctx}" get httpproxy -A 2>/dev/null || true
done
```

Expected result:

- `platform-ingress` exists and may be default.
- `restricted-ingress` exists and is not default.
- platform-ingress services use the `198.51.100.x` VIPs.
- restricted-ingress services use the `198.51.100.x` VIPs.
- Every exposed object has an explicit ingress class.
