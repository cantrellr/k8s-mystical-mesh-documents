# Configuration Baseline

> **Public release rewrite note:** This file was rewritten with public-safe cluster, realm, DNS, path, and IP placeholders. It preserves the platform design intent but is not a live deployment inventory.

**Reference Architecture Environment**
**Version:** 1.5
**Date:** May 22, 2026

This document is the canonical baseline for current deployment defaults in this repository.

## Capacity Baseline (3k-5k Continuous Users)

### Ingress and Edge

- Contour values (`contour-values-v4.yaml`, `reference-ingress-values-v5.yaml`, `federated-realm-ingress-values-v4.yaml`, `enterprise-realm-ingress-values-v4.yaml`) now default to:
  - `contour.replicaCount: 3`
  - explicit `contour.resources` and `envoy.resources`

### Rocket.Chat

- `build/sites/all/values/rocketchat-microservices-values-v2.yaml` defaults:
  - `replicaCount: 4`
  - `minAvailable: 4`
  - microservices (`presence`, `ddpStreamer`, `account`, `authorization`, `streamHub`) each `replicas: 3`
- `build/sites/all/resources/rocketchat-resources-v5.yaml` includes 6 HPAs:
  - `rocketchat-rocketchat-hpa`
  - `rocketchat-ddp-streamer-hpa`
  - `rocketchat-presence-hpa`
  - `rocketchat-account-hpa`
  - `rocketchat-authorization-hpa`
  - `rocketchat-stream-hub-hpa`

### Keycloak

- All install-referenced Keycloak CRs (`keycloak-cr-*-v3.yaml`) default to:
  - `instances: 3`
  - requests: `cpu: "1"`, `memory: 2Gi`
  - limits: `cpu: "2"`, `memory: 4Gi`

### MongoDB / Ops Manager

- `mongodb-rocketchat-replicaset-https-v2a.yaml`:
  - per application cluster `members: 2`
  - secondary vote configuration added (`votes: 0`)
  - increased MongoDB agent/database resources
- `mongodb-opsmanager-https-v2.yaml`:
  - `replicas: 2`
  - application database `members: 5`

### Monitoring

- Prometheus values include explicit CPU limits:
  - mgmt-cluster: `cpu: 6`
  - application clusters: `cpu: 2`

### Trident Protect

- `trident-protect-values-v1.yaml` includes explicit resources for:
  - `controller.resources`
  - `jobResources.defaults`

## Resource Baseline Accounting (CPU/Memory)

This section converts current defaults into deployment-level resource totals.

Assumptions used for totals:

1. CPU is reported in cores (`1000m = 1 CPU`) and memory in Gi (`1024Mi = 1Gi`).
2. Keycloak subtotal assumes all four install-referenced CRs are active (`enterprise-idp`, `federated-idp`, `platform-idp`).
3. Ingress Envoy is a DaemonSet; subtotal below uses a minimum of one Envoy pod per cluster (4 total).
4. Trident Protect job resources are bursty; subtotal includes one concurrent job as a planning baseline.
5. 5k-user target is modeled by scaling Rocket.Chat services to current HPA maximums while keeping non-HPA components at baseline.

### Minimum Baseline Subtotals (3k-Ready Deployment)

| Workload Tier | Scale Assumption | Requested CPU | Requested Memory | Limit CPU | Limit Memory |
| --- | --- | --- | --- | --- | --- |
| Ingress (Contour) | 3 replicas x 4 clusters | 3.00 | 4.5Gi | 12.00 | 12Gi |
| Ingress (Envoy DaemonSet minimum) | 1 pod x 4 clusters | 2.00 | 2Gi | 8.00 | 6Gi |
| Rocket.Chat (main + microservices) | base replicas in values | 5.50 | 15.5Gi | 20.00 | 31Gi |
| Keycloak | 4 deployments x 3 instances | 12.00 | 24Gi | 24.00 | 48Gi |
| MongoDB + Ops Manager | multicluster + opsmanager replicas | 8.80 | 23Gi | 32.00 | 64Gi |
| Monitoring (Prometheus only) | 1 manager + 3 application clusters | 1.90 | 7Gi | 12.00 | 18Gi |
| Mongo Express | 1 pod x 4 clusters | 0.40 | 0.5Gi | 2.00 | 2Gi |
| Trident Protect | controller + 1 concurrent job | 1.25 | 2.5Gi | 6.00 | 10Gi |
| **Grand Total (minimum baseline)** | all tiers combined | **34.85** | **79Gi** | **116.00** | **191Gi** |

### Additional Resources Needed to Reach Full 5k Users

Only Rocket.Chat tier scales materially in current defaults (via HPA max values in `rocketchat-resources-v5.yaml`).

| Tier | Requested CPU Delta | Requested Memory Delta | Limit CPU Delta | Limit Memory Delta |
| --- | --- | --- | --- | --- |
| Rocket.Chat scale-up (base -> HPA max) | +16.50 | +58.5Gi | +72.00 | +117Gi |

### Grand Totals for Full 5k User Capacity

| Capacity Target | Requested CPU | Requested Memory | Limit CPU | Limit Memory |
| --- | --- | --- | --- | --- |
| Minimum baseline (3k-ready) | 34.85 | 79Gi | 116.00 | 191Gi |
| Full 5k capacity target | 51.35 | 137.5Gi | 188.00 | 308Gi |

Recommended planning headroom for stable operations at 5k is at least 20% above requests:

- Recommended allocatable CPU: ~61.6 cores
- Recommended allocatable memory: ~165Gi

Notes:

- If Envoy runs on every worker node (typical DaemonSet behavior), increase totals by `0.5 CPU / 512Mi request` and `2 CPU / 1536Mi limit` per additional Envoy pod beyond the 4-pod minimum assumption.
- Ops Manager application DB resources are not explicitly pinned in active spec; totals above include explicit resources found in active container specs only.

## Security and Network Baseline

### Network Segmentation

- Namespace-specific NetworkPolicies are maintained for:
  - Rocket.Chat
  - MongoDB
  - NATS
  - Monitoring
  - Keycloak (including `enterprise-idp`, `federated-idp`, and `platform-idp`)
- Default deny template remains at:
  - `build/sites/all/resources/networkpolicy-default-deny-template.yaml`

### Security Context Hardening

- Rocket.Chat microservice security contexts are explicit and non-root:
  - `allowPrivilegeEscalation: false`
  - `runAsNonRoot: true`
  - `capabilities.drop: [ALL]`
  - `seccompProfile.type: RuntimeDefault`

### Security Hardening Automation

- Hardening workflow:
  - `build/install/stigs/deploy-security-hardening.sh`
- Namespace labeling/default-deny rollout expanded to include:
  - `monitoring`
  - `keycloak`
- Script now checks namespace existence before applying default deny policies.

## Known Remaining Hardening Items

The following are not yet defaulted in this repo baseline:

1. NATS transport TLS is enabled in `build/sites/all/values/nats-cluster-values-v3.yaml` for client and cluster route traffic.
2. Explicit mesh-wide `PeerAuthentication` strict mTLS policy manifests are not yet codified in `build/sites`.
3. Pod Security Admission labels are still mostly commented in installer scripts.

## Validation Quick Checks

```bash
# Rocket.Chat baseline
rg -n "replicaCount: 4|minAvailable: 4|replicas: 3" build/sites/all/values/rocketchat-microservices-values-v2.yaml

# Keycloak baseline
rg -n "instances: 3|memory: 2Gi|memory: 4Gi" build/sites/all/resources/keycloak-cr-*-v3.yaml

# Contour baseline
rg -n "replicaCount: 3" build/sites/**/values/*ingress-values-v*.yaml build/sites/**/values/contour-values-v4.yaml

# Network policies
kubectl get networkpolicy -A
```

## May 22, 2026 Version 1.5 Baseline Addendum

### Ingress Boundary Update

- `platform-ingress` and `restricted-ingress` are separate ingress planes with separate namespaces, IngressClasses, and MetalLB VIPs.
- `restricted-ingress` is intentionally **not** a default IngressClass.
- All Ingress and HTTPProxy objects must explicitly target the intended ingress plane.
- Control-plane services such as Grafana, Prometheus, Alertmanager, and Kiali stay on `platform-ingress` unless a segmented exposure is explicitly approved.

### Monitoring Baseline Update

- Grafana uses dedicated PostgreSQL in the `monitoring` namespace.
- Prometheus and Alertmanager use their native storage models; they are intentionally not moved to PostgreSQL.
- Kiali reaches central Grafana and Prometheus through routable `platform.example.internal` HTTPS endpoints, not cross-cluster `.svc` DNS.
- Kiali uses a Grafana service-account token stored in the `kiali-grafana-credentials` Secret in each cluster's `istio-system` namespace.

### Resource Boundary Update

- All directly managed workload manifests now include resources for containers and initContainers.
- Keycloak CA truststore init containers have explicit CPU/memory requests and limits.
- Chrony host-prep init container has explicit CPU/memory requests and limits.
- PostgreSQL volume-permission init jobs have explicit CPU/memory requests and limits.
- Prometheus central TSDB now has both time and size retention controls to avoid filling the PVC during compaction/WAL bursts.


### Scheduler and Disruption Policy Update

- Rocket.Chat main deployment now permits one voluntary disruption instead of requiring all four replicas to remain available.
- Rocket.Chat microservices have explicit PDBs with `maxUnavailable: 1`.
- Contour control-plane deployments have explicit hostname topology spread and `maxUnavailable: 1` PDB posture.
- NATS uses chart-native hostname topology spread and keeps its `maxUnavailable: 1` PDB.
- Keycloak realms retain host anti-affinity, add topology spread, and now include explicit realm PDBs.
- Single-replica PostgreSQL, Prometheus, Grafana, and Alertmanager components intentionally do not receive PDBs until redesigned for HA.

See `docs/Scheduler-and-Disruption-Policy-Review.md`.

### Performance Defaults Added

- PostgreSQL debug image logging is disabled for the Keycloak and Grafana PostgreSQL releases.
- Prometheus central storage uses explicit `walCompression: true` and `retentionSize: 120GB` against the 150Gi PVC.
- Custom Kiali dashboard discovery uses `auto` with a threshold to avoid excessive dashboard-discovery overhead.
