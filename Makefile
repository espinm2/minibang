# Later List
#   - Setup git repo with configs to install Istio
#   - Create makefile target to create self-signed certs & upload to cluster
#   - Push configs to ArgoCD to automatically configure itself from git repo
#
#
CONTEXT ?= $(shell kubectl config current-context)

.PHONY: minibang
minibang: create_cluster set_config install_argocd expose_argocd
	@echo "🐙 Cluster Created & Configured!"

# Note: --port 8080:80@loadbalancer means anything hitting 
# host port 8080 gets sent to container at port 80.
# Given it matches nodefilter loadbalancer.
.PHONY: create_cluster
create_cluster:
	@echo "🐙 Creating Cluster"
	k3d cluster create miniverse \
		--api-port 6550 \
		--servers 1 \
		--agents 3 \
		--port 8080:80@loadbalancer \
		--wait

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
	@echo -n "Install Argo in $(CONTEXT) cluster? [y/N] " && read ans && [ $${ans:-N} = y ]
	kubectl create namespace argocd
	# TODO: dynamicall get & patch argo-server deployment manifest
	# wget -P manifest https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
	kubectl apply -n argocd -f manifest/install.yaml


# Changing argocd-server to type LoadBalancer
.PHONY: expose_argocd
expose_argocd:
	@echo "🐙 Exposing Argo"
	@echo -n "Expose Argo in $(CONTEXT) cluster? [y/N] " && read ans && [ $${ans:-N} = y ]
	kubectl apply -n argocd -f manifest/argo-ingress.yaml


.PHONY: create_ingress_cert
create_ingress_cert:
	@echo "⛵️ Creating Istio Ingress Cert"
	mkdir -p certs/istio
	openssl req -new -newkey rsa:4096 -days 365 -nodes -x509 \
		-subj "/C=US/ST=MA/L=SOMERVILLE/O=NONE/CN=localhost" \
		-keyout certs/istio/selfsigned.key  -out /certs/istio/selfsigned.crt
