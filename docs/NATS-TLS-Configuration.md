# NATS TLS Configuration

> **Public release rewrite note:** This file was rewritten with public-safe cluster, realm, DNS, path, and IP placeholders. It preserves the platform design intent but is not a live deployment inventory.

**Version:** 1.5  
**Date:** May 22, 2026

## Purpose

NATS is the internal transport used by Rocket.Chat and its microservices. Previous configuration left the NATS client and route ports in plaintext. This revision closes that gap by enabling TLS on:

- NATS client connections on TCP/4222
- NATS cluster route connections on TCP/6222
- Rocket.Chat and Rocket.Chat microservice connections to NATS

The monitoring endpoint remains HTTP on localhost for the in-pod `prometheus-nats-exporter`; Prometheus scrapes the exporter on TCP/7777 through the existing PodMonitor.

## Certificate model

Certificates are issued by `platform-ca-clusterissuer` using cert-manager.

| Secret | Namespace | Purpose |
|---|---|---|
| `nats-client-tls` | `nats-system` | Server certificate for `tls://nats.nats-system.svc.cluster.local:4222` |
| `nats-cluster-tls` | `nats-system` | Server/client certificate for StatefulSet route traffic over `tls://nats-*.nats-headless.nats-system.svc.cluster.local:6222` |
| `rocketchat-nats-ca-secret` | `rocketchat` | CA bundle mounted into Rocket.Chat pods so Node.js can validate the NATS server certificate |

The NATS cluster certificate includes both `server auth` and `client auth` usages because NATS route TLS validates peers during server-to-server cluster communication.

## Rocket.Chat client behavior

The Rocket.Chat NATS transport secret now uses:

```text
tls://nats.nats-system.svc.cluster.local:4222
```

Rocket.Chat and the microservice deployments mount the NATS CA at:

```text
/etc/ssl/nats/ca.crt
```

and set:

```text
NODE_EXTRA_CA_CERTS=/etc/ssl/nats/ca.crt
```

This lets the Node.js runtime validate the internal platform-ingress CA instead of falling back to insecure TLS behavior.

## Deployment

NATS installation now applies the certificate resources and waits for both cert-manager `Certificate` objects before running Helm:

```bash
cd /opt/k8s-mystical-mesh/build/install/realms/platform-ingress/rocketchat
./19-install-nats-cluster.sh site-a management
```

After Rocket.Chat is installed or upgraded, validate TLS:

```bash
cd /opt/k8s-mystical-mesh
./build/monitoring/scripts/verify-nats-tls.sh mgmt-cluster
```

## Security posture

This is TLS encryption with server authentication. It does **not** require client certificate authentication for Rocket.Chat yet. That is intentional. It closes the plaintext transport gap without introducing a breaking mTLS dependency into the Rocket.Chat/Moleculer client stack before client-certificate support is explicitly proven.

Future hardening can move NATS client traffic from TLS server-auth to full mTLS by adding Rocket.Chat client certificates and setting `verify: true` on the NATS client TLS listener.
