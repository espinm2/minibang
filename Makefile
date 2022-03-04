
SHELL=/bin/bash
CONTEXT ?= $(shell kubectl config current-context)

.PHONY: minibang
minibang: 
	make create_cluster
	make set_config
	make install_argocd
	make expose_argocd
	make configure_apps_argocd
	@echo "🎉 Cluster Created"
	@echo "👉 Argo reachable at http://localhost:8080/argocd"


# Requires jq
# 	Mac: brew install jq
# Wait until all pods ready
.PHONY: wait_until_ready
wait_until_ready:
	while [[ $$(kubectl get pods --all-namespaces -o json | jq -r '.items[] | select((.status.phase != "Running") and (.status.phase != "Succeeded")) | .metadata.namespace + "/" + .metadata.name' | wc -l) -ne 0 ]]; do echo "Waiting for pods to stablize." && sleep 10; done


# Requires k3d 
# 	Mac: brew install k3d
.PHONY: create_cluster
create_cluster:
	@echo "🐙 Creating Cluster"
	k3d cluster create miniverse \
		--api-port 6550 \
		--servers 1 \
		--agents 1 \
		--port 8080:80@loadbalancer \
		--port 8443:443@loadbalancer \
		--wait
	make wait_until_ready


.PHONY: set_config
set_config:
	@echo "🐙 Setting Kubeconfig"
	k3d kubeconfig write miniverse # creates ~/.k3d/kubeconfig-miniverse.yaml
	cp ~/.kube/config ~/.kube/config.backup # I don't merge to avoid mishaps
	cp ~/.k3d/kubeconfig-miniverse.yaml ~/.kube/config 


.PHONY: delete_cluster
delete_cluster:
	@echo "💥 Deleting Cluster"
	@echo -n "Delete $(CONTEXT) cluster? [y/N] " && read ans && [ $${ans:-N} = y ]
	k3d cluster delete miniverse


# Requires install for argocd cli 
# 	Mac: brew install argocd
.PHONY: install_argocd
install_argocd:
	@echo "🐙 Installing Argo"
	kubectl create namespace argocd
	kubectl apply -n argocd -f manifest/argo/argo-install-v2.yaml
	kubectl apply -n argocd -f manifest/argo/argo-cm.yaml
	kubectl apply -n argocd -f manifest/argo/argo-rbac-cm.yaml
	make wait_until_ready


# Adding Ingress to ArgoCD
.PHONY: expose_argocd
expose_argocd:
	@echo "🐙 Exposing Argo"
	kubectl apply -n argocd -f manifest/argo/argo-ingress.yaml


.PHONY: configure_apps_argocd
configure_apps_argocd:
	@echo "🐙 Configuring all apps in ArgoCD"
	@kubectl apply -n argocd -f manifest/dapr/app.yaml
	@kubectl apply -n argocd -f manifest/guestbook/app.yaml
	@kubectl apply -n argocd -f manifest/nats/app.yaml	
	@kubectl apply -n argocd -f manifest/istio/base/app.yaml	
	@kubectl apply -n argocd -f manifest/istio/gateway/app.yaml	
	@kubectl apply -n argocd -f manifest/istio/istiod/app.yaml	
	@echo "Configured!"


.PHONY: install_istio
install_istio:
	@echo "⛵️ Installing Istio"
	istioctl install -y
	make wait_until_ready


.PHONY: create_ingress_cert
create_ingress_cert:
	@echo "⛵️ Creating Istio Ingress Cert"
	mkdir -p certs/istio
	openssl req -new -newkey rsa:4096 -days 365 -nodes -x509 \
		-subj "/C=US/ST=MA/L=SOMERVILLE/O=NONE/CN=localhost" \
		-keyout certs/istio/selfsigned.key  -out /certs/istio/selfsigned.crt
