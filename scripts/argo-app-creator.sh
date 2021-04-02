#!/bin/bash

# Creates the miniverse app in argo
cat > manifest/argo-app.yaml << EOF
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: miniverse
  namespace: argocd
spec:
  destination:
    server: https://kubernetes.default.svc
  project: default
  source:
    path: local
    repoURL: https://github.com/espinm2/miniverse.git
    targetRevision: HEAD
  syncPolicy: {}
EOF
