#!/bin/bash

DOMAIN=local

#Install basic controllers required to bootstrap the cluster

# Install Nginx Ingress
helm upgrade --install ingress-nginx ingress-nginx \
  --repo https://kubernetes.github.io/ingress-nginx \
  --namespace ingress-nginx --create-namespace --wait


# Install ArgoCD Ingress
helm upgrade --install argocd argo-cd \
    --repo https://argoproj.github.io/argo-helm \
    --namespace argocd --create-namespace \
    --version 4.8.3 \
    --set server.ingress.hosts="{argo-cd.$DOMAIN}" \
    --set server.ingress.enabled=true \
    --set server.extraArgs="{--insecure}" \
    --set server.ingress.ingressClassName=nginx \
    --set controller.args.appResyncPeriod=30

kubectl --namespace argocd rollout status deployment argocd-server

ARGOCD_PASSWD=$(kubectl --namespace argocd \
    get secret argocd-initial-admin-secret --output jsonpath="{.data.password}" \
    | base64 --decode)

echo "ArgoCD is ready, you can login using admin:${ARGOCD_PASSWD}"

open https://argo-cd.$DOMAIN

kubectl apply -f argocd-bootstrap.yaml
