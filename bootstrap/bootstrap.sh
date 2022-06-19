#!/bin/bash

DOMAIN=local

[ -z ${AWS_ACCESS_KEY_ID+x} ] && \
    echo "\${AWS_ACCESS_KEY_ID} for Crossplane not defined"

[ -z ${AWS_SECRET_ACCESS_KEY+x} ] && \
    echo "\${AWS_ACCESS_KEY_ID} for Crossplane not defined"

# Install basic controllers required to bootstrap the cluster

# Install Nginx Ingress
helm upgrade --install ingress-nginx ingress-nginx \
  --repo https://kubernetes.github.io/ingress-nginx \
  --version 4.1.4 \
  --namespace ingress-nginx --create-namespace --wait

kubectl apply -k ../apps/argo-cd/overlays/rancher

kubectl -n argocd rollout status deployment argocd-server

ARGOCD_PASSWD=$(kubectl --namespace argocd \
    get secret argocd-initial-admin-secret --output jsonpath="{.data.password}" \
    | base64 --decode)

printf '\n';printf '*%.0s' {1..80};printf '\n'
printf '# ArgoCD is ready, you can login using admin:%s\n' "${ARGOCD_PASSWD}"
printf '*%.0s' {1..80};printf '\n'

open https://argo-cd.$DOMAIN

# Configure AWS credentials for Crossplane
kubectl create ns crossplane-system

echo "[default]
aws_access_key_id = $AWS_ACCESS_KEY_ID
aws_secret_access_key = $AWS_SECRET_ACCESS_KEY
" | tee crossplane-creds.conf > /dev/null

kubectl -n crossplane-system create secret generic aws-creds \
    --from-file creds=./crossplane-creds.conf

rm crossplane-creds.conf

kubectl apply -f argocd-bootstrap.yaml
