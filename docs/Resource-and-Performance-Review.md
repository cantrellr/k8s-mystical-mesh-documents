# Resource and Performance Review

> **Public release rewrite note:** This file was rewritten with public-safe cluster, realm, DNS, path, and IP placeholders. It preserves the platform design intent but is not a live deployment inventory.

**Reference Architecture Environment**  
**Version:** 1.5  
**Date:** May 22, 2026

## Executive Summary

The repo is in much better shape than the first monitoring pass, but there were still several maturity gaps that would show up under rebuild pressure or higher concurrency:

1. `restricted-ingress` ingress controllers were marked as default, creating ingress-class ambiguity.
2. Kiali still used cross-cluster `.svc` DNS for central Prometheus/Grafana in the uploaded repo.
3. Several helper/init containers had no CPU/memory boundaries.
4. PostgreSQL images had debug logging enabled.
5. Prometheus TSDB retention had no explicit size cap relative to the PVC.
6. Some alert ratios aggregated globally instead of preserving the `cluster` label.

This update fixes the tactical issues and documents the operating model.

## Resource Configuration Changes

| Area | Change | Why it matters |
| --- | --- | --- |
| Chrony DaemonSet | Added resources for `disable-timesyncd` initContainer | Avoids unbounded init container behavior during node-wide rollout |
| Keycloak CR init containers | Added CPU/memory requests/limits to CA import init containers | Prevents truststore import from being BestEffort under node pressure |
| PostgreSQL chart values | Added `volumePermissions.resources` | Prevents permission-fix init jobs from running unbounded |
| PostgreSQL chart values | Set `image.debug: false` | Reduces unnecessary log volume and runtime noise |
| Prometheus server | Added `retentionSize: 120GB` for 150Gi PVC | Keeps room for WAL/head chunks and reduces full-volume risk |
| Prometheus server | Added explicit `walCompression: true` | Makes TSDB storage posture explicit even if defaults change later |
| Kiali custom dashboards | Set discovery to `auto` with threshold `10` | Avoids unnecessary custom-dashboard discovery overhead on larger workloads |

## Performance and Reliability Changes

### Prometheus

Prometheus keeps current head data and WAL data outside compacted blocks, so disk planning cannot use the PVC size as the retention target. The central server now caps retained TSDB blocks below the PVC ceiling so there is operational headroom for WAL, checkpoints, and compaction.

### Grafana

Grafana remains backed by PostgreSQL. That is the right architecture. Do not move Prometheus or Alertmanager to PostgreSQL; they should keep their native storage models.

### Kiali

Kiali now uses routable HTTPS FQDNs for central Prometheus and Grafana instead of trying to resolve services that only exist inside the mgmt-cluster cluster DNS boundary. Kiali also uses a Grafana service-account bearer token instead of anonymous access.

### Ingress

The `restricted-ingress` Contour/Envoy plane is no longer marked as a default IngressClass. That removes an avoidable class of routing mistakes where an Ingress without `ingressClassName` could land on the wrong controller.

## Remaining Backlog

These are not blockers, but they are the next worthwhile maturity moves:

1. Add namespace-level default-deny and explicit allow policies for `platform-ingress` and `restricted-ingress` ingress namespaces.
2. Split restricted-ingress hostnames from platform-ingress hostnames instead of relying on identical FQDNs on different VIPs.
3. Add Alertmanager notification receiver config and test routing end-to-end.
4. Add Prometheus cardinality dashboards and alerts before onboarding more services.
5. Consider a future PostgreSQL HA pattern for Grafana only if Grafana becomes a real multi-user dependency.
6. Review Kiali authentication strategy; `anonymous` is acceptable for a sealed reference environment but not for shared enterprise use.

## Validation Commands

```bash
# Resource coverage check for workload manifests
python3 - <<'PY'
import pathlib, yaml
kinds={'Deployment','StatefulSet','DaemonSet','Job','CronJob'}
for p in pathlib.Path('build').rglob('*.yaml'):
    try:
        docs=list(yaml.safe_load_all(p.read_text()))
    except Exception:
        continue
    for d in docs:
        if not isinstance(d,dict) or d.get('kind') not in kinds:
            continue
        spec=d.get('spec',{})
        tpl=spec.get('template',{})
        if d.get('kind')=='CronJob':
            tpl=spec.get('jobTemplate',{}).get('spec',{}).get('template',{})
        ps=tpl.get('spec',{})
        for c in ps.get('initContainers',[])+ps.get('containers',[]):
            if 'resources' not in c:
                print(p, d.get('kind'), d.get('metadata',{}).get('name'), c.get('name'))
PY
```
