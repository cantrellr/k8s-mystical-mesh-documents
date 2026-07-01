# K8s Mystical Mesh Public Documentation Package

```text
██╗  ██╗  █████╗  ███████╗       ███╗   ███╗ ██╗   ██╗ ███████╗ ████████╗ ██╗  ██████╗  █████╗  ██╗
██║ ██╔╝ ██╔══██╗ ██╔════╝       ████╗ ████║ ╚██╗ ██╔╝ ██╔════╝ ╚══██╔══╝ ██║ ██╔════╝ ██╔══██╗ ██║
█████╔╝  ╚█████╔╝ ███████╗       ██╔████╔██║  ╚████╔╝  ███████╗    ██║    ██║ ██║      ███████║ ██║
██╔═██╗  ██╔══██╗ ╚════██║       ██║╚██╔╝██║   ╚██╔╝   ╚════██║    ██║    ██║ ██║      ██╔══██║ ██║
██║  ██╗ ╚█████╔╝ ███████║       ██║ ╚═╝ ██║    ██║    ███████║    ██║    ██║ ╚██████╗ ██║  ██║ ███████╗
╚═╝  ╚═╝  ╚════╝  ╚══════╝       ╚═╝     ╚═╝    ╚═╝    ╚══════╝    ╚═╝    ╚═╝  ╚═════╝ ╚═╝  ╚═╝ ╚══════╝

██████╗   ██████╗   ██████╗ ██╗   ██╗ ███╗   ███╗ ███████╗ ███╗   ██╗ ████████╗ ███████╗
██╔══██╗ ██╔═══██╗ ██╔════╝ ██║   ██║ ████╗ ████║ ██╔════╝ ████╗  ██║ ╚══██╔══╝ ██╔════╝
██║  ██║ ██║   ██║ ██║      ██║   ██║ ██╔████╔██║ █████╗   ██╔██╗ ██║    ██║    ███████╗
██║  ██║ ██║   ██║ ██║      ██║   ██║ ██║╚██╔╝██║ ██╔══╝   ██║╚██╗██║    ██║    ╚════██║
██████╔╝ ╚██████╔╝ ╚██████╗ ╚██████╔╝ ██║ ╚═╝ ██║ ███████╗ ██║ ╚████║    ██║    ███████║
╚═════╝   ╚═════╝   ╚═════╝  ╚═════╝  ╚═╝     ╚═╝ ╚══════╝ ╚═╝  ╚═══╝    ╚═╝    ╚══════╝

public-safe kubernetes platform documentation package
```

This package contains public-safe documentation for the K8s Mystical Mesh platform. The documentation has been consolidated around a cluster portfolio model and a single authoritative System Design Document.

## Cluster Portfolio

The platform is organized into three enterprise cluster categories:

1. **Single multi-node cluster** — one resilient cluster for shared platform or application services.
2. **Multi multi-node clusters** — multiple resilient clusters across sites, missions, or security domains.
3. **Single-node clusters** — constrained lab, edge, demo, or disconnected validation clusters with explicit availability caveats.

## Authoritative Documents

| Document | Purpose |
| --- | --- |
| `docs/Cluster-Portfolio-Strategy.md` | Concise decision guide for choosing between single multi-node, multi multi-node, and single-node cluster patterns. |
| `docs/System-Design-Document.md` | Consolidated architecture, networking, security, storage, Rancher, RKE2, air-gap, monitoring, application, resource, scheduling, operations, and recovery reference. |

Previous standalone Markdown documents under `docs/` were integrated into the SDD to reduce drift and keep one architectural source of truth.

## Naming Standard

The package uses:

- `mgmt-cluster`
- `app-cluster-a`
- `app-cluster-b`
- `app-cluster-c`
- `single-node-cluster`
- `single-multinode-cluster`
- `site-a`, `site-b`, `site-c`
- `platform-ingress`
- `restricted-ingress`
- `platform-idp`, `federated-idp`, `enterprise-idp`
- `registry.example.internal:8443`
- `platform.example.internal`
- RFC documentation IP ranges

## Related Operational Repositories

- `cantrellr/k8s-airgap-images` — image catalog, connected pull cache, deterministic retagging, and internal registry promotion workflow.
- `cantrellr/kubeharbor` — Harbor runtime, VM/data-disk lifecycle, TLS, and offline registry deployment workflow.
- `cantrellr/rke2-node-init` — offline RKE2 node bootstrap and lifecycle automation.
- `cantrellr/k8s-mystical-mesh` — private implementation repo containing live branch-specific deployment content.

## Release Guidance

Run one final human review before publishing. The scanner removes obvious operational leakage, but diagrams, commands, and examples should still be checked by a human reviewer before release.

## Diagram Exports

Mermaid diagrams from the consolidated SDD and portfolio strategy should be included in the next diagram export refresh.
