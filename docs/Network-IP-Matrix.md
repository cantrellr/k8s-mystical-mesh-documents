# Network IP Matrix - Multi-Cluster Kubernetes Environment

> **Public release rewrite note:** This file was rewritten with public-safe cluster, realm, DNS, path, and IP placeholders. It preserves the platform design intent but is not a live deployment inventory.

**Reference Architecture Environment**  
**Version:** 1.5  
**Date:** May 22, 2026

For current scale/resource/security defaults, see `docs/Configuration-Baseline.md`.

---

## Table of Contents

1. [Network Port Groups](#network-port-groups)
2. [Cluster IP Allocations](#cluster-ip-allocations)
3. [Service Endpoints](#service-endpoints)
4. [Node Inventory](#node-inventory)

---

## Network Port Groups

The infrastructure uses four distinct network segments for different purposes:

| Port Group | IP Space | Description |
| ------------ | ---------- | ------------- |
| **out-of-band-mgmt** | 203.0.113.200-203.0.113.323 | Infrastructure management / lab out-of-band management services |
| **platform-net** | 192.0.2.0/24 | Kubernetes Admin, Cluster Nodes, and App Services |
| **storage-net** | 203.0.113.10-203.0.113.47 | Kubernetes Cluster Nodes for Persistent Volumes (iSCSI) |
| **restricted-ingress** | 198.51.100.128/25 | Kubernetes Cluster Nodes and App Services (Alternative Network) |

**Network Purposes:**

- **out-of-band-mgmt:** infrastructure management and lab out-of-band management services
- **platform-net:** Primary Kubernetes management and service network
- **storage-net:** Dedicated storage network for iSCSI traffic
- **restricted-ingress:** Alternative network path for redundancy and segmentation

---

## Cluster IP Allocations

### Complete Cluster Matrix

| Cluster | Site | Node IP Range | Storage IP Range | Restricted Ingress IP Range | Platform MetalLB Pool | Restricted Ingress MetalLB Pool | Platform Ingress IP | Restricted Ingress Ingress IP | Service CIDR | Pod Network CIDR |
| --------- | ------ | --------------- | ------------------ | ------------------- | --------------------- | ---------------------- | ------------------- | --------------------- | -------------- | ------------------ |
| **mgmt-cluster** | Site A | 192.0.2.10-192.0.2.19 | 203.0.113.10-203.0.113.17 | 192.0.2.110-192.0.2.119 | 198.51.100.10-198.51.100.19 | 198.51.100.110-198.51.100.119 | 198.51.100.15 | 198.51.100.114 | SERVICE-CIDR-MGMT | POD-CIDR-MGMT |
| **app-cluster-a** | Site A | 192.0.2.20-192.0.2.29 | 203.0.113.20-203.0.113.26 | 192.0.2.120-192.0.2.129 | 198.51.100.20-198.51.100.29 | 198.51.100.120-198.51.100.129 | 198.51.100.25 | 198.51.100.124 | SERVICE-CIDR-APP-A | POD-CIDR-APP-A |
| **app-cluster-b** | Site B | 192.0.2.30-192.0.2.39 | 203.0.113.30-203.0.113.36 | 192.0.2.130-192.0.2.139 | 198.51.100.30-198.51.100.39 | 198.51.100.130-198.51.100.139 | 198.51.100.35 | 198.51.100.134 | SERVICE-CIDR-APP-B | POD-CIDR-APP-B |
| **app-cluster-c** | Site C | 192.0.2.40-192.0.2.49 | 203.0.113.40-203.0.113.46 | 192.0.2.140-192.0.2.149 | 198.51.100.40-198.51.100.49 | 198.51.100.140-198.51.100.149 | 198.51.100.45 | 198.51.100.144 | SERVICE-CIDR-APP-C | POD-CIDR-APP-C |

### mgmt-cluster Cluster (Management Cluster)

**IP Allocations:**

- **Node IPs (platform-net):** 192.0.2.10-192.0.2.19
- **Storage IPs (storage-net):** 203.0.113.10-203.0.113.17
- **Restricted Ingress IPs:** 192.0.2.110-192.0.2.119
- **Platform MetalLB Pool:** 198.51.100.10-198.51.100.19
- **Restricted Ingress MetalLB Pool:** 198.51.100.110-198.51.100.119
- **Contour Ingress (Domain):** 198.51.100.15
- **Contour Ingress (Restricted Ingress):** 198.51.100.114
- **Cluster Service CIDR:** SERVICE-CIDR-MGMT
- **Pod Network CIDR:** POD-CIDR-MGMT

**FQDN:** mgmt-cluster-api.platform.example.internal

**Purpose:** MongoDB Operator, Central Monitoring (Prometheus/Grafana), Istio Primary Control Plane

### app-cluster-a Cluster (Application Cluster - Site A)

**IP Allocations:**

- **Node IPs (platform-net):** 192.0.2.20-192.0.2.29
- **Storage IPs (storage-net):** 203.0.113.20-203.0.113.26
- **Restricted Ingress IPs:** 192.0.2.120-192.0.2.129
- **Platform MetalLB Pool:** 198.51.100.20-198.51.100.29
- **Restricted Ingress MetalLB Pool:** 198.51.100.120-198.51.100.129
- **Contour Ingress (Domain):** 198.51.100.25
- **Contour Ingress (Restricted Ingress):** 198.51.100.124
- **Cluster Service CIDR:** SERVICE-CIDR-APP-A
- **Pod Network CIDR:** POD-CIDR-APP-A

**FQDN:** app-cluster-a-api.platform.example.internal

**Purpose:** Rocket.Chat Application, MongoDB ReplicaSet Member, NATS Messaging

### app-cluster-b Cluster (Application Cluster - Site B)

**IP Allocations:**

- **Node IPs (platform-net):** 192.0.2.30-192.0.2.39
- **Storage IPs (storage-net):** 203.0.113.30-203.0.113.36
- **Restricted Ingress IPs:** 192.0.2.130-192.0.2.139
- **Platform MetalLB Pool:** 198.51.100.30-198.51.100.39
- **Restricted Ingress MetalLB Pool:** 198.51.100.130-198.51.100.139
- **Contour Ingress (Domain):** 198.51.100.35
- **Contour Ingress (Restricted Ingress):** 198.51.100.134
- **Cluster Service CIDR:** SERVICE-CIDR-APP-B
- **Pod Network CIDR:** POD-CIDR-APP-B

**FQDN:** app-cluster-b-api.platform.example.internal

**Purpose:** Rocket.Chat Application, MongoDB ReplicaSet Member, NATS Messaging

### app-cluster-c Cluster (Application Cluster - Site C)

**IP Allocations:**

- **Node IPs (platform-net):** 192.0.2.40-192.0.2.49
- **Storage IPs (storage-net):** 203.0.113.40-203.0.113.46
- **Restricted Ingress IPs:** 192.0.2.140-192.0.2.149
- **Platform MetalLB Pool:** 198.51.100.40-198.51.100.49
- **Restricted Ingress MetalLB Pool:** 198.51.100.140-198.51.100.149
- **Contour Ingress (Domain):** 198.51.100.45
- **Contour Ingress (Restricted Ingress):** 198.51.100.144
- **Cluster Service CIDR:** SERVICE-CIDR-APP-C
- **Pod Network CIDR:** POD-CIDR-APP-C

**FQDN:** app-cluster-c-api.platform.example.internal

**Purpose:** Rocket.Chat Application, MongoDB ReplicaSet Member, NATS Messaging

---

## Service Endpoints

### Application Services

| Service | FQDN | Platform Network IPs | Restricted Ingress Network IPs | Protocol | Port |
| --------- | ------ | ------------------- | --------------------- | ---------- | ------ |
| **Rocket.Chat** | rocket.platform.example.internal | 198.51.100.25, 198.51.100.35, 198.51.100.45 | 198.51.100.124, 198.51.100.134, 198.51.100.144 | HTTP/HTTPS | 80/443 |

**Note:** Sites are simulated representations of possible deployment configurations in a production environment.

### Infrastructure Services

| Service | FQDN/Endpoint | IP Address | Protocol | Port | Purpose |
| --------- | --------------- | ------------ | ---------- | ------ | --------- |
| **Container Registry** | registry.example.internal | - | HTTPS | 8443 | Container image repository |
| **NetApp Storage (NFS)** | storage.example.internal | - | NFS | 2049 | NFS storage provisioning |
| **NetApp Storage (iSCSI)** | storage.example.internal | - | iSCSI | 3260 | Block storage provisioning |
| **NetApp Data LIF** | storage-data.example.internal | - | NFS | 2049 | NFS data traffic |

### Service Mesh East-West Gateways

| Cluster | Network | Gateway Type | Port | Purpose |
| --------- | --------- | -------------- | ------ | --------- |
| mgmt-cluster | Platform MetalLB Pool | LoadBalancer | 15443 | Cross-cluster service mesh traffic |
| mgmt-cluster | Restricted Ingress MetalLB Pool | LoadBalancer | 15443 | Cross-cluster service mesh traffic |
| app-cluster-a | Platform MetalLB Pool | LoadBalancer | 15443 | Cross-cluster service mesh traffic |
| app-cluster-a | Restricted Ingress MetalLB Pool | LoadBalancer | 15443 | Cross-cluster service mesh traffic |
| app-cluster-b | Platform MetalLB Pool | LoadBalancer | 15443 | Cross-cluster service mesh traffic |
| app-cluster-b | Restricted Ingress MetalLB Pool | LoadBalancer | 15443 | Cross-cluster service mesh traffic |
| app-cluster-c | Platform MetalLB Pool | LoadBalancer | 15443 | Cross-cluster service mesh traffic |
| app-cluster-c | Restricted Ingress MetalLB Pool | LoadBalancer | 15443 | Cross-cluster service mesh traffic |

**Note:** East-west gateways are assigned IPs dynamically from MetalLB pools when deployed.

---

## Node Inventory

### mgmt-cluster Cluster (Site A)

| Hostname | platform-net | storage-net | restricted-ingress | Role |
| ---------- | -------------- | ------------- | ---------- | ------ |
| **mgmt-cluster-api** | - | - | - | Cluster VIP |
| mgmt-cluster-ctrl01 | 192.0.2.10 | 203.0.113.10 | 192.0.2.110 | Control Plane |
| mgmt-cluster-ctrl02 | 192.0.2.11 | 203.0.113.11 | 192.0.2.111 | Control Plane |
| mgmt-cluster-ctrl03 | 192.0.2.12 | 203.0.113.12 | 192.0.2.112 | Control Plane |
| mgmt-cluster-spare | 192.0.2.13 | 203.0.113.13 | 192.0.2.113 | Spare Node |
| mgmt-cluster-work01 | 192.0.2.14 | 203.0.113.14 | 192.0.2.114 | Worker Node |
| mgmt-cluster-work02 | 192.0.2.15 | 203.0.113.15 | 192.0.2.115 | Worker Node |
| mgmt-cluster-work03 | 192.0.2.16 | 203.0.113.16 | 192.0.2.116 | Worker Node |
| mgmt-cluster-work04 | 192.0.2.17 | 203.0.113.17 | 192.0.2.117 | Worker Node |

**Total Capacity:** 3 control plane nodes, 4 worker nodes, 1 spare

### app-cluster-a Cluster (Site A)

| Hostname | platform-net | storage-net | restricted-ingress | Role |
| ---------- | -------------- | ------------- | ---------- | ------ |
| **app-cluster-a-api** | - | - | - | Cluster VIP |
| app-cluster-a-ctrl01 | 192.0.2.20 | 203.0.113.20 | 192.0.2.120 | Control Plane |
| app-cluster-a-ctrl02 | 192.0.2.21 | 203.0.113.21 | 192.0.2.121 | Control Plane |
| app-cluster-a-ctrl03 | 192.0.2.22 | 203.0.113.22 | 192.0.2.122 | Control Plane |
| app-cluster-a-spare | 192.0.2.23 | 203.0.113.23 | 192.0.2.123 | Spare Node |
| app-cluster-a-work01 | 192.0.2.24 | 203.0.113.24 | 192.0.2.124 | Worker Node |
| app-cluster-a-work02 | 192.0.2.25 | 203.0.113.25 | 192.0.2.125 | Worker Node |
| app-cluster-a-work03 | 192.0.2.26 | 203.0.113.26 | 192.0.2.126 | Worker Node |

**Total Capacity:** 3 control plane nodes, 3 worker nodes, 1 spare

### app-cluster-b Cluster (Site B)

| Hostname | platform-net | storage-net | restricted-ingress | Role |
| ---------- | -------------- | ------------- | ---------- | ------ |
| **app-cluster-b-api** | - | - | - | Cluster VIP |
| app-cluster-b-ctrl01 | 192.0.2.30 | 203.0.113.30 | 192.0.2.130 | Control Plane |
| app-cluster-b-ctrl02 | 192.0.2.31 | 203.0.113.31 | 192.0.2.131 | Control Plane |
| app-cluster-b-ctrl03 | 192.0.2.32 | 203.0.113.32 | 192.0.2.132 | Control Plane |
| app-cluster-b-spare | 192.0.2.33 | 203.0.113.33 | 192.0.2.133 | Spare Node |
| app-cluster-b-work01 | 192.0.2.34 | 203.0.113.34 | 192.0.2.134 | Worker Node |
| app-cluster-b-work02 | 192.0.2.35 | 203.0.113.35 | 192.0.2.135 | Worker Node |
| app-cluster-b-work03 | 192.0.2.36 | 203.0.113.36 | 192.0.2.136 | Worker Node |

**Total Capacity:** 3 control plane nodes, 3 worker nodes, 1 spare

### app-cluster-c Cluster (Site C)

| Hostname | platform-net | storage-net | restricted-ingress | Role |
| ---------- | -------------- | ------------- | ---------- | ------ |
| **app-cluster-c-api** | - | - | - | Cluster VIP |
| app-cluster-c-ctrl01 | 192.0.2.40 | 203.0.113.40 | 192.0.2.140 | Control Plane |
| app-cluster-c-ctrl02 | 192.0.2.41 | 203.0.113.41 | 192.0.2.141 | Control Plane |
| app-cluster-c-ctrl03 | 192.0.2.42 | 203.0.113.42 | 192.0.2.142 | Control Plane |
| app-cluster-c-spare | 192.0.2.43 | 203.0.113.43 | 192.0.2.143 | Spare Node |
| app-cluster-c-work01 | 192.0.2.44 | 203.0.113.44 | 192.0.2.144 | Worker Node |
| app-cluster-c-work02 | 192.0.2.45 | 203.0.113.45 | 192.0.2.145 | Worker Node |
| app-cluster-c-work03 | 192.0.2.46 | 203.0.113.46 | 192.0.2.146 | Worker Node |

**Total Capacity:** 3 control plane nodes, 3 worker nodes, 1 spare

---

## Network Architecture Diagrams

### Three-Network Design

Each cluster node has three network interfaces:

```text
┌──────────────────────────────────────────────────────────────┐
│                    Kubernetes Node                           │
│                                                              │
│  ┌──────────────┐  ┌──────────────┐  ┌────────────────────┐  │
│  │ platform-net │  │ storage-net  │  │ restricted-ingress │  │
│  │  (Primary)   │  │  (Storage)   │  │ (Secondary)        │  │
│  │              │  │              │  │                    │  │
│  │ 192.0.2.x/24 │  │ 203.0.113.x  │  │ 198.51.100.x/25    │  │
│  │              │  │              │  │                    │  │
│  │ Management   │  │ iSCSI Only   │  │ App Traffic        │  │
│  │ App Services │  │ Block Storage│  │ Restricted Ingress │  │
│  └──────────────┘  └──────────────┘  └────────────────────┘  │
│                                                              │
└──────────────────────────────────────────────────────────────┘
```

### Traffic Segmentation

**platform-net (192.0.2.0/24):**

- Kubernetes API server communication
- kubectl/helm management traffic
- LoadBalancer services (MetalLB)
- Ingress traffic (Contour)
- Service mesh control plane (Istio)

**storage-net (203.0.113.10-203.0.113.47):**

- Dedicated iSCSI storage network
- Persistent volume traffic only
- Isolated from application traffic
- Direct connection to NetApp SVM

**restricted-ingress (198.51.100.128/25):**

- Alternative network path for services
- Redundant LoadBalancer services
- Additional ingress endpoints
- Network segmentation and isolation

### MetalLB IP Pool Strategy

Each cluster has two MetalLB pools for redundancy:

- **Platform Pool:** Allocates IPs from platform-net network (198.51.100.x)
- **Restricted Ingress Pool:** Allocates IPs from restricted-ingress network (198.51.100.x)

Services can request IPs from either pool using address pool annotations.

---

## Reference Links

- **Main Documentation:** [README.md](../README.md)
- **System Design:** [System-Design-Document.md](System-Design-Document.md)
- **Monitoring Guide:** [Monitoring-Enhancements.md](Monitoring-Enhancements.md)
- **Security Guide:** [Security-Hardening-Guide.md](Security-Hardening-Guide.md)
- **Operations Guide:** [Operations-Quick-Reference.md](Operations-Quick-Reference.md)

---

**Last Updated:** May 22, 2026

## Ingress Plane VIP Summary

The platform and restricted ingress planes intentionally use different VIP ranges and namespaces.

| Cluster | platform-ingress IngressClass | platform-ingress VIP | restricted-ingress IngressClass | restricted-ingress VIP |
| --- | --- | ---: | --- | ---: |
| mgmt-cluster | `platform-ingress` | `198.51.100.15` | `restricted-ingress` | `198.51.100.114` |
| app-cluster-a | `platform-ingress` | `198.51.100.25` | `restricted-ingress` | `198.51.100.124` |
| app-cluster-b | `platform-ingress` | `198.51.100.35` | `restricted-ingress` | `198.51.100.134` |
| app-cluster-c | `platform-ingress` | `198.51.100.45` | `restricted-ingress` | `198.51.100.144` |

Operational rule: `restricted-ingress` must not be a default IngressClass. See `docs/Ingress-Segmentation-Design.md` for the security rationale.
