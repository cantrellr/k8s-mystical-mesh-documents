# Quick Reference Guide - Operations

> **Public release rewrite note:** This file was rewritten with public-safe cluster, realm, DNS, path, and IP placeholders. It preserves the platform design intent but is not a live deployment inventory.

**Reference Architecture Environment**  
**Version:** 1.5  
**Date:** May 22, 2026

Baseline reference: `docs/Configuration-Baseline.md`

## 🚀 Common Operations

### Cluster Access

```bash
# List all contexts
kubectl config get-contexts

# Switch to specific cluster
kubectl config use-context mgmt-cluster
kubectl config use-context app-cluster-a
kubectl config use-context app-cluster-b
kubectl config use-context app-cluster-c

# View current context
kubectl config current-context
```

### Check Cluster Health

```bash
# Node status
kubectl get nodes -o wide

# System pods
kubectl get pods -n kube-system

# All namespaces overview
kubectl get pods -A | grep -v Running

# Resource usage
kubectl top nodes
kubectl top pods -A
```

### Service Mesh Status

```bash
# Istio control plane
kubectl get pods -n istio-system

# East-West gateway status
kubectl get svc -n istio-system | grep eastwest

# Check Istio proxy status
istioctl proxy-status

# Verify multi-cluster connectivity
kubectl exec -n istio-system deploy/istiod-stable -- \
  curl http://istiod.istio-system:15014/debug/endpointz
```

### Monitoring Access

```bash
# Port-forward to Prometheus
kubectl port-forward -n monitoring svc/prometheus-operated 9090:9090
# Access: http://localhost:9090

# Port-forward to Grafana
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80
# Access: http://localhost:3000

# Port-forward to Alertmanager
kubectl port-forward -n monitoring svc/prometheus-alertmanager 9093:9093
# Access: http://localhost:9093

# Get Grafana admin password
kubectl get secret -n monitoring grafana-admin-credentials \
  -o jsonpath='{.data.admin-password}' | base64 -d
```

### Application Status

```bash
# Rocket.Chat
kubectl get pods -n rocketchat
kubectl logs -n rocketchat -l app.kubernetes.io/name=rocketchat --tail=100

# MongoDB
kubectl get mongodb -n mongodb
kubectl get pods -n mongodb

# NATS
kubectl get pods -n nats-system
kubectl exec -n nats-system nats-0 -- nats-server --version
```

### Storage Operations

```bash
# Check Trident backends
kubectl get tbc -n trident-system

# View storage classes
kubectl get sc

# Check PVCs
kubectl get pvc -A

# View volume usage
kubectl get pvc -A -o=jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.resources.requests.storage}{"\t"}{.status.phase}{"\n"}{end}'
```

### Certificate Management

```bash
# Check cert-manager
kubectl get pods -n cert-manager

# View certificates
kubectl get certificates -A

# Check certificate status
kubectl describe certificate <cert-name> -n <namespace>

# View ClusterIssuers
kubectl get clusterissuer
```

---

## 🔍 Troubleshooting

### Pod Not Starting

```bash
# Check pod status
kubectl describe pod <pod-name> -n <namespace>

# View events
kubectl get events -n <namespace> --sort-by='.lastTimestamp'

# Check logs
kubectl logs <pod-name> -n <namespace>

# Check previous logs (if crashed)
kubectl logs <pod-name> -n <namespace> --previous

# Check init containers
kubectl logs <pod-name> -n <namespace> -c <init-container-name>
```

### Service Not Accessible

```bash
# Check service
kubectl get svc <service-name> -n <namespace>

# Check endpoints
kubectl get endpoints <service-name> -n <namespace>

# Test connectivity
kubectl run -it --rm debug --image=busybox --restart=Never -- \
  wget -O- http://<service-name>.<namespace>:80

# Check Istio sidecar injection
kubectl get pod <pod-name> -n <namespace> -o jsonpath='{.spec.containers[*].name}'
```

### Monitoring Issues

```bash
# Check Prometheus targets
kubectl port-forward -n monitoring svc/prometheus-operated 9090:9090
# Browse to http://localhost:9090/targets

# Check ServiceMonitors
kubectl get servicemonitor -n monitoring

# Check PrometheusRules
kubectl get prometheusrule -n monitoring

# Validate PrometheusRule syntax
promtool check rules <file.yaml>

# Check Alertmanager configuration
kubectl get secret -n monitoring alertmanager-prometheus-alertmanager \
  -o jsonpath='{.data.alertmanager\.yaml}' | base64 -d
```

### Storage Issues

```bash
# Check Trident operator
kubectl get pods -n trident-system

# View Trident logs
kubectl logs -n trident-system deploy/trident-operator-controller

# Check backend connectivity
kubectl exec -n trident-system deploy/trident-operator-controller -- \
  tridentctl get backend

# Check volume details
kubectl describe pvc <pvc-name> -n <namespace>

# Test storage class
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: test-pvc
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
  storageClassName: tkg-work-storage-iscsi-latebinding
EOF

kubectl get pvc test-pvc
kubectl delete pvc test-pvc
```

### Istio Mesh Issues

```bash
# Check Istio installation
istioctl verify-install

# Analyze configuration
istioctl analyze -A

# Check proxy configuration
istioctl proxy-config cluster <pod-name>.<namespace>
istioctl proxy-config endpoint <pod-name>.<namespace>
istioctl proxy-config route <pod-name>.<namespace>

# View proxy logs
kubectl logs <pod-name> -n <namespace> -c istio-proxy

# Increase proxy log level
istioctl proxy-config log <pod-name>.<namespace> --level debug
```

### MongoDB Issues

```bash
# Check MongoDB operator
kubectl get pods -n mongodb-operator
kubectl logs -n mongodb-operator deploy/mongodb-kubernetes-operator

# Check MongoDB status
kubectl get mongodb -n mongodb -o yaml

# MongoDB logs
kubectl logs -n mongodb <mongodb-pod-name>

# Connect to MongoDB
kubectl exec -it -n mongodb <mongodb-pod-name> -- mongosh

# Check replication status
kubectl exec -n mongodb <mongodb-pod-name> -- mongosh --eval "rs.status()"
```

---

## 📊 Grafana PostgreSQL Quick Checks

```bash
# Grafana configuration database statefulset/service/secret
kubectl --context mgmt-cluster -n monitoring get sts mgmt-cluster-server-postgres-dhi-postgresql
kubectl --context mgmt-cluster -n monitoring get svc mgmt-cluster-server-postgres-dhi-postgresql
kubectl --context mgmt-cluster -n monitoring get secret grafanapostgres-credentials-secret

# Confirm Grafana is not emitting SQLite lock contention after PostgreSQL cutover
kubectl --context mgmt-cluster -n monitoring logs deployment/mgmt-cluster-server-grafana --since=2h \
  | grep -i 'database is locked'
```

Expected result for the last command: no new matches after the PostgreSQL-backed Grafana deployment is active.

---

## 🔧 Maintenance Tasks

### Update Helm Deployment

```bash
# Update cert-manager
helm upgrade cert-manager /path/to/helm/packages/cert-manager-1.5.14.tgz \
  --namespace cert-manager \
  --values build/sites/all/values/bitnami-cert-manager-values-v1514-v1.yaml

# Update Prometheus
helm upgrade mgmt-cluster-server /path/to/helm/packages/kube-prometheus-stack-82.1.0.tgz \
  --namespace monitoring \
  --values build/sites/site-a/manager-cluster/values/kube-prometheus-server-values-mgmt-cluster-v9.yaml

# Update Rocket.Chat
helm upgrade rocketchat /path/to/helm/packages/rocketchat-6.27.1.tgz \
  --namespace rocketchat \
  --values build/sites/all/values/rocketchat-microservices-values-v2.yaml
```

### Restart Deployments

```bash
# Restart specific deployment
kubectl rollout restart deployment <deployment-name> -n <namespace>

# Restart all deployments in namespace
kubectl rollout restart deployment -n <namespace>

# Restart statefulset
kubectl rollout restart statefulset <statefulset-name> -n <namespace>

# Restart daemonset
kubectl rollout restart daemonset <daemonset-name> -n <namespace>

# Check rollout status
kubectl rollout status deployment <deployment-name> -n <namespace>
```

### Scale Applications

```bash
# Scale deployment
kubectl scale deployment <deployment-name> -n <namespace> --replicas=3

# Scale statefulset
kubectl scale statefulset <statefulset-name> -n <namespace> --replicas=5

# Auto-scale (HPA)
kubectl autoscale deployment <deployment-name> -n <namespace> \
  --min=2 --max=10 --cpu-percent=80
```

### Backup Operations

```bash
# Export MongoDB data
kubectl exec -n mongodb <mongodb-pod-name> -- \
  mongodump --archive=/tmp/backup.archive --gzip

# Copy backup from pod
kubectl cp mongodb/<mongodb-pod-name>:/tmp/backup.archive ./backup.archive

# Backup Kubernetes resources
kubectl get all -n <namespace> -o yaml > namespace-backup.yaml

# Backup specific resource
kubectl get deployment <deployment-name> -n <namespace> -o yaml > deployment-backup.yaml
```

### Certificate Renewal

```bash
# Force certificate renewal
kubectl delete certificaterequest -n <namespace> <cert-request>

# Check certificate expiration
kubectl get certificate -A -o json | \
  jq -r '.items[] | "\(.metadata.namespace)/\(.metadata.name): \(.status.notAfter)"'

# Renew Istio certificates
kubectl delete secret -n istio-system cacerts
kubectl apply -f build/misc/istio-cacerts/istio-<cluster>-cacerts.yaml
kubectl rollout restart deployment -n istio-system
```

---

## 📊 Monitoring Queries

### Prometheus Queries

```promql
# CPU usage by pod
sum(rate(container_cpu_usage_seconds_total{pod!=""}[5m])) by (pod, namespace)

# Memory usage by pod
sum(container_memory_working_set_bytes{pod!=""}) by (pod, namespace)

# Network traffic by pod
sum(rate(container_network_transmit_bytes_total[5m])) by (pod, namespace)

# Pod restarts
sum(kube_pod_container_status_restarts_total) by (namespace, pod)

# PVC usage
(kubelet_volume_stats_used_bytes / kubelet_volume_stats_capacity_bytes) * 100

# MongoDB replication lag
mongodb_mongod_replset_member_replication_lag

# Rocket.Chat API latency
histogram_quantile(0.95, rate(http_request_duration_seconds_bucket{job="rocketchat"}[5m]))

# NATS message rate
rate(nats_varz_in_msgs[5m])

# Istio request rate
sum(rate(istio_requests_total[5m])) by (source_workload, destination_workload)
```

### LogQL Queries (if using Loki)

```logql
# All logs from namespace
{namespace="rocketchat"}

# Error logs
{namespace="rocketchat"} |= "error"

# Logs from specific pod
{namespace="rocketchat", pod="rocketchat-abc123"}

# Rate of errors
rate({namespace="rocketchat"} |= "error" [5m])
```

---

## 🔐 Security Operations

### Check Pod Security

```bash
# Verify Pod Security Standards
kubectl get ns -L pod-security.kubernetes.io/enforce

# Check for privileged pods
kubectl get pods -A -o json | \
  jq -r '.items[] | select(.spec.containers[].securityContext.privileged==true) | 
  "\(.metadata.namespace)/\(.metadata.name)"'

# Check for pods running as root
kubectl get pods -A -o json | \
  jq -r '.items[] | select(.spec.securityContext.runAsUser==0 or .spec.containers[].securityContext.runAsUser==0) | 
  "\(.metadata.namespace)/\(.metadata.name)"'
```

### RBAC Auditing

```bash
# List all ClusterRoleBindings
kubectl get clusterrolebindings

# Find cluster-admin bindings
kubectl get clusterrolebindings -o json | \
  jq -r '.items[] | select(.roleRef.name=="cluster-admin") | .metadata.name'

# Check ServiceAccount permissions
kubectl auth can-i --list --as=system:serviceaccount:<namespace>:<sa-name>

# Test specific permission
kubectl auth can-i create pods --as=system:serviceaccount:<namespace>:<sa-name>
```

### Network Policy Testing

```bash
# List all NetworkPolicies
kubectl get networkpolicy -A

# Check key policy namespaces quickly
for ns in rocketchat mongodb nats-system monitoring keycloak; do
  echo "=== $ns ==="
  kubectl get networkpolicy -n "$ns"
done

# Describe NetworkPolicy
kubectl describe networkpolicy <policy-name> -n <namespace>

# Test connectivity (should fail if policy blocks)
kubectl run test-pod --rm -it --image=busybox -n <source-namespace> -- \
  wget -O- http://<service>.<target-namespace>:80
```

---

## 📝 Useful Scripts

### Quick Health Check

```bash
#!/bin/bash
# health-check.sh

echo "=== Node Status ==="
kubectl get nodes

echo -e "\n=== System Pods ==="
kubectl get pods -n kube-system | grep -v Running || echo "All system pods running"

echo -e "\n=== Application Pods ==="
kubectl get pods -n rocketchat
kubectl get pods -n mongodb
kubectl get pods -n nats-system

echo -e "\n=== Rocket.Chat HPA ==="
kubectl get hpa -n rocketchat

echo -e "\n=== Istio Health ==="
kubectl get pods -n istio-system

echo -e "\n=== Monitoring Health ==="
kubectl get pods -n monitoring

echo -e "\n=== Recent Events ==="
kubectl get events -A --sort-by='.lastTimestamp' | tail -10
```

### Resource Usage Report

```bash
#!/bin/bash
# resource-report.sh

echo "=== Node Resources ==="
kubectl top nodes

echo -e "\n=== Top CPU Consumers ==="
kubectl top pods -A | sort -k3 -nr | head -10

echo -e "\n=== Top Memory Consumers ==="
kubectl top pods -A | sort -k4 -nr | head -10

echo -e "\n=== PVC Usage ==="
kubectl get pvc -A -o custom-columns=\
NAMESPACE:.metadata.namespace,\
NAME:.metadata.name,\
SIZE:.spec.resources.requests.storage,\
STATUS:.status.phase
```

### Certificate Expiration Check

```bash
#!/bin/bash
# cert-expiration.sh

echo "=== Certificate Expiration Report ==="
kubectl get certificate -A -o json | \
  jq -r '.items[] | 
  "\(.metadata.namespace)/\(.metadata.name): \(.status.notAfter // "Unknown")"' | \
  sort -t: -k2

echo -e "\n=== Certificates Expiring Soon (<30 days) ==="
# Would need more complex logic to parse dates
```

---

## Ingress Plane Checks

### Verify platform-ingress and restricted-ingress separation

```bash
for ctx in mgmt-cluster app-cluster-a app-cluster-b app-cluster-c; do
  echo "===== ${ctx} ====="
  kubectl --context "${ctx}" get ingressclass
  kubectl --context "${ctx}" get svc -n platform-ingress
  kubectl --context "${ctx}" get svc -n restricted-ingress
  kubectl --context "${ctx}" get ingress -A
  kubectl --context "${ctx}" get httpproxy -A 2>/dev/null || true
  echo
done
```

Expected result:

- `platform-ingress` may be default.
- `restricted-ingress` must not be default.
- Control-plane services should use `platform-ingress` unless there is an approved segmented exposure path.

### Find Ingress objects without an explicit class

```bash
for ctx in mgmt-cluster app-cluster-a app-cluster-b app-cluster-c; do
  echo "===== ${ctx} ====="
  kubectl --context "${ctx}" get ingress -A -o json |     jq -r '.items[] | select(.spec.ingressClassName == null) | "\(.metadata.namespace)/\(.metadata.name)"'
  echo
done
```

No output is the desired state.

---

## Monitoring / Kiali / Grafana Checks

### Recreate and distribute Kiali's Grafana service-account token

```bash
cd /opt/k8s-mystical-mesh/build/install/monitoring
./05-configure-kiali-grafana-access.sh
```

### Validate Kiali to central Grafana/Prometheus

```bash
cd /opt/k8s-mystical-mesh
./build/monitoring/scripts/verify-kiali-grafana-integration.sh
```

### Check Grafana PostgreSQL mode

```bash
kubectl --context mgmt-cluster -n monitoring exec deploy/mgmt-cluster-server-grafana -- \
  printenv GF_DATABASE_TYPE GF_DATABASE_HOST GF_DATABASE_NAME
```

Expected database type: `postgres`.

### Check for SQLite lock regression

```bash
kubectl --context mgmt-cluster -n monitoring logs deployment/mgmt-cluster-server-grafana --since=2h | \
  egrep -i 'database is locked|sqlite|transaction retry' || true
```

No output is the desired state.

---

## Resource and Performance Checks

### Identify pods missing requests or limits

```bash
for ctx in mgmt-cluster app-cluster-a app-cluster-b app-cluster-c; do
  echo "===== ${ctx} ====="
  kubectl --context "${ctx}" get pods -A -o json | jq -r '
    .items[] as $pod
    | ($pod.spec.containers + ($pod.spec.initContainers // []))[]
    | select((.resources.requests.cpu? // empty) == "" or (.resources.requests.memory? // empty) == "" or (.resources.limits.memory? // empty) == "")
    | "\($pod.metadata.namespace)/\($pod.metadata.name) container=\(.name)"
  '
  echo
done
```

### Check Prometheus central storage headroom

```bash
kubectl --context mgmt-cluster -n monitoring exec prometheus-mgmt-cluster-server-prometheus-0 -- df -h /prometheus
```

### Check high-cardinality pressure

```bash
kubectl --context mgmt-cluster -n monitoring exec -it prometheus-mgmt-cluster-server-prometheus-0 -- \
  promtool query instant http://localhost:9090 'topk(20, count by (__name__)({__name__=~".+"}))'
```

---

## 🚨 Emergency Procedures

### Complete Cluster Failure

1. **Check infrastructure:**

   ```bash
   ping <kubernetes-api-endpoint>
   kubectl cluster-info
   kubectl get nodes
   ```

2. **Check control plane:**

   ```bash
   kubectl get pods -n kube-system
   kubectl logs -n kube-system -l component=kube-apiserver
   ```

3. **Check etcd:**

   ```bash
   kubectl get pods -n kube-system -l component=etcd
   ETCDCTL_API=3 etcdctl endpoint health
   ```

4. **Restore from backup** (if available)

### Service Degradation

1. **Identify affected service:**

   ```bash
   kubectl get pods -A | grep -v Running
   kubectl get events -A --sort-by='.lastTimestamp' | tail -20
   ```

2. **Check resource constraints:**

   ```bash
   kubectl top nodes
   kubectl describe node <node-name>
   ```

3. **Scale if needed:**

   ```bash
   kubectl scale deployment <deployment> -n <namespace> --replicas=<N>
   ```

4. **Restart if stuck:**

   ```bash
   kubectl delete pod <pod-name> -n <namespace>
   ```

### Data Loss Prevention

1. **Immediate snapshot:**

   ```bash
   # MongoDB
   kubectl exec -n mongodb <pod> -- mongodump --archive > backup-$(date +%Y%m%d-%H%M%S).archive
   ```

2. **Prevent further changes:**

   ```bash
   # Scale down applications
   kubectl scale deployment -n rocketchat --all --replicas=0
   ```

3. **Investigate and restore**

---

## 📞 Escalation

### L1 → L2 Escalation Criteria

- Service down > 15 minutes
- Data inconsistency detected
- Security incident suspected
- Multiple failed restart attempts

### L2 → L3 Escalation Criteria

- Multi-cluster failure
- Data loss confirmed
- Security breach confirmed
- Architecture change needed

### Emergency Contacts

- **Platform Team:** <platform-oncall@company.com>
- **Security Team:** <security-oncall@company.com>
- **MongoDB Support:** Ticket via portal
- **NetApp Support:** Case via portal

---

## 🔖 Quick Links

- **Prometheus:** `kubectl port-forward -n monitoring svc/prometheus-operated 9090:9090`
- **Grafana:** `kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80`
- **Kiali:** `kubectl port-forward -n istio-system svc/kiali 20001:20001`
- **Alertmanager:** `kubectl port-forward -n monitoring svc/prometheus-alertmanager 9093:9093`

---


## Scheduler / PDB Validation

Run after a rebuild or before a maintenance window:

```bash
./build/monitoring/scripts/verify-scheduling-and-pdb.sh
```

Fast checks:

```bash
kubectl get pdb -A -o wide
kubectl get deploy,statefulset -A -o jsonpath='{range .items[?(@.spec.template.spec.affinity)]}{.kind}{"/"}{.metadata.namespace}{"/"}{.metadata.name}{"\n"}{end}'
kubectl get deploy,statefulset -A -o jsonpath='{range .items[?(@.spec.template.spec.topologySpreadConstraints)]}{.kind}{"/"}{.metadata.namespace}{"/"}{.metadata.name}{"\n"}{end}'
```

If `kubectl drain` blocks, inspect the PDB first:

```bash
kubectl describe pdb -n <namespace> <pdb-name>
```

**Last Updated:** May 22, 2026

## Validate Istio sidecars and monitoring coverage

Run this after the Istio, ingress, application, and monitoring installs:

```bash
./build/monitoring/scripts/verify-istio-sidecars-and-metrics.sh
```

Use the output to confirm that platform namespaces are not accidentally sidecar-injected and that ServiceMonitor/PodMonitor resources exist for the expected workloads.


## NATS TLS validation

```bash
./build/monitoring/scripts/verify-nats-tls.sh mgmt-cluster
```
