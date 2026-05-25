# Scheduler and Disruption Policy Review

> **Public release rewrite note:** This file was rewritten with public-safe cluster, realm, DNS, path, and IP placeholders. It preserves the platform design intent but is not a live deployment inventory.

**Reference Architecture Environment**  
**Version:** 1.5  
**Date:** May 22, 2026

## Executive Summary

This pass tightens Kubernetes scheduling and voluntary disruption behavior across the multi-cluster platform. The goal is straightforward: spread replicated workloads across nodes where it matters, avoid accidental hard scheduling deadlocks, and keep `kubectl drain` / node maintenance from turning into a platform outage.

The corrected posture is:

| Workload area | Scheduling policy | Disruption policy |
| --- | --- | --- |
| Rocket.Chat core | Soft pod anti-affinity by hostname | Main deployment `minAvailable: 3` for four baseline replicas |
| Rocket.Chat microservices | Soft pod anti-affinity by service | Explicit PDBs with `maxUnavailable: 1` |
| Contour control plane | Soft anti-affinity plus hostname topology spread | Explicit PDB with `maxUnavailable: 1` |
| Envoy ingress data plane | DaemonSet placement | No PDB; DaemonSet/node lifecycle handles placement |
| NATS | Hostname topology spread | PDB enabled, `maxUnavailable: 1` |
| Keycloak realms | Hard pod anti-affinity retained, topology spread added | Explicit PDB with `maxUnavailable: 1` |
| PostgreSQL singletons | No artificial PDB | Single-replica databases must remain drain-able; HA requires a separate database HA design |
| Prometheus / Alertmanager / Grafana singletons | No artificial PDB | Single-replica monitoring services should not block node maintenance |
| MongoDBMultiCluster members | One member per Kubernetes cluster | Do not add per-cluster singleton PDBs; resiliency comes from the multi-cluster replica set |

## Why this changed

The previous Rocket.Chat PDB used `minAvailable: 4` while the baseline replica count was also `4`. That prevented voluntary disruption of even one healthy pod. It looked resilient, but operationally it blocked maintenance.

The platform now uses `maxUnavailable: 1` or equivalent drain-safe budgets for replicated stateless services. Singletons intentionally do **not** get PDBs because a PDB on one replica usually blocks node drains without improving availability.

## Implementation Notes

### Rocket.Chat

- Main application anti-affinity is now preferred instead of required.
- Main application PDB allows one voluntary disruption.
- Microservice PDBs were added for `ddp-streamer`, `presence`, `account`, `authorization`, and `stream-hub`.

### Contour

- `contour.pdb.maxUnavailable: 1` is explicit in all platform-ingress, restricted-ingress, federated-realm, and enterprise-realm ingress values.
- Hostname topology spread is configured for the replicated Contour control-plane pods.
- Envoy remains a DaemonSet and is not given a PDB.

### NATS

- The NATS StatefulSet uses chart-native `podTemplate.topologySpreadConstraints` by hostname.
- The chart-native PDB remains enabled.

### Keycloak

- Three-instance Keycloak realms retain host-level anti-affinity.
- Hostname topology spread was added to the Keycloak CRs.
- PDBs were added to each realm resource bundle.

## Validation

Run this after deployment:

```bash
./build/monitoring/scripts/verify-scheduling-and-pdb.sh
```

Expected outcome:

- Replicated applications have PDBs.
- Single-replica stateful services do not have blocking PDBs.
- Rocket.Chat PDB no longer requires all four pods to remain available.
- Contour and NATS expose drain-safe disruption budgets.
- Keycloak realm PDBs exist and allow one voluntary disruption.
