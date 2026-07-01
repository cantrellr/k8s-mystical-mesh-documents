# Single-Node Cluster Reference

**Public-Safe Reference Architecture**  
**Version:** 1.0  
**Date:** July 1, 2026

This document provides the public-safe single-node cluster reference derived from the private lab branch. It keeps live names, addresses, and operational values out of the public documentation repo while preserving the design intent.

## Intended Use

Single-node clusters are suitable for:

- constrained labs
- development sandboxes
- edge-style experiments
- disconnected validation
- proof-of-concept deployments

They are not a substitute for a high-availability production cluster unless the business owner formally accepts the availability and data-durability limitations.

## Reference Architecture

```mermaid
flowchart TB
    subgraph Enterprise[Enterprise Services]
        IdP[Identity Provider]
        DNS[DNS]
        CA[Certificate Authority]
        Registry[Internal Registry]
        Rancher[Rancher Manager]
    end

    subgraph Node[Single Node]
        OS[Hardened OS]
        Boundary[Host Boundary]
        RKE2[RKE2 Server]
        API[Kubernetes API]
        ETCD[Embedded etcd]
        Core[Core Add-ons]
        Ingress[Ingress Plane]
        Monitor[Monitoring Agent]
        Apps[Workloads]
        LocalPV[Local Persistent Volumes]
    end

    Rancher --> API
    IdP --> Rancher
    DNS --> Node
    CA --> API
    Registry --> RKE2
    Boundary --> RKE2
    RKE2 --> API
    RKE2 --> ETCD
    API --> Core
    Core --> Ingress
    Ingress --> Apps
    Apps --> LocalPV
    Monitor --> Rancher
```

## Security Posture

```mermaid
flowchart TB
    User[Administrator] --> Auth[Central Authentication]
    Auth --> Rancher[Rancher UI]
    Rancher --> API[Kubernetes API]

    subgraph Controls[Single-Node Controls]
        HostFW[Host Firewall]
        Audit[Audit Logging]
        TLS[TLS Trust]
        PSA[Pod Security Admission]
        NetPol[NetworkPolicies]
        Secrets[Secret Protection]
        Runtime[Runtime Hardening]
        Patch[Patch Baseline]
    end

    API --> Audit
    HostFW --> API
    TLS --> API
    PSA --> Runtime
    NetPol --> Runtime
    Secrets --> Runtime
    Patch --> Runtime
```

## Local Storage Model

```mermaid
flowchart LR
    subgraph Physical[Physical or Virtual Disks]
        D1[Disk A]
        D2[Disk B]
        D3[Disk C]
    end

    subgraph Kubernetes[Kubernetes Storage]
        Mounts[Mounted Paths]
        PV[Local PersistentVolumes]
        SC[StorageClass]
        PVC[PersistentVolumeClaims]
        Pods[Stateful Workloads]
    end

    D1 --> Mounts
    D2 --> Mounts
    D3 --> Mounts
    Mounts --> PV
    SC --> PVC
    PV --> PVC
    PVC --> Pods
```

## Storage Caveat

Local persistent volumes bind workload availability to the health of the node and the local disk. That is acceptable for labs and edge-style validation, but it requires a backup, restore, and rebuild plan before stateful workloads are promoted.

## Firewall Rule Intent

```mermaid
flowchart TB
    subgraph Sources[Approved Sources]
        Admin[Admin Workstations]
        Rancher[Rancher Manager]
        Registry[Internal Registry]
        Infra[DNS Time CA]
        Users[Approved Users]
    end

    subgraph Node[Single-Node Boundary]
        AdminAccess[Managed Admin Access]
        APIAccess[Cluster API Access]
        WebAccess[Approved Web Access]
        InfraAccess[Infrastructure Services]
        Deny[Drop Unapproved Traffic]
    end

    Admin --> AdminAccess
    Rancher --> APIAccess
    Registry --> WebAccess
    Infra --> InfraAccess
    Users --> WebAccess
    AdminAccess --> Deny
    APIAccess --> Deny
    WebAccess --> Deny
    InfraAccess --> Deny
```

## Rancher Management

```mermaid
flowchart LR
    Rancher[Rancher Manager] --> Import[Import Cluster]
    Import --> Agent[Cluster Agent]
    Agent --> Inventory[Inventory and Health]
    Inventory --> RBAC[RBAC and Projects]
    Inventory --> Monitoring[Monitoring]
    Inventory --> Policy[Policy Visibility]
    Inventory --> Fleet[Fleet Targeting]
```

## Operational Gates

| Gate | Required Outcome |
| --- | --- |
| OS baseline | Hardened and patched host. |
| Network baseline | Segmented interfaces and explicit allow list. |
| Registry access | Internal registry pull path validated. |
| RKE2 baseline | Server installed with intended profile and config. |
| Storage baseline | Local disks mounted, labeled, and backed up. |
| Ingress baseline | Approved ingress path validated. |
| Rancher baseline | Cluster imported, visible, and governed. |
| Backup baseline | Restore path tested before stateful promotion. |

## Do Not Overstate This Pattern

A single-node cluster is useful, but it is not resilient. The documentation should say that plainly. The trade is cost and simplicity in exchange for a larger failure domain.
