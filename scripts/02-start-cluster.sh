#!/bin/bash
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()  { echo -e "${GREEN}[INFO]${NC} $1"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

echo "============================================"
echo "  Istio in Action — Cluster Setup"
echo "============================================"
echo ""

PROFILE="istio-demo"

# Start minikube with enough resources for Istio
if minikube status -p "$PROFILE" &> /dev/null; then
    info "Minikube cluster '$PROFILE' is already running"
else
    info "Starting Minikube cluster '$PROFILE'..."
    minikube start \
        --profile="$PROFILE" \
        --cpus=4 \
        --memory=8192 \
        --driver=docker \
        --kubernetes-version=v1.30.0
    info "Minikube cluster started"
fi

# Set kubectl context
info "Setting kubectl context to minikube profile '$PROFILE'..."
kubectl config use-context "$PROFILE"

# Install Istio
info "Installing Istio with demo profile..."
istioctl install --set profile=demo -y

# Verify Istio installation
info "Verifying Istio installation..."
kubectl -n istio-system wait --for=condition=ready pod -l app=istiod --timeout=120s
kubectl -n istio-system wait --for=condition=ready pod -l app=istio-ingressgateway --timeout=120s

info "Istio components:"
kubectl get pods -n istio-system

echo ""
info "Cluster and Istio are ready!"
echo ""
echo "Next step: Run ./scripts/03-deploy-app.sh"
