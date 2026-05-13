#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

info()  { echo -e "${GREEN}[INFO]${NC} $1"; }
header() { echo -e "\n${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"; echo -e "${CYAN}  $1${NC}"; echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"; }

FRONTEND_URL="http://localhost:9080"

wait_for_user() {
    echo ""
    echo -e "${YELLOW}Press Enter to continue to the next scenario...${NC}"
    read -r
}

send_requests() {
    local count=${1:-10}
    local v1=0 v2=0 errors=0
    for i in $(seq 1 "$count"); do
        resp=$(curl -s "$FRONTEND_URL/api/backend" 2>/dev/null || echo '{"version":"error"}')
        version=$(echo "$resp" | python3 -c "import sys,json; print(json.load(sys.stdin).get('version','error'))" 2>/dev/null || echo "error")
        case $version in
            v1) v1=$((v1+1)) ;;
            v2) v2=$((v2+1)) ;;
            *)  errors=$((errors+1)) ;;
        esac
    done
    echo -e "  Results: ${BLUE}v1=$v1${NC} | ${GREEN}v2=$v2${NC} | ${RED}errors=$errors${NC} (out of $count requests)"
}

echo "============================================"
echo "  Istio in Action — Demo Scenarios"
echo "============================================"
echo ""
echo "Make sure you have port-forward running:"
echo "  kubectl port-forward svc/frontend 9080:8080 -n istio-demo"
echo ""
echo "And open the UI at: $FRONTEND_URL"
wait_for_user

# ─────────────────────────────────────────────
# Scenario 1: All traffic to v1
# ─────────────────────────────────────────────
header "Scenario 1: All Traffic to v1 (Baseline)"
echo "Routing 100% of traffic to backend v1."
echo "This is the stable production baseline."
kubectl apply -f "$PROJECT_DIR/istio/traffic-v1-only.yaml"
sleep 2
info "Sending 20 requests..."
send_requests 20
echo ""
echo "➡️  Expected: All requests go to v1"
wait_for_user

# ─────────────────────────────────────────────
# Scenario 2: Canary deployment (80/20)
# ─────────────────────────────────────────────
header "Scenario 2: Canary Deployment (80% v1 / 20% v2)"
echo "Gradually introducing v2 to a small percentage of traffic."
echo "This is how you safely roll out a new version."
kubectl apply -f "$PROJECT_DIR/istio/traffic-canary.yaml"
sleep 2
info "Sending 50 requests..."
send_requests 50
echo ""
echo "➡️  Expected: ~80% v1, ~20% v2"
wait_for_user

# ─────────────────────────────────────────────
# Scenario 3: 50/50 split (A/B testing)
# ─────────────────────────────────────────────
header "Scenario 3: A/B Testing (50% v1 / 50% v2)"
echo "Equal traffic split for comparing two versions."
kubectl apply -f "$PROJECT_DIR/istio/traffic-50-50.yaml"
sleep 2
info "Sending 50 requests..."
send_requests 50
echo ""
echo "➡️  Expected: ~50% v1, ~50% v2"
wait_for_user

# ─────────────────────────────────────────────
# Scenario 4: Header-based routing
# ─────────────────────────────────────────────
header "Scenario 4: Header-Based Routing"
echo "Requests with 'x-version: v2' header go to v2."
echo "All other requests go to v1."
echo "Use case: QA team tests v2 while production users see v1."
kubectl apply -f "$PROJECT_DIR/istio/traffic-header-routing.yaml"
sleep 2

echo ""
info "Regular request (no header):"
curl -s "$FRONTEND_URL/api/backend" | python3 -m json.tool 2>/dev/null || echo "(request failed)"

echo ""
info "Request with x-version: v2 header:"
curl -s -H "x-version: v2" "$FRONTEND_URL/api/backend" | python3 -m json.tool 2>/dev/null || echo "(request failed)"
wait_for_user

# ─────────────────────────────────────────────
# Scenario 5: Fault injection
# ─────────────────────────────────────────────
header "Scenario 5: Fault Injection"
echo "Injecting 3-second delays (50%) and HTTP 503 errors (10%)."
echo "Use case: Testing how your application handles failures."
kubectl apply -f "$PROJECT_DIR/istio/fault-injection.yaml"
sleep 2
info "Sending 20 requests (some will be slow or fail)..."
send_requests 20
echo ""
echo "➡️  Expected: Some delays and ~10% errors"
wait_for_user

# ─────────────────────────────────────────────
# Scenario 6: Circuit breaker
# ─────────────────────────────────────────────
header "Scenario 6: Circuit Breaker"
echo "Limiting the backend to 1 concurrent connection."
echo "Excess requests will be rejected immediately (503) instead of overloading."
echo "Use case: Prevent cascading failures when a service is slow."

# Reset routing to v1-only first
kubectl apply -f "$PROJECT_DIR/istio/traffic-v1-only.yaml"
kubectl apply -f "$PROJECT_DIR/istio/circuit-breaker.yaml"
sleep 2
info "Sending 20 rapid requests (some will be rejected)..."
send_requests 20
echo ""
echo "➡️  Expected: Some errors from the circuit breaker rejecting excess connections"

# Restore normal destination rule
kubectl apply -f "$PROJECT_DIR/istio/destination-rule.yaml"
wait_for_user

# ─────────────────────────────────────────────
# Scenario 7: Retry policy
# ─────────────────────────────────────────────
header "Scenario 7: Retry Policy"
echo "Applying automatic retries: 3 attempts with 2s per-try timeout."
echo "Use case: Handle transient failures without changing application code."
kubectl apply -f "$PROJECT_DIR/istio/traffic-v1-only.yaml"
kubectl apply -f "$PROJECT_DIR/istio/retry-policy.yaml"
sleep 2
info "Sending 10 requests (retries happen transparently if any fail)..."
send_requests 10
echo ""
echo "➡️  Istio retries failed requests automatically — the app never sees transient errors."

# Restore default routing
kubectl apply -f "$PROJECT_DIR/istio/traffic-v1-only.yaml"
kubectl apply -f "$PROJECT_DIR/istio/destination-rule.yaml"
wait_for_user

# ─────────────────────────────────────────────
# Scenario 8: mTLS verification
# ─────────────────────────────────────────────
header "Scenario 8: Mutual TLS (mTLS)"
echo "Verifying that all traffic between services is encrypted."

# Reset to normal routing first
kubectl apply -f "$PROJECT_DIR/istio/traffic-v1-only.yaml"
kubectl apply -f "$PROJECT_DIR/istio/destination-rule.yaml"
sleep 2

# Apply strict mTLS
kubectl apply -f "$PROJECT_DIR/istio/peer-authentication.yaml"
sleep 2

info "Checking mTLS status..."
istioctl x describe pod "$(kubectl get pod -n istio-demo -l app=backend,version=v1 -o jsonpath='{.items[0].metadata.name}')" -n istio-demo 2>/dev/null || echo "(istioctl describe not available)"
echo ""
echo "➡️  All service-to-service traffic is now encrypted with mTLS"
wait_for_user

# ─────────────────────────────────────────────
# Scenario 9: Authorization policy
# ─────────────────────────────────────────────
header "Scenario 9: Authorization Policy"
echo "Applying policy: Only the frontend service can call the backend."
kubectl apply -f "$PROJECT_DIR/istio/authorization-policy.yaml"
sleep 3
info "Testing access through frontend (should work):"
send_requests 5
echo ""
info "Direct backend call from outside the mesh would be denied."
echo "➡️  Zero-trust: services must be explicitly allowed to communicate"
wait_for_user

# ─────────────────────────────────────────────
# Cleanup: Reset to baseline
# ─────────────────────────────────────────────
header "Resetting to Baseline"
kubectl apply -f "$PROJECT_DIR/istio/traffic-v1-only.yaml"
kubectl apply -f "$PROJECT_DIR/istio/destination-rule.yaml"
kubectl delete authorizationpolicy backend-allow-frontend-only -n istio-demo 2>/dev/null || true
kubectl delete peerauthentication strict-mtls -n istio-demo 2>/dev/null || true
info "Reset complete — all traffic going to v1"

echo ""
echo "============================================"
echo "  Demo Complete!"
echo "============================================"
echo ""
echo "Explore more:"
echo "  • Open Kiali dashboard:   istioctl dashboard kiali"
echo "  • Open Grafana dashboard: istioctl dashboard grafana"
echo "  • Open Jaeger tracing:    istioctl dashboard jaeger"
echo ""
echo "Tear down: ./scripts/05-teardown.sh"
