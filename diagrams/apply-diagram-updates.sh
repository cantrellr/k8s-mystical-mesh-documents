#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   ./apply-diagram-updates.sh /path/to/k8s-mystical-mesh-documents
#
# This applies the complete diagram sync unit:
#   1. Updated Mermaid source files
#   2. Regenerated SVG exports
#   3. Regenerated PNG exports
#   4. Markdown files that embed/reference those diagrams
#   5. Diagram index node/edge metadata

REPO_DIR="${1:-}"
if [[ -z "${REPO_DIR}" || ! -d "${REPO_DIR}/.git" ]]; then
  echo "ERROR: Provide the path to a local clone of cantrellr/k8s-mystical-mesh-documents." >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${REPO_DIR}"

mkdir -p diagrams/mermaid-source diagrams/svg diagrams/png docs

# Keep source-of-truth Mermaid files and rendered assets aligned.
cp "${SCRIPT_DIR}"/mermaid-source/system-design-document-diagram-*.mmd diagrams/mermaid-source/
cp "${SCRIPT_DIR}"/svg/system-design-document-diagram-*.svg diagrams/svg/
cp "${SCRIPT_DIR}"/png/system-design-document-diagram-*.png diagrams/png/
cp "${SCRIPT_DIR}"/DIAGRAM-SYNC-REPORT.md docs/DIAGRAM-SYNC-REPORT.md

# Update Markdown consumers and diagram index metadata from Mermaid source.
python3 "${SCRIPT_DIR}/sync-mermaid-markdown.py" "${REPO_DIR}"

git status --short

# Stage the complete sync unit, including any Markdown files the sync script touched.
git add \
  diagrams/mermaid-source/system-design-document-diagram-01.mmd \
  diagrams/mermaid-source/system-design-document-diagram-02.mmd \
  diagrams/mermaid-source/system-design-document-diagram-03.mmd \
  diagrams/mermaid-source/system-design-document-diagram-05.mmd \
  diagrams/mermaid-source/system-design-document-diagram-09.mmd \
  diagrams/svg/system-design-document-diagram-01.svg \
  diagrams/svg/system-design-document-diagram-02.svg \
  diagrams/svg/system-design-document-diagram-03.svg \
  diagrams/svg/system-design-document-diagram-05.svg \
  diagrams/svg/system-design-document-diagram-09.svg \
  diagrams/png/system-design-document-diagram-01.png \
  diagrams/png/system-design-document-diagram-02.png \
  diagrams/png/system-design-document-diagram-03.png \
  diagrams/png/system-design-document-diagram-05.png \
  diagrams/png/system-design-document-diagram-09.png \
  diagrams/DIAGRAM-INDEX.md \
  diagrams/DIAGRAM-INDEX.json \
  docs/DIAGRAM-SYNC-REPORT.md

if [[ -s .diagram-sync-updated-files.txt ]]; then
  while IFS= read -r file_path; do
    [[ -n "${file_path}" ]] && git add "${file_path}"
  done < .diagram-sync-updated-files.txt
fi
rm -f .diagram-sync-updated-files.txt

if git diff --cached --quiet; then
  echo "No changes staged. The repository is already synchronized."
else
  git commit -m "Synchronize Mermaid diagram documentation and exports"
fi
