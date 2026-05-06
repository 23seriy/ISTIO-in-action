#!/bin/bash
set -euo pipefail

GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'

info()  { echo -e "${GREEN}[INFO]${NC} $1"; }

echo "============================================"
echo "  Istio in Action — Observability Dashboards"
echo "============================================"
echo ""

echo "Choose a dashboard to open:"
echo ""
echo "  1) Kiali    — Service mesh topology & health"
echo "  2) Grafana  — Metrics & performance dashboards"
echo "  3) Jaeger   — Distributed tracing"
echo "  4) All      — Open all dashboards"
echo ""
read -p "Enter choice [1-4]: " choice

case $choice in
    1)
        info "Opening Kiali dashboard..."
        istioctl dashboard kiali
        ;;
    2)
        info "Opening Grafana dashboard..."
        istioctl dashboard grafana
        ;;
    3)
        info "Opening Jaeger dashboard..."
        istioctl dashboard jaeger
        ;;
    4)
        info "Opening all dashboards in background..."
        istioctl dashboard kiali &
        sleep 2
        istioctl dashboard grafana &
        sleep 2
        istioctl dashboard jaeger &
        echo ""
        info "All dashboards opened. Press Ctrl+C to close them."
        wait
        ;;
    *)
        echo "Invalid choice"
        exit 1
        ;;
esac
