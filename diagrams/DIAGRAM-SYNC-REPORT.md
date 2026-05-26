# Mermaid Diagram Sync Report

Generated: 2026-05-26
Repository: `cantrellr/k8s-mystical-mesh-documents`
Source folder: `diagrams/mermaid-source`

## Source change set analyzed

The latest Mermaid source commit changed the following diagrams:

| Diagram | Mermaid source | Summary |
| --- | --- | --- |
| 01 | `system-design-document-diagram-01.mmd` | Standardized Site/Cluster labels, added MongoDB OpsManager, adjusted external services layout. |
| 02 | `system-design-document-diagram-02.mmd` | Added monitoring-component grouping, expanded layer labels, split scrape edges. |
| 03 | `system-design-document-diagram-03.mmd` | Reorganized topology by DC1/DC2/DC3, updated cluster labels, adjusted mesh traffic ordering. |
| 05 | `system-design-document-diagram-05.mmd` | Adjusted Service Certificates subgraph spacing for better render layout. |
| 09 | `system-design-document-diagram-09.mmd` | Rebuilt MongoDB topology by Site A/B/C, added MongoDB OpsManager, removed duplicate nodes. |

## Markdown consumers updated

The update package now includes Markdown synchronization. During application, `sync-mermaid-markdown.py` scans all repository `.md` files and replaces any Mermaid block that is immediately bound to one of the changed diagram exports.

Expected Markdown/index consumers from repository search:

| File | Action |
| --- | --- |
| `docs/System-Design-Document.md` | Sync embedded Mermaid blocks for diagrams 01, 02, 03, 05, and 09 from `diagrams/mermaid-source`. |
| `diagrams/DIAGRAM-INDEX.md` | Refresh diagram links and node/edge counts from Mermaid source. |
| `diagrams/DIAGRAM-INDEX.json` | Refresh diagram node/edge counts from Mermaid source. |

## Generated assets

The following SVG and PNG files were regenerated from the latest Mermaid sources:

| Diagram | SVG | PNG |
| --- | --- | --- |
| 01 | `diagrams/svg/system-design-document-diagram-01.svg` | `diagrams/png/system-design-document-diagram-01.png` |
| 02 | `diagrams/svg/system-design-document-diagram-02.svg` | `diagrams/png/system-design-document-diagram-02.png` |
| 03 | `diagrams/svg/system-design-document-diagram-03.svg` | `diagrams/png/system-design-document-diagram-03.png` |
| 05 | `diagrams/svg/system-design-document-diagram-05.svg` | `diagrams/png/system-design-document-diagram-05.png` |
| 09 | `diagrams/svg/system-design-document-diagram-09.svg` | `diagrams/png/system-design-document-diagram-09.png` |

## Validation

- Mermaid CLI render completed successfully after using Chromium with a local content-load patch.
- SVG outputs were validated as SVG files.
- PNG outputs were validated as PNG image files.
- PNG dimensions:
  - Diagram 01: 1568 x 476
  - Diagram 02: 1568 x 424
  - Diagram 03: 1568 x 676
  - Diagram 05: 1568 x 842
  - Diagram 09: 1568 x 1076

## Operational note

This package is designed to be applied as one commit so the repository does not drift between Mermaid source, rendered image exports, and Markdown documentation consumers.
