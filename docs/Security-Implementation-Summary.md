# Security Hardening Implementation Summary

> **Public release rewrite note:** This file was rewritten with public-safe cluster, realm, DNS, path, and IP placeholders. It preserves the platform design intent but is not a live deployment inventory.

**Reference Architecture Environment**  
**Version:** 1.5  
**Date:** May 22, 2026

---

## Executive Summary

This document summarizes the security hardening implementation for the multi-cluster Kubernetes environment. The current baseline includes pod security hardening, namespace-segmented NetworkPolicies, and expanded default-deny automation coverage.

**Current Risk Level:** 🟡 **MEDIUM** (network segmentation and security contexts enforced, with remaining hardening gaps)  
**Target Risk Level (Future):** 🟢 **LOW** (with strict mesh mTLS policy, NATS TLS default-on, and Pod Security Admission labels enforced)

---

## Changes Implemented

### 1. ✅ Pod Security Contexts

Security contexts have been added to application and infrastructure components to enforce:

- **runAsNonRoot**: Prevents containers from running as root
- **Drop ALL capabilities**: Removes all Linux capabilities, adds only what's needed
- **seccomp profiles**: Enforces RuntimeDefault seccomp profile
- **allowPrivilegeEscalation: false**: Prevents privilege escalation

---

### 2. ✅ Network Policies

NetworkPolicies have been created for all application and infrastructure namespaces to:

- Control ingress traffic (who can access the service)
- Control egress traffic (what the service can access)
- Enable defense-in-depth security posture
- Facilitate incident containment

### 3. ✅ 2026-04 Baseline Security Updates

- Expanded Keycloak policy coverage for all deployed variants (`platform-idp`, `federated-idp`, and `enterprise-idp`)
- Narrowed overly broad monitoring ingress policy selectors
- Replaced broad keycloak egress `ipBlock` rules with namespace/pod scoped postgres egress
- Enforced explicit non-root security contexts for Rocket.Chat microservices
- Expanded default-deny rollout scope in hardening automation to include `monitoring` and `keycloak`

### 4. ⚠️ Remaining Hardening Work

- NATS transport TLS is enabled by default in `build/sites/all/values/nats-cluster-values-v3.yaml`
- Explicit mesh-wide strict mTLS policy manifests (for example `PeerAuthentication` in STRICT mode) are not yet codified in `build/sites`
- Pod Security Admission namespace labels are present in scripts mostly as commented guidance, not enforced defaults

---

## File Changes Summary

### Configuration Files Modified

#### NATS Cluster

- **File:** `build/sites/all/values/nats-cluster-values-v3.yaml` (v2 → v3)
- **Changes:**
  - Added `podSecurityContext` with UID 1000, GID 1000, fsGroup 1000
  - Added `containerSecurityContext` dropping ALL capabilities
  - Added seccomp RuntimeDefault profile
  - Added same to `promExporter` section

**Security Improvements:**

```yaml
podSecurityContext:
  runAsNonRoot: true
  runAsUser: 1000
  runAsGroup: 1000
  fsGroup: 1000
  seccompProfile:
    type: RuntimeDefault

containerSecurityContext:
  allowPrivilegeEscalation: false
  runAsNonRoot: true
  capabilities:
    drop:
    - ALL
  seccompProfile:
    type: RuntimeDefault
```

---

#### Contour Ingress Controller

- **Files:** (v3 → v4 across all clusters)
  - `build/sites/site-a/manager-cluster/values/contour-values-v4.yaml`
  - `build/sites/site-a/domain-cluster/values/contour-values-v4.yaml`
  - `build/sites/site-b/domain-cluster/values/contour-values-v4.yaml`
  - `build/sites/site-c/domain-cluster/values/contour-values-v4.yaml`

- **Changes:**
  - Added `podSecurityContext` for both Contour and Envoy
  - Contour: UID 65534 (nobody), drops ALL capabilities
  - Envoy: UID 65534, drops ALL capabilities except NET_BIND_SERVICE (for ports < 1024)

**Security Improvements:**

```yaml
contour:
  podSecurityContext:
    runAsNonRoot: true
    runAsUser: 65534
    fsGroup: 65534
    seccompProfile:
      type: RuntimeDefault
  containerSecurityContext:
    allowPrivilegeEscalation: false
    runAsNonRoot: true
    capabilities:
      drop:
      - ALL

envoy:
  podSecurityContext:
    runAsNonRoot: true
    runAsUser: 65534
    fsGroup: 65534
    seccompProfile:
      type: RuntimeDefault
  containerSecurityContext:
    allowPrivilegeEscalation: false
    runAsNonRoot: true
    capabilities:
      drop:
      - ALL
      add:
      - NET_BIND_SERVICE  # Required for privileged ports
```

---

#### Prometheus Stack

- **File:** `build/sites/site-a/manager-cluster/values/kube-prometheus-server-values-mgmt-cluster-v9.yaml` (v8 → v9)
- **Changes:**
  - Added `securityContext` to Prometheus (UID 1000, fsGroup 2000)
  - Added `securityContext` to Grafana (UID 472, fsGroup 472)
  - Added `securityContext` to Alertmanager (UID 1000, fsGroup 2000)
  - All components drop ALL capabilities

**Security Improvements:**

```yaml
prometheus:
  prometheusSpec:
    securityContext:
      runAsNonRoot: true
      runAsUser: 1000
      fsGroup: 2000
      seccompProfile:
        type: RuntimeDefault
    containers:
      - name: prometheus
        securityContext:
          allowPrivilegeEscalation: false
          capabilities:
            drop:
            - ALL

grafana:
  podSecurityContext:
    runAsNonRoot: true
    runAsUser: 472
    fsGroup: 472
    seccompProfile:
      type: RuntimeDefault
  containerSecurityContext:
    allowPrivilegeEscalation: false
    capabilities:
      drop:
      - ALL

alertmanager:
  alertmanagerSpec:
    securityContext:
      runAsNonRoot: true
      runAsUser: 1000
      fsGroup: 2000
      seccompProfile:
        type: RuntimeDefault
```

---

### NetworkPolicy Files Created

#### 1. Rocket.Chat NetworkPolicy

**File:** `build/sites/all/resources/networkpolicy-rocketchat-v1.yaml`

**Policies Defined:**

- `rocketchat-main`: Main application pods
  - **Ingress:** From Contour (port 3000), from Prometheus (metrics)
  - **Egress:** To MongoDB (27017), NATS (4222), Istio (15012), DNS, K8s API

- `rocketchat-presence`: Presence microservice
  - **Ingress:** From main Rocket.Chat pods, Prometheus
  - **Egress:** To NATS, main Rocket.Chat pods, DNS

**Traffic Allowed:**

- ✅ Inbound from Contour for user traffic
- ✅ Outbound to MongoDB for data persistence
- ✅ Outbound to NATS for real-time messaging
- ✅ Outbound to Istio for service mesh integration
- ✅ Prometheus metrics scraping

---

#### 2. MongoDB NetworkPolicy

**File:** `build/sites/all/resources/networkpolicy-mongodb-v1.yaml`

**Policies Defined:**

- `mongodb-replicaset`: MongoDB pods
  - **Ingress:** From Rocket.Chat (27017), MongoDB Operator, Prometheus exporter (9216), inter-replica
  - **Egress:** To other replicas, Istio east-west gateway (15443), MongoDB Operator, DNS, K8s API

- `mongodb-exporter`: MongoDB Exporter sidecar
  - **Ingress:** From Prometheus (9216)
  - **Egress:** To MongoDB pods (27017), DNS

**Traffic Allowed:**

- ✅ Inbound from Rocket.Chat for database queries
- ✅ Inter-replica communication for replication
- ✅ Cross-cluster replication via Istio east-west gateway
- ✅ MongoDB Operator management traffic
- ✅ Prometheus metrics scraping

---

#### 3. NATS NetworkPolicy

**File:** `build/sites/all/resources/networkpolicy-nats-v1.yaml`

**Policies Defined:**

- `nats-cluster`: NATS server pods
  - **Ingress:** From Rocket.Chat (4222), Prometheus (8222, 7777), inter-cluster NATS (6222)
  - **Egress:** To other NATS pods (6222), DNS

- `nats-exporter`: NATS Prometheus exporter
  - **Ingress:** From Prometheus (7777)
  - **Egress:** To NATS monitoring endpoint (8222), DNS

**Traffic Allowed:**

- ✅ Inbound from Rocket.Chat for messaging
- ✅ Inter-cluster NATS routing
- ✅ Prometheus metrics scraping
- ✅ NATS monitoring endpoint access

---

#### 4. Monitoring NetworkPolicy

**File:** `build/sites/site-a/manager-cluster/resources/networkpolicy-monitoring-v1.yaml`

**Policies Defined:**

- `prometheus`: Prometheus server
  - **Ingress:** From Grafana (9090), Alertmanager, and `istio-system` sources for remote write path
  - **Egress:** To all namespaces for scraping, Alertmanager (9093), DNS, K8s API

- `grafana`: Grafana UI
  - **Ingress:** From Contour, monitoring namespace workloads, and Kiali in `istio-system`
  - **Egress:** To Prometheus and dedicated Grafana PostgreSQL on TCP/5432
- `mgmt-cluster-server-postgres`: Grafana configuration database
  - **Ingress:** From Grafana only on TCP/5432
  - **Egress:** DNS only
  - **Egress:** To Prometheus (9090), DNS, K8s API

- `alertmanager`: Alertmanager
  - **Ingress:** From Prometheus (9093), Contour, inter-alertmanager (9094)
  - **Egress:** To webhook receivers (443), other Alertmanager instances, DNS

**Traffic Allowed:**

- ✅ Prometheus scraping all ServiceMonitors
- ✅ Grafana querying Prometheus
- ✅ Alertmanager receiving alerts and sending notifications
- ✅ Web UI access via Contour
- ✅ Remote write from other clusters

---

#### 5. Default Deny Template

**File:** `build/sites/all/resources/networkpolicy-default-deny-template.yaml`

**Policies Defined:**

- `default-deny-all-ingress`: Denies all ingress by default
- `default-deny-all-egress`: Denies all egress by default
- `allow-dns-egress`: Allows DNS (commonly needed)

**Usage:**

```bash
sed 's/${NAMESPACE}/rocketchat/g' networkpolicy-default-deny-template.yaml | kubectl apply -f -
```

**Purpose:** Establish a default-deny posture, then layer specific allow policies on top for defense-in-depth.

---

### Deployment Scripts Created

#### 1. Security Hardening Deployment Script

**File:** `build/install/stigs/deploy-security-hardening.sh`

**Capabilities:**

- Automated deployment of all security enhancements
- Preflight checks (kubectl, helm)
- User confirmation before deployment
- Step-by-step deployment with progress tracking
- Namespace labeling for NetworkPolicy selectors
- Optional default deny policy deployment
- Verification of security contexts
- NetworkPolicy listing

**Steps:**

1. Deploy NATS with security contexts
2. Deploy Contour with security contexts (all 4 clusters)
3. Update Prometheus Stack with security contexts
4. Label namespaces for NetworkPolicy selectors
5. Deploy Rocket.Chat NetworkPolicies
6. Deploy MongoDB NetworkPolicies
7. Deploy NATS NetworkPolicies
8. Deploy Monitoring NetworkPolicies
9. (Optional) Deploy default deny NetworkPolicies

---

## Deployment Guide

### Prerequisites

```bash
# Verify tools
kubectl version
helm version

# Verify cluster access
kubectl config get-contexts

# Ensure you have access to all 4 clusters
kubectl config use-context mgmt-cluster && kubectl get nodes
kubectl config use-context app-cluster-a && kubectl get nodes
kubectl config use-context app-cluster-b && kubectl get nodes
kubectl config use-context app-cluster-c && kubectl get nodes
```

### Phase 1: Deploy Security Contexts (Low Risk)

Security contexts can be deployed without breaking existing functionality. They add constraints but don't block traffic.

```bash
# Run the deployment script
chmod +x build/install/stigs/deploy-security-hardening.sh
./build/install/stigs/deploy-security-hardening.sh

# When prompted for default deny policies, answer "no" initially
```

**Expected Duration:** 15-20 minutes  
**Risk Level:** 🟢 Low

### Phase 2: Deploy Application NetworkPolicies (Medium Risk)

Application NetworkPolicies allow specific traffic. Deploy and test before default deny.

**Already included in script above** (Steps 5-8)

**Testing After Deployment:**

```bash
# Test Rocket.Chat web UI
kubectl port-forward -n rocketchat svc/rocketchat 3000:3000
# Access http://localhost:3000

# Test MongoDB connectivity
kubectl exec -it -n rocketchat deployment/rocketchat -- nc -zv mongodb.mongodb.svc.cluster.local 27017

# Test NATS connectivity
kubectl exec -it -n rocketchat deployment/rocketchat -- nc -zv nats.nats-system.svc.cluster.local 4222

# Check Prometheus targets
kubectl port-forward -n monitoring svc/prometheus-operated 9090:9090
# Browse to http://localhost:9090/targets
```

**Expected Duration:** 5-10 minutes  
**Risk Level:** 🟡 Medium (may break unexpected connections)

### Phase 3: Deploy Default Deny Policies (High Risk)

⚠️ **CAUTION:** This will block all traffic not explicitly allowed!

```bash
# Re-run deployment script and answer "yes" to default deny
./build/install/stigs/deploy-security-hardening.sh
# When prompted: "Deploy default deny policies? (yes/no): yes"

# OR manually apply:
for NS in rocketchat mongodb nats-system monitoring keycloak; do
    sed "s/\${NAMESPACE}/${NS}/g" build/sites/all/resources/networkpolicy-default-deny-template.yaml | \
        kubectl apply -f -
done
```

**Testing:**

```bash
# Verify default deny is in place
kubectl get networkpolicy -n rocketchat
kubectl get networkpolicy -n mongodb
kubectl get networkpolicy -n nats-system
kubectl get networkpolicy -n monitoring
kubectl get networkpolicy -n keycloak

# Test that allowed traffic still works
# Test that blocked traffic is denied (try accessing from unauthorized namespace)
```

**Expected Duration:** 5 minutes  
**Risk Level:** 🔴 High (will break undocumented connections)

---

## Verification Procedures

### 1. Verify Pod Security Contexts

```bash
# Check NATS pods
kubectl get pod -n nats-system -l app.kubernetes.io/name=nats -o json | \
    jq '.items[].spec.securityContext'

# Expected output:
#{
#  "fsGroup": 1000,
#  "runAsGroup": 1000,
#  "runAsNonRoot": true,
#  "runAsUser": 1000,
#  "seccompProfile": {
#    "type": "RuntimeDefault"
#  }
#}

# Check Contour pods
kubectl get pod -n contour -l app.kubernetes.io/name=contour -o json | \
    jq '.items[].spec.securityContext'

# Check Prometheus pods
kubectl get pod -n monitoring -l app.kubernetes.io/name=prometheus -o json | \
    jq '.items[].spec.securityContext'

# Verify containers drop ALL capabilities
kubectl get pod -n nats-system -l app.kubernetes.io/name=nats -o json | \
    jq '.items[].spec.containers[].securityContext.capabilities'

# Expected output:
#{
#  "drop": ["ALL"]
#}
```

### 2. Verify NetworkPolicies

```bash
# List all NetworkPolicies
kubectl get networkpolicy -A

# Expected output should include:
# rocketchat     rocketchat-main
# rocketchat     rocketchat-presence
# mongodb        mongodb-replicaset
# mongodb        mongodb-exporter
# nats-system    nats-cluster
# nats-system    nats-exporter
# monitoring     prometheus
# monitoring     grafana
# monitoring     alertmanager

# Describe specific policy
kubectl describe networkpolicy rocketchat-main -n rocketchat

# Check policy selectors match pods
kubectl get pods -n rocketchat --show-labels
```

### 3. Test Network Connectivity

```bash
# Test allowed connection (should succeed)
kubectl run -it --rm debug --image=busybox --restart=Never --namespace=rocketchat -- \
    nc -zv mongodb.mongodb.svc.cluster.local 27017

# Test blocked connection (should fail if default deny is in place)
kubectl run -it --rm debug --image=busybox --restart=Never --namespace=default -- \
    nc -zv mongodb.mongodb.svc.cluster.local 27017
# Expected: Connection refused or timeout
```

### 4. Monitor NetworkPolicy Violations

```bash
# Check for connection failures in application logs
kubectl logs -n rocketchat deployment/rocketchat --tail=50 | grep -i "connection\|refused\|timeout"

# Check Prometheus for connection metrics
# Query: rate(net_conntrack_listener_conn_closed_total[5m])
```

---

## Security Posture Assessment

### Before Implementation

| Category | Status | Risk Level |
| ---------- | -------- | ------------ |
| Pod Running as Root | ❌ All pods can run as root | 🔴 Critical |
| Linux Capabilities | ❌ All capabilities available | 🔴 Critical |
| Seccomp Profiles | ❌ No seccomp enforcement | 🔴 Critical |
| Network Segmentation | ❌ No NetworkPolicies | 🔴 Critical |
| Privilege Escalation | ❌ Not prevented | 🔴 Critical |

**Overall Risk:** 🔴 **CRITICAL**

### After Implementation

| Category | Status | Risk Level |
| ---------- | -------- | ------------ |
| Pod Running as Root | ✅ runAsNonRoot enforced | 🟢 Low |
| Linux Capabilities | ✅ ALL capabilities dropped | 🟢 Low |
| Seccomp Profiles | ✅ RuntimeDefault enforced | 🟢 Low |
| Network Segmentation | ✅ NetworkPolicies in place | 🟡 Medium |
| Privilege Escalation | ✅ Prevented | 🟢 Low |

**Overall Risk:** 🟡 **MEDIUM** (down from CRITICAL)

### Future State (with Pod Security Standards)

| Category | Status | Risk Level |
| ---------- | -------- | ------------ |
| Pod Running as Root | ✅ PSS restricted enforced | 🟢 Low |
| Linux Capabilities | ✅ ALL capabilities dropped | 🟢 Low |
| Seccomp Profiles | ✅ RuntimeDefault enforced | 🟢 Low |
| Network Segmentation | ✅ Default deny + allow policies | 🟢 Low |
| Privilege Escalation | ✅ Prevented | 🟢 Low |
| RBAC | ✅ Least privilege | 🟢 Low |
| Secrets Encryption | ✅ Vault integration | 🟢 Low |

**Target Overall Risk:** 🟢 **LOW**

---

## Rollback Procedures

### Rollback Security Contexts

```bash
# Rollback NATS to v2
helm upgrade nats helm/packages/nats-2.12.2.tgz \
    --namespace nats-system \
    --values build/sites/all/values/nats-cluster-values-v3.yaml

# Rollback Contour to v3 (per cluster)
helm upgrade contour helm/packages/contour-21.1.4.tgz \
    --namespace contour \
    --values build/sites/*/values/contour-values-v3.yaml

# Rollback Prometheus Stack to v8
helm upgrade mgmt-cluster-server helm/packages/kube-prometheus-stack-82.1.0.tgz \
    --namespace monitoring \
    --values build/sites/site-a/manager-cluster/values/kube-prometheus-server-values-mgmt-cluster-v9.yaml
```

### Remove NetworkPolicies

```bash
# Remove all NetworkPolicies from a namespace
kubectl delete networkpolicy --all -n rocketchat
kubectl delete networkpolicy --all -n mongodb
kubectl delete networkpolicy --all -n nats-system
kubectl delete networkpolicy --all -n monitoring
```

---

## Troubleshooting

### Pod Fails to Start with Security Context

**Symptom:** Pod in CrashLoopBackOff after adding security context

**Diagnosis:**

```bash
kubectl describe pod <pod-name> -n <namespace>
kubectl logs <pod-name> -n <namespace>
```

**Common Issues:**

1. **Filesystem permissions:** Pod tries to write to filesystem owned by root
   - **Fix:** Ensure fsGroup matches runAsUser
2. **Port < 1024:** Pod needs to bind privileged port without root
   - **Fix:** Add NET_BIND_SERVICE capability or change port
3. **Required capability:** Application needs specific Linux capability
   - **Fix:** Add only the required capability (minimal approach)

### NetworkPolicy Blocks Legitimate Traffic

**Symptom:** Application can't connect to service after NetworkPolicy deployment

**Diagnosis:**

```bash
# Check if NetworkPolicy exists
kubectl get networkpolicy -n <namespace>

# Describe NetworkPolicy
kubectl describe networkpolicy <policy-name> -n <namespace>

# Test connectivity
kubectl exec -it <pod> -n <namespace> -- nc -zv <service> <port>
```

**Fix:**

```bash
# Temporarily remove NetworkPolicy to confirm
kubectl delete networkpolicy <policy-name> -n <namespace>

# Test connectivity again
# If it works, update NetworkPolicy to allow the connection

# Re-apply fixed NetworkPolicy
kubectl apply -f <updated-policy.yaml>
```

### DNS Resolution Fails

**Symptom:** Pods can't resolve DNS after NetworkPolicy deployment

**Fix:** Ensure allow-dns-egress policy is in place

```bash
kubectl apply -f build/sites/all/resources/networkpolicy-default-deny-template.yaml
```

---

**Last Updated:** May 22, 2026

## May 22, 2026 Version 1.5 Security Addendum

### Platform Ingress / Restricted Ingress Ingress Separation

The ingress architecture now separates standard platform access from segmented workload exposure:

- `platform-ingress` is the standard control-plane and lab ingress plane.
- `restricted-ingress` is a segmented ingress plane for constrained or higher-risk workload paths.
- `restricted-ingress` must not be the default IngressClass.
- Every exposed service must declare the intended `ingressClassName`.

This change reduces routing ambiguity and limits blast radius. A misconfigured segmented workload should not accidentally land behind the same Envoy service and policy boundary as core platform services.

### Kiali / Grafana Access Hardening

Kiali no longer depends on anonymous Grafana access or cross-cluster Kubernetes service DNS. The current model uses:

- Central Grafana HTTPS FQDN: `https://grafana.platform.example.internal`
- Central Prometheus HTTPS FQDN: `https://prometheus.platform.example.internal`
- Grafana service-account token with Viewer role
- Per-cluster `kiali-grafana-credentials` Secret in `istio-system`
- `kiali-cabundle` ConfigMap for the platform-ingress CA bundle

### Remaining Security Backlog

1. Replace Kiali `anonymous` UI authentication before exposing it outside a sealed admin lab.
2. Add default-deny NetworkPolicies directly to `platform-ingress` and `restricted-ingress` ingress namespaces.
3. Add explicit allow lists for Envoy ingress to backend namespaces.
4. Codify Istio mesh-wide strict mTLS with namespace-specific exceptions where required.
