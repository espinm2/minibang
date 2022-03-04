# Minibang: Cluster Creation

This creates a k3d cluster with some common applications installed for local development.

Includes:
1. Istio
2. Dapr
3. Miniverse Repo
  1. Guestbook
  2. NATs

## Requirements

Installation can be done with a package manager like brew.

Tools:
  1. k3d
  2. jq
  3. kubectl


## Usage

1. Create the local cluster with ArgoCD using the following command.
```bash
make minibang
```
2. On your browser go to http://localhost:8080/argocd/applications
3. Sync the dapr application
4. Sync the miniverse-nats application
