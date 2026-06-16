#!/bin/bash
set -e

# 1. Taint nodes labeled app=mysql so only mysql pods (with matching toleration) land there
kubectl taint nodes -l app=mysql app=mysql:NoSchedule --overwrite

# 2. Install the Ingress NGINX controller and wait until it is ready
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=120s

# 3. Install metrics-server (required so the HPA can read CPU/Memory metrics in kind)
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
kubectl patch -n kube-system deployment metrics-server --type=json \
  -p '[{"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--kubelet-insecure-tls"}]'

# 4. Deploy the todoapp Helm chart (it pulls in the mysql subchart automatically)
helm upgrade --install todoapp .infrastructure/helm-chart/todoapp \
  -f .infrastructure/helm-chart/todoapp/values.yaml
