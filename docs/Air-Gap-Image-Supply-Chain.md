# Air-Gap Image Supply Chain

## Purpose

This public-safe addendum describes the image acquisition, normalization, promotion, and registry-readiness model used by the K8s Mystical Mesh platform. The core design principle is that platform deployment should consume trusted images from an internal registry, not make opportunistic pulls from public Internet registries during cluster rollout.

In an air-gapped Kubernetes environment, the image supply chain is a Tier-0 platform dependency. Missing images, inconsistent retagging, weak registry ownership, or unverified registry trust will break downstream deployment automation.

## Repository Ownership Model

| Capability | Image promotion utility | Registry lifecycle utility | Platform deployment repo |
| --- | --- | --- | --- |
| Source image catalog | Owns | References | Consumes expected output |
| Image list normalization | Owns | Does not own | Does not own |
| Connected pull workflow | Owns | Does not own | Does not own |
| Offline/internal push workflow | Owns | Delegates to registry endpoint | Consumes promoted images |
| Registry install/runtime lifecycle | Does not own | Owns | Does not own |
| TLS and client trust lifecycle | Requires working trust | Owns | Validates from nodes |
| Helm/YAML deployment | Does not own | Does not own | Owns |

This separation prevents registry installation, image movement, and application deployment from becoming one oversized script stack.

## Standard Workflow

1. **Maintain source image lists** for Kubernetes distribution components, platform add-ons, ingress, monitoring, service mesh, data services, and operational tools.
2. **Normalize and categorize image lists** into public/no-auth, authenticated registry, archived, and aggregate manifests.
3. **Pull images while connected** using explicit credentials only where required.
4. **Stage or deploy the internal registry** before platform rollout.
5. **Retag and push images** into the internal registry using a deterministic promotion mode.
6. **Validate image availability and registry trust** from the target environment before running cluster deployment scripts.

## Registry Naming Contract

The preferred promotion mode strips the upstream registry prefix and places the image under the internal registry project/namespace:

```text
docker.io/example/component:v1.0.0
  -> registry.example.internal:8443/library/example/component:v1.0.0

registry1.example.mil/namespace/component:v1.0.0
  -> registry.example.internal:8443/library/namespace/component:v1.0.0
```

A preserve-registry mode can be used when upstream path collisions are a material risk:

```text
docker.io/example/component:v1.0.0
  -> registry.example.internal:8443/library/docker.io/example/component:v1.0.0
```

Platform manifests and Helm values must use the same mapping contract as the promotion workflow. If these drift, the cluster will fail with image pull errors even when the registry is healthy.

## Pre-Deployment Gates

Before platform deployment, operators should verify:

- the image manifest count matches the expected bill of materials;
- no critical images are left in failed-pull or missing-image logs;
- the internal registry projects/namespaces exist;
- the push account has required permissions;
- the Kubernetes node runtime trusts the registry certificate chain;
- at least one representative image pull succeeds from a target node.

## Failure Modes

| Failure | Likely Cause | Corrective Action |
| --- | --- | --- |
| Image pull errors | Manifests do not match the internal registry promotion mode | Reconcile values/manifests with the promotion target mapping |
| Push denied | Account lacks project or repository permissions | Use a push-scoped account for existing projects or a project-management account for preflight |
| Project creation fails | Robot/service account cannot create registry projects | Use a registry administrator or project-management credential for preflight |
| TLS trust failure | Node runtime does not trust the registry CA | Install the CA in the runtime trust store and restart the runtime |
| Missing pushed image | Source image was skipped, failed, or normalized differently | Review pull/push logs and rerun the image workflow with the required credentials |

## Design Decision

Image promotion is handled as a separate supply-chain workflow before cluster deployment. That gives the platform a clean control point for image provenance, credential prompts, retagging, registry project reconciliation, and deployment readiness evidence.

Bottom line: production rollout should not be the first time the team discovers an image is missing. That failure class belongs in preflight, not during platform deployment.
