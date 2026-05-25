# K8s Mystical Mesh Public Documentation Package

This package contains rewritten public-safe versions of the uploaded K8s Mystical Mesh documentation files.

## Contents

- `docs/` — rewritten Markdown/TXT documentation
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
- `site-a`, `site-b`, `site-c`
- `platform-ingress`
- `restricted-ingress`
- `platform-idp`, `federated-idp`, `enterprise-idp`
- `registry.example.internal:8443`
- `platform.example.internal`
- RFC documentation IP ranges

## Release Guidance

Run one final human review before pushing this to a public repository. The scanner removes obvious operational leakage, but diagrams, commands, and examples should still be checked by a human reviewer before release.


## Diagram Exports

Mermaid diagrams from the documentation have been exported to image files under `diagrams/`. See `diagrams/DIAGRAM-INDEX.md` for SVG, PNG, and Mermaid source references.
