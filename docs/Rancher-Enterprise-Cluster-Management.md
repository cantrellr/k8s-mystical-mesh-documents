# Rancher Enterprise Cluster Management

**Public-Safe Reference Architecture**  
**Version:** 1.0  
**Date:** July 1, 2026

Rancher Manager is the enterprise control point for clusters in all three categories:

- single multi-node cluster
- multi multi-node clusters
- single-node clusters

The operating principle is simple: Rancher provides centralized visibility, access control, policy alignment, and lifecycle workflows, while each cluster still keeps its own Kubernetes API, workload runtime, and failure domain.

## Management Model

```mermaid
flowchart TB
    subgraph Enterprise[Enterprise Control Plane]
        IdP[Enterprise Identity]
        Rancher[Rancher Manager]
        Git[Git Repositories]
        Registry[Internal Registry]
        Observability[Observability Stack]
    end

    subgraph Clusters[Managed Cluster Estate]
        SMC[Single Multi-Node Cluster]
        MMC[Multi Multi-Node Clusters]
        SNC[Single-Node Clusters]
    end

    IdP --> Rancher
    Rancher --> SMC
    Rancher --> MMC
    Rancher --> SNC
    Git --> Rancher
    Registry --> SMC
    Registry --> MMC
    Registry --> SNC
    SMC --> Observability
    MMC --> Observability
    SNC --> Observability
```

## Rancher UI Operating Areas

| Area | Purpose | Enterprise Outcome |
| --- | --- | --- |
| Cluster Explorer | Inspect workloads, namespaces, nodes, storage, and events | Single pane of glass |
| Cluster Management | Register, import, upgrade, and manage clusters | Standard lifecycle control |
| Users and Authentication | Integrate enterprise identity and groups | Central access governance |
| Projects and Namespaces | Group namespaces with delegated RBAC | Cleaner ownership model |
| Apps and Charts | Deploy approved platform services | Controlled self-service |
| Monitoring | View health and capacity | Faster incident triage |
| Fleet | GitOps deployment to target clusters | Repeatable configuration |
| Security and Policy | Run scans and enforce standards | Audit-ready operations |

## Cluster Onboarding Flow

```mermaid
sequenceDiagram
    participant Owner as Cluster Owner
    participant Rancher as Rancher Manager
    participant Cluster as Downstream Cluster
    participant IdP as Enterprise Identity
    participant Git as GitOps Source

    Owner->>Rancher: Create or import cluster
    Rancher->>Cluster: Deploy cluster agent
    Cluster->>Rancher: Register health and inventory
    IdP->>Rancher: Provide users and groups
    Rancher->>Cluster: Apply RBAC bindings
    Git->>Rancher: Publish desired state
    Rancher->>Cluster: Reconcile target bundles
    Cluster->>Rancher: Report state
```

## RBAC and Ownership Pattern

```mermaid
flowchart LR
    IdP[Enterprise Identity] --> Groups[Enterprise Groups]
    Groups --> GlobalRoles[Global Roles]
    Groups --> ClusterRoles[Cluster Roles]
    Groups --> ProjectRoles[Project Roles]

    ClusterRoles --> PlatformTeam[Platform Team]
    ProjectRoles --> AppTeam[Application Team]
    ProjectRoles --> SecurityTeam[Security Team]
    GlobalRoles --> Admins[Platform Admins]

    PlatformTeam --> Clusters[Clusters]
    AppTeam --> Projects[Projects]
    SecurityTeam --> Policies[Policies]
    Admins --> Rancher[Rancher Manager]
```

## Category-Specific Use

| Cluster Category | Rancher Use | Guardrail |
| --- | --- | --- |
| Single multi-node cluster | Primary cluster lifecycle, RBAC, projects, monitoring, apps | Use HA storage and redundant ingress. |
| Multi multi-node clusters | Central estate management, Fleet targeting, cross-cluster visibility | Keep cluster labels and ownership clean. |
| Single-node clusters | Import for visibility, policy, inventory, and lifecycle awareness | Do not market as HA. Backup is mandatory. |

## Fleet Targeting Model

```mermaid
flowchart TB
    Git[Git Repository] --> Fleet[Fleet]
    Fleet --> Labels[Cluster Labels]
    Labels --> Prod[production=true]
    Labels --> Lab[lab=true]
    Labels --> Site[site=example]
    Labels --> Category[category=single-node]

    Prod --> MultiNode[Multi-Node Clusters]
    Lab --> SingleNode[Single-Node Clusters]
    Site --> SiteClusters[Site Clusters]
    Category --> CategoryBundles[Category Bundles]
```

## Lifecycle Responsibilities

| Responsibility | Rancher | Cluster Owner | Platform Team |
| --- | --- | --- | --- |
| Authentication | Owns integration point | Consumes access | Designs group model |
| Cluster import | Provides workflow | Runs registration | Validates health |
| RBAC | Enforces assignments | Requests access | Approves model |
| Monitoring | Provides views | Responds to alerts | Maintains dashboards |
| GitOps | Runs reconciliation | Owns app repos | Owns platform repos |
| Backup | Coordinates visibility | Owns cluster backup | Defines standard |
| Compliance | Surfaces scans | Remediates findings | Owns baseline |

## Documentation Provisions

Add these docs as the portfolio matures:

| Document | Purpose |
| --- | --- |
| `docs/Rancher-Cluster-Onboarding-Runbook.md` | Step-by-step import and validation. |
| `docs/Rancher-RBAC-Model.md` | Enterprise groups, roles, and delegated ownership. |
| `docs/Fleet-Targeting-Standards.md` | Label strategy and bundle targeting. |
| `docs/Cluster-Backup-and-Restore-Standards.md` | Backup expectations by cluster category. |
| `docs/Single-Node-Operations-Runbook.md` | Day-2 operations for constrained clusters. |
| `docs/Cluster-Decommissioning-Runbook.md` | Clean removal from Rancher and platform tooling. |

## Change and Removal Recommendations

- Change the current documentation package from one dominant multi-cluster narrative to a cluster portfolio narrative.
- Keep the existing multi-cluster design, but clearly label it as the multi multi-node reference.
- Add a single multi-node architecture document so smaller enterprise deployments have a clean target pattern.
- Add single-node caveats everywhere single-node clusters are discussed.
- Remove or regenerate duplicated Mermaid nodes from current exported diagrams.
- Avoid putting live hostnames, routable addresses, or private operational secrets into the public documentation repo.
