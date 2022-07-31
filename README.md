# Platform Demo

End-to-end Internal Developer Platform proof of concept. Boots a local k3s management cluster, installs the control plane (ArgoCD + Crossplane + KubeVela + cert-manager + Prometheus) via GitOps, then provisions a real EKS cluster in AWS with the same control plane installed — all through a single Crossplane Composite Resource. Developers ship apps via KubeVela `Application` manifests; ingress, TLS, and exposure are handled by traits.

## What it demonstrates

- **Kubernetes as universal control plane API.** Custom CRDs (`aws.demo.com/v1alpha1/Cluster`, `services.demo.com/v1alpha1/IRSA`, `services.demo.com/v1alpha1/Network`) drive AWS infrastructure through Crossplane Compositions — no Terraform.
- **GitOps from t=0.** Local cluster bootstrap is the only imperative step. After ArgoCD comes up it installs and reconciles everything else from this repo (App-of-Apps pattern under `apps/argo-cd`).
- **Developer-facing abstractions over Kubernetes.** KubeVela `TraitDefinition`s (`backend`, `frontend`, `expose`, `ingress-1-20`, `nginx-ssl`, `autoscaler`) let app authors declare an `Application` without writing Deployment / Service / Ingress / Certificate YAML.
- **Cross-cluster control plane.** The remote EKS cluster created by Crossplane is itself an ArgoCD-managed cluster — same App-of-Apps tree, same definitions, no cluster-specific tooling.

## Architecture

```
┌───────────────────────────────────────────────────────────┐
│  Local k3s (Rancher Desktop) — management cluster         │
│  ┌─────────────────────────────────────────────────────┐  │
│  │ ingress-nginx  +  ArgoCD  +  Crossplane             │  │
│  │ KubeVela  +  cert-manager  +  Prometheus            │  │
│  └─────────────────────────────────────────────────────┘  │
│                          │                                │
│       Crossplane XR: Cluster (aws.demo.com/v1alpha1)      │
│                          │                                │
└──────────────────────────┼────────────────────────────────┘
                           ▼
┌───────────────────────────────────────────────────────────┐
│  EKS (AWS) — workload cluster                             │
│  ┌─────────────────────────────────────────────────────┐  │
│  │ VPC / subnets / SG / IRSA / OIDC provider           │  │
│  │ + same control plane (ArgoCD, KubeVela, cert-mgr)   │  │
│  │ + workload apps (yelb demo)                         │  │
│  └─────────────────────────────────────────────────────┘  │
└───────────────────────────────────────────────────────────┘
```

## Stack

ArgoCD, Crossplane, KubeVela, cert-manager (Let's Encrypt), ingress-nginx, Prometheus, metrics-server, AWS Node Termination Handler. AWS EKS, VPC, IAM/OIDC. Helm, Kustomize, App-of-Apps.

## Quickstart

Prerequisites: Rancher Desktop (or any k3s), `kubectl`, `helm`, AWS credentials with EKS provisioning permissions.

```bash
export AWS_ACCESS_KEY_ID=...
export AWS_SECRET_ACCESS_KEY=...

cd bootstrap
./bootstrap.sh
```

The script installs ingress-nginx and ArgoCD into the local cluster, hands AWS creds to Crossplane as a Secret, then installs the `bootstrap-cluster` Helm chart which seeds the App-of-Apps tree. Everything after that reconciles from Git.

To provision the remote EKS cluster:

```bash
kubectl apply -f custom-resources/eksCluster.yaml
```

To ship an app to the EKS cluster:

```bash
kubectl apply -f custom-resources/application.yaml   # yelb demo
```

## Repository layout

| Path | Contents |
|------|----------|
| `bootstrap/` | One-shot local cluster bootstrap (ingress-nginx, ArgoCD seed, Crossplane creds) |
| `apps/argo-cd/` | ArgoCD overlays (Kustomize) for both local and EKS contexts |
| `apps/crossplane-config/`, `apps/crossplane-providers/` | Crossplane provider + config installation |
| `apps/crossplane-xr/` | Composite Resource Definitions and Compositions (Cluster, IRSA, Network) |
| `apps/kubevela-definitions/` | KubeVela `ComponentDefinition`s (backend, frontend) and `TraitDefinition`s (expose, ingress, nginx-ssl) |
| `eks/` | Workload-cluster manifests (cert-manager, kubevela, prometheus, etc.) — reconciled by remote ArgoCD |
| `rancher/` | Management-cluster overlays for the same set of components |
| `custom-resources/` | Example XRs the platform consumes — provision an EKS cluster, an IRSA role, or ship a yelb `Application` |

## License

Apache-2.0 (see `LICENSE`).
