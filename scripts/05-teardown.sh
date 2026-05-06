#!/bin/bash
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()  { echo -e "${GREEN}[INFO]${NC} $1"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }

PROFILE="istio-demo"

echo "============================================"
echo "  Istio in Action — Teardown"
echo "============================================"
echo ""

read -p "This will delete the Minikube cluster '$PROFILE'. Continue? (y/N) " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    info "Deleting namespace..."
    kubectl delete namespace istio-demo --ignore-not-found

    info "Uninstalling Istio..."
    istioctl uninstall --purge -y 2>/dev/null || true
    kubectl delete namespace istio-system --ignore-not-found

    info "Stopping and deleting Minikube cluster..."
    minikube delete -p "$PROFILE"

    info "Teardown complete!"
else
    warn "Teardown cancelled."
fi
