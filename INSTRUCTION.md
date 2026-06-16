# Validation Instructions

This document explains how to deploy and validate the `todoapp` Helm chart
(with the `mysql` subchart) on a local `kind` cluster.

## Prerequisites

- docker
- kind
- kubectl
- helm

## 1. Create the cluster

```bash
kind create cluster --name kind --config cluster.yml
kubectl get nodes
```

You should see 1 control-plane node and 6 worker nodes in the `Ready` state.

## 2. Inspect and taint the mysql nodes

```bash
# Inspect labels and taints
kubectl get nodes --show-labels
kubectl get nodes -o custom-columns=NAME:.metadata.name,TAINTS:.spec.taints

# (also done automatically by bootstrap.sh)
kubectl taint nodes -l app=mysql app=mysql:NoSchedule --overwrite
```

## 3. Deploy everything

```bash
chmod +x bootstrap.sh
./bootstrap.sh
```

`bootstrap.sh` taints the mysql nodes, installs the Ingress NGINX controller
and metrics-server, and deploys the `todoapp` Helm chart (which automatically
includes the `mysql` subchart).

## 4. Verify the deployment

Wait ~1-2 minutes until everything is up, then:

```bash
kubectl get pods -n mysql        # 2x mysql-*  Running
kubectl get pods -n todoapp      # 2x todoapp-* Running (scaled by the HPA)
kubectl get hpa -n todoapp       # todoapp, minReplicas=2, TARGETS not <unknown>
kubectl get ingress -n todoapp   # todoapp-ingress
kubectl get all,cm,secret,ing -A
```

## 5. Access the application

```bash
curl http://localhost:30007/     # via NodePort
curl http://localhost/           # via Ingress
```

## 6. Render / lint the chart locally (optional)

```bash
helm lint .infrastructure/helm-chart/todoapp
helm template .infrastructure/helm-chart/todoapp -f .infrastructure/helm-chart/todoapp/values.yaml
```

## 7. Regenerate output.log

```bash
kubectl get all,cm,secret,ing -A > output.log
```

## Cleanup

```bash
helm uninstall todoapp
kind delete cluster --name kind
```
