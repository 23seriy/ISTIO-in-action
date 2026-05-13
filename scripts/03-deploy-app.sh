#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()  { echo -e "${GREEN}[INFO]${NC} $1"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }

PROFILE="istio-demo"

echo "============================================"
echo "  Istio in Action — Deploy Application"
echo "============================================"
echo ""

# Point Docker to Minikube's daemon so images are available to the cluster
info "Configuring Docker to use Minikube's daemon..."
eval $(minikube -p "$PROFILE" docker-env)

# Build images inside Minikube
info "Building backend image..."
docker build -t istio-demo/backend:latest "$PROJECT_DIR/apps/backend"

info "Building frontend image..."
docker build -t istio-demo/frontend:latest "$PROJECT_DIR/apps/frontend"

# Create namespace with Istio injection
info "Creating namespace with Istio sidecar injection..."
kubectl apply -f "$PROJECT_DIR/k8s/namespace.yaml"

# Deploy backend v1, v2, and frontend
info "Deploying backend v1..."
kubectl apply -f "$PROJECT_DIR/k8s/backend-v1.yaml"

info "Deploying backend v2..."
kubectl apply -f "$PROJECT_DIR/k8s/backend-v2.yaml"

info "Deploying backend service..."
kubectl apply -f "$PROJECT_DIR/k8s/backend-service.yaml"

info "Deploying frontend..."
kubectl apply -f "$PROJECT_DIR/k8s/frontend.yaml"

info "Deploying frontend service..."
kubectl apply -f "$PROJECT_DIR/k8s/frontend-service.yaml"

# Apply Istio gateway
info "Applying Istio gateway..."
kubectl apply -f "$PROJECT_DIR/istio/gateway.yaml"

# Apply destination rules
info "Applying destination rules..."
kubectl apply -f "$PROJECT_DIR/istio/destination-rule.yaml"

# Default: route all traffic to v1
info "Applying default routing (100% to v1)..."
kubectl apply -f "$PROJECT_DIR/istio/traffic-v1-only.yaml"

# Restart deployments so rebuilt images are picked up on redeploy
info "Restarting deployments to pick up latest images..."
kubectl rollout restart deployment/backend-v1 -n istio-demo
kubectl rollout restart deployment/backend-v2 -n istio-demo
kubectl rollout restart deployment/frontend -n istio-demo

# Wait for pods
info "Waiting for pods to be ready..."
kubectl -n istio-demo wait --for=condition=ready pod -l app=backend --timeout=120s
kubectl -n istio-demo wait --for=condition=ready pod -l app=frontend --timeout=120s

echo ""
info "Application deployed successfully!"
echo ""
kubectl get pods -n istio-demo
echo ""

# Get access URL
info "To access the application, run in a separate terminal:"
echo ""
echo "  minikube tunnel -p $PROFILE"
echo ""
echo "Then get the external IP:"
echo ""
echo "  kubectl get svc istio-ingressgateway -n istio-system"
echo ""
echo "Or use port-forward for quick access:"
echo ""
echo "  kubectl port-forward svc/frontend 9080:8080 -n istio-demo"
echo ""
echo "Then open: http://localhost:9080"
echo ""
echo "Next step: Run ./scripts/04-demo-scenarios.sh for guided demos"
