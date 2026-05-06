#!/bin/bash
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()  { echo -e "${GREEN}[INFO]${NC} $1"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

echo "============================================"
echo "  Istio in Action — Prerequisites Installer"
echo "============================================"
echo ""

# Check OS
if [[ "$(uname)" != "Darwin" ]]; then
    error "This script is designed for macOS. Adjust package manager commands for your OS."
    exit 1
fi

# Check Homebrew
if ! command -v brew &> /dev/null; then
    error "Homebrew is required. Install it from https://brew.sh"
    exit 1
fi

# Install minikube
if command -v minikube &> /dev/null; then
    info "minikube already installed: $(minikube version --short)"
else
    info "Installing minikube..."
    brew install minikube
    info "minikube installed: $(minikube version --short)"
fi

# Install istioctl
if command -v istioctl &> /dev/null; then
    info "istioctl already installed: $(istioctl version --remote=false 2>/dev/null)"
else
    info "Installing istioctl..."
    brew install istioctl
    info "istioctl installed: $(istioctl version --remote=false 2>/dev/null)"
fi

# Verify kubectl
if command -v kubectl &> /dev/null; then
    info "kubectl already installed: $(kubectl version --client --short 2>/dev/null || kubectl version --client 2>/dev/null | head -1)"
else
    info "Installing kubectl..."
    brew install kubectl
fi

# Verify Docker
if command -v docker &> /dev/null; then
    info "Docker already installed: $(docker --version)"
else
    error "Docker is required. Install Docker Desktop from https://docker.com"
    exit 1
fi

echo ""
info "All prerequisites installed successfully!"
echo ""
echo "Next step: Run ./scripts/02-start-cluster.sh"
