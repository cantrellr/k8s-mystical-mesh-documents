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

This package contains public-safe versions of the K8s Mystical Mesh documentation files. It now organizes the platform into three enterprise cluster categories:

1. **Single multi-node cluster** — one resilient cluster for shared platform or application services.
2. **Multi multi-node clusters** — multiple resilient clusters across sites, missions, or security domains.
3. **Single-node clusters** — constrained lab, edge, demo, or disconnected validation clusters with explicit availability caveats.

## Contents

- `docs/` — rewritten Markdown/TXT documentation
- `docs/Cluster-Portfolio-Strategy.md` — cluster category model and decision matrix
- `docs/Rancher-Enterprise-Cluster-Management.md` — Rancher UI and Rancher Manager enterprise operating model
- `docs/Single-Node-Cluster-Reference.md` — public-safe single-node architecture reference
- `docs/System-Design-Document.md` — multi multi-node reference architecture
- `docs/Air-Gap-Image-Supply-Chain.md` — public-safe image supply-chain and registry-promotion model
- `Resource-Baseline-Analysis-public.xlsx` — rewritten workbook
- `SANITIZATION-MAPPING.md` — source-to-public naming and IP mapping
- `PUBLIC-RELEASE-REVIEW.md` — source/output file map and review notes
- `PUBLIC-SANITIZATION-SCAN-REPORT.json` — automated scan results
- `PACKAGE-MANIFEST.json` — file hashes and package metadata

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

Run one final human review before pushing this to a public repository. The scanner removes obvious operational leakage, but diagrams, commands, and examples should still be checked by a human reviewer before release.

## Diagram Exports

Mermaid diagrams from the documentation have been exported to image files under `diagrams/`. See `diagrams/DIAGRAM-INDEX.md` for SVG, PNG, and Mermaid source references.

New Mermaid diagrams added in the cluster portfolio, Rancher management, and single-node reference documents should be included in the next diagram export refresh.
