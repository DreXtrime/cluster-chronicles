# Cluster Chronicles

A production-style Kubernetes infrastructure running a Flask monitoring application, with full CI/CD, observability, and GitOps automation.

> This repository is configured as an educational playground to demonstrate Kubernetes cluster configuration, GitOps, and monitoring stacks within a local **Minikube** sandbox.
>
> **Don't attempt to clone and deploy this cluster manually unless you know what you are doing.**  

## Overview

This repository contains all Kubernetes manifests for deploying the [simple-infra-monitor](https://github.com/DreXtrime/simple-infra-monitor) application stack. Infrastructure is managed declaratively via ArgoCD - pushing to this repo automatically updates the cluster.

## Architecture

- **App**: Flask backend + frontend deployed to a local Minikube cluster
- **GitOps**: ArgoCD watches this repo and syncs changes automatically
- **Image Updates**: ArgoCD Image Updater detects new image digests on ghcr.io and triggers redeployment
- **CI/CD**: GitHub Actions builds, scans (Trivy + bandit), and publishes images on push to main
- **Monitoring**: Prometheus + Grafana with custom application dashboards and Alertmanager alerts to Discord
- **Logging**: ECK (Elasticsearch + Kibana) with Fluent Bit collecting logs from all pods
- **KubeView**: Render an interactive webui diagram of the cluster
- **Autoscaling**: HPA scales frontend between 2-5 replicas based on CPU

## Prerequisites

- Minikube
- kubectl
- Helm

## Setup

### 1. Start Minikube
```bash
minikube start --driver=docker --memory=14384 --cpus=6
```

### 2. Enable addons
```bash
minikube addons enable ingress
minikube addons enable metrics-server
```

### 3. Create namespaces
```bash
kubectl create namespace app
kubectl create namespace monitoring
kubectl create namespace logging
kubectl create namespace cicd
```

### 4. Install ArgoCD
```bash
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update
helm install argocd argo/argo-cd --namespace cicd
```

### 5. Bootstrap the cluster
```bash
kubectl apply -f manifests/cicd/app-of-apps.yaml
```

ArgoCD will automatically install and configure everything else.

### 6. Create required secrets
```bash
# Discord webhook for alerts
kubectl create secret generic discord-webhook-secret \
  --namespace monitoring \
  --from-literal=url='<your-discord-webhook-url>'

# Elasticsearch credentials are created automatically by ECK
```

### 7. Start tunnel and port-forwards
```bash
minikube tunnel
./port-forward.sh
```

## Accessing Services

| Service      | URL                    | Credentials         |
|--------------|------------------------|---------------------|
| Application  | http://localhost       | -                   |
| Grafana      | http://127.0.0.1:3000  | admin / see below   |
| ArgoCD       | https://127.0.0.1:9090 | admin / see below   |
| Prometheus   | http://127.0.0.1:9091  | -                   |
| Alertmanager | http://127.0.0.1:9093  | -                   |
| Kibana       | https://127.0.0.1:5601 | elastic / see below |
| Kubeview     | https://127.0.0.1:8888 | -                   |

### Retrieving passwords
```bash
# Grafana
kubectl get secret -n monitoring prometheus-grafana -o jsonpath="{.data.admin-password}" | base64 -d

# ArgoCD
kubectl -n cicd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# Kibana (Elasticsearch)
kubectl get secret elasticsearch-es-elastic-user -n logging -o jsonpath='{.data.elastic}' | base64 -d
```

## CI/CD Pipeline

The application images live in [simple-infra-monitor](https://github.com/DreXtrime/simple-infra-monitor). On every push:

1. Tests run (pytest, flake8, bandit)
2. Docker images are built
3. Trivy scans images for CRITICAL vulnerabilities
4. If scan passes, images are pushed to ghcr.io with `latest` and SHA tags
5. ArgoCD Image Updater detects the new digest and triggers redeployment

## Logging

Fluent Bit collects logs from all pods and forwards to Elasticsearch. Kibana dashboards:
- **Cluster Logs** - kube-system namespace logs
- **Application Logs** - app and cicd namespace logs
- **Pod and Container Logs** - per-pod log filtering

## Folder Structure

```
manifests/
├── app/          # Backend, frontend, ingress, RBAC, network policies
├── cicd/         # ArgoCD Application manifests
├── logging/      # ECK Elasticsearch and Kibana resources
├── monitoring/   # Prometheus rules, ServiceMonitor, Grafana dashboards
└── storage/      # PersistentVolumes and PersistentVolumeClaims
```