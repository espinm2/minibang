#!/bin/bash

# Skip creation of configmap if already defined
FILE=manifest/argo-cm.yaml
if test -f "$FILE"; then
    echo "manifest/argo-cm.yaml already exist, skipping creation."
    exit 0
fi

echo "Create OAuth App at https://github.com/settings/applications/new"
echo "Params:"
echo "\tApplication Name: miniverse-argocd"
echo "\tHomepage Url: http://localhost:8080/argocd/"
echo "\tCallback Url: http://localhost:8080/argocd/api/dex/callback"

echo "Collecting OAuth info to create argo-cm.yaml"
echo -n Client ID: 
read CLIENT_ID

echo -n Client secret: 
read CLIENT_SECRET


cat > manifest/argo-cm.yaml << EOF
apiVersion: v1
kind: ConfigMap
metadata:
  labels:
    app.kubernetes.io/name: argocd-cm
    app.kubernetes.io/part-of: argocd
  name: argocd-cm
  namespace: argocd
data:
  url: http://localhost:8080/argocd/
  dex.config: |
    connectors:
      - type: github
        id: github
        name: GitHub
        config:
          clientID: $CLIENT_ID
          clientSecret: $CLIENT_SECRET
  repositories: |
    - insecure: true
      insecureIgnoreHostKey: true
      type: git
      url: https://github.com/espinm2/miniverse.git
EOF
