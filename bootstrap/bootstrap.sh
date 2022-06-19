#!/bin/bash

DOMAIN=local

#Install basic controllers required to bootstrap the cluster

# Install Nginx Ingress
helm upgrade --install ingress-nginx ingress-nginx \
  --repo https://kubernetes.github.io/ingress-nginx \
  --version 4.1.4 \
  --namespace ingress-nginx --create-namespace --wait

kubectl apply -k ../apps/argo-cd/overlays/rancher

kubectl --namespace argocd rollout status deployment argocd-server

ARGOCD_PASSWD=$(kubectl --namespace argocd \
    get secret argocd-initial-admin-secret --output jsonpath="{.data.password}" \
    | base64 --decode)

echo "ArgoCD is ready, you can login using admin:${ARGOCD_PASSWD}"

open https://argo-cd.$DOMAIN


kubectl apply -f argocd-bootstrap.yaml
