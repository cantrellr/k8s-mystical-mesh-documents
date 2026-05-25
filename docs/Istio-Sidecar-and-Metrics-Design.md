# Istio Sidecar and Metrics Design

> **Public release rewrite note:** This file was rewritten with public-safe cluster, realm, DNS, path, and IP placeholders. It preserves the platform design intent but is not a live deployment inventory.

**Reference Architecture Environment**  
**Version:** 1.5  
**Date:** May 22, 2026

## Design decision

The mesh data plane should be attached only to workloads that need Istio traffic management, identity, mTLS, and telemetry. Platform/control-plane namespaces should not be namespace-wide injected by default.

For this repo, the target model is:

| Namespace / workload | Sidecar policy | Reason |
|---|---:|---|
| `rocketchat` application pods | Injected | Application traffic should be visible in Kiali and Istio telemetry. |
| Keycloak pods | Explicit pod-level injection | Keycloak is an application workload, but its namespaces also contain platform dependencies, so pod-level injection is safer than namespace-wide injection. |
| Istio east-west gateways | Injected by the gateway chart | Gateway workloads are part of the Istio data plane; do not namespace-inject all of `istio-system`. |
| `istio-system` control-plane pods | Not injected | istiod, Kiali, and operators are control-plane components, not app workloads. |
| `monitoring` | Not injected | Prometheus/Grafana/Alertmanager observe the mesh; they should not become mesh workload noise unless secure mTLS scraping is intentionally designed. |
| `metallb-system` | Not injected | MetalLB is infrastructure and already exposes metrics through ServiceMonitor. |
| `nats-system` | Not injected | NATS clustering uses its own protocol and chart-native exporter/PodMonitor. |
| `mongodb` / `mongodb-operator` | Not injected | MongoDB uses operator-managed TLS, service discovery, and database-specific monitoring. |
| Contour/Envoy ingress namespaces | Not injected | These are L7 ingress controllers and are intentionally separated from Istio sidecar data plane. |

Istio revision-based injection should use `istio.io/rev`; avoid mixing it with legacy `istio-injection` labels because label precedence can cause surprising results.

## Monitoring design

Prometheus Agent runs in every cluster and remote-writes to the central mgmt-cluster Prometheus server. The agents select ServiceMonitor and PodMonitor resources across namespaces.

The repo now monitors:

- Kubernetes core metrics through kube-state-metrics, node-exporter, kubelet, and cAdvisor.
- Istio control plane through the `istiod` ServiceMonitor.
- Istio gateway metrics through `/stats/prometheus` on the gateway metrics port.
- Istio sidecar proxy metrics through a PodMonitor selecting injected pods with `security.istio.io/tlsMode=istio`.
- Rocket.Chat through its chart-native PodMonitor.
- NATS through its chart-native Prometheus exporter PodMonitor.
- MetalLB through chart-provided ServiceMonitors enabled after monitoring CRDs exist.
- MongoDB operator metrics through an explicit ServiceMonitor.
- Keycloak through its Keycloak CR `serviceMonitor` setting.

MongoDB database/member metrics are separate from MongoDB operator metrics. The MongoDB CR has a commented `spec.prometheus` section; enable that only when you are ready to expose MongoDB database metrics with the required credentials and ServiceMonitor wiring.

## Validation

Run:

```bash
./build/monitoring/scripts/verify-istio-sidecars-and-metrics.sh
```

Expected high-level result:

- `monitoring`, `metallb-system`, `nats-system`, `mongodb`, and `mongodb-operator` should not have ordinary `istio-proxy` sidecars.
- `istio-system` should not sidecar-inject Kiali or istiod. Istio gateways are the exception.
- Application workloads such as Rocket.Chat and Keycloak should have sidecars when the related deployment is enabled.
- `servicemonitor` and `podmonitor` objects should exist for the platform components listed above.

## Operational notes

Do not solve observability gaps by mesh-injecting every namespace. That creates noisy telemetry, harder upgrades, extra CPU/memory overhead, and more failure coupling. Use explicit ServiceMonitor and PodMonitor objects for infrastructure, and reserve sidecars for workloads that actually benefit from the mesh.

## Known observability backlog

The current package fixes mesh sidecar placement and Prometheus discovery. Two deeper database telemetry items are intentionally called out instead of being hidden:

1. **PostgreSQL database internals**: the current `dhi-postgresql` chart does not include a postgres-exporter sidecar or metrics service. Kubernetes-level pod/PVC metrics are covered, but database-level metrics such as connection counts, locks, cache hit ratio, and slow query indicators require adding a PostgreSQL exporter pattern to the chart or deploying a separate exporter per database.
2. **MongoDB replica/member internals**: MongoDB operator metrics are now scraped. MongoDB database metrics require enabling the MongoDB CR `spec.prometheus` block and creating the matching ServiceMonitor/credentials for the MongoDB exporter endpoint.

Those two items are the remaining gap between "platform-monitored" and "database-internals-monitored." Do not solve either by injecting sidecars; use database-native exporters.
