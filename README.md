# ⛵ Istio in Action

A hands-on project demonstrating Istio service mesh capabilities on a local Minikube cluster. Built with simple Python microservices to showcase traffic management, security, observability, and resilience features — all running on your laptop.

![Istio](https://img.shields.io/badge/Istio-1.24-466BB0?logo=istio&logoColor=white)
![Kubernetes](https://img.shields.io/badge/Kubernetes-1.30-326CE5?logo=kubernetes&logoColor=white)
![Minikube](https://img.shields.io/badge/Minikube-local-F7B93E?logo=kubernetes&logoColor=white)
![Python](https://img.shields.io/badge/Python-3.12-3776AB?logo=python&logoColor=white)

> 📝 **Read the full walkthrough on Medium:** [Istio in Action: A Hands-On Guide to Service Mesh on Your Laptop](https://medium.com/@sergeiolshanetski/istio-in-action-a-hands-on-guide-to-service-mesh-on-your-laptop-e5ccac34262e)

## 🏗️ Architecture

```
                    ┌─────────────────────────────────────────────┐
                    │              Istio Service Mesh              │
                    │                                             │
  User ──────►  Istio       ┌─────────┐      ┌──────────────┐   │
              Ingress  ────►│Frontend │─────►│  Backend v1  │   │
              Gateway       │  (Web)  │      │  (blue)      │   │
                    │       └─────────┘      └──────────────┘   │
                    │            │                               │
                    │            │            ┌──────────────┐   │
                    │            └───────────►│  Backend v2  │   │
                    │                         │  (green)     │   │
                    │                         └──────────────┘   │
                    │                                             │
                    │  🔒 mTLS    📊 Metrics    🔍 Tracing       │
                    └─────────────────────────────────────────────┘
```

**Frontend** — A web UI that calls the backend and visually shows which version responded (blue for v1, green for v2). Includes a burst mode to send 20 requests and see traffic distribution in real-time.

**Backend v1 / v2** — Identical Flask apps that return version-tagged JSON. The color coding makes traffic splitting immediately visible.

## 📋 What You'll Learn

| Istio Feature | What It Does | Demo Scenario |
|---|---|---|
| **Traffic Splitting** | Route percentages of traffic to different versions | 80/20 canary, 50/50 A/B testing |
| **Header-Based Routing** | Route based on HTTP headers | QA team tests v2 while users see v1 |
| **Fault Injection** | Simulate failures without code changes | Add delays and HTTP errors |
| **Circuit Breaking** | Prevent cascading failures | Limit connections, eject unhealthy hosts |
| **Retry Policy** | Automatic retries for transient failures | 3 retries with timeout |
| **Mutual TLS** | Encrypt all service-to-service traffic | Strict mTLS enforcement |
| **Authorization Policy** | Control which services can communicate | Only frontend can call backend |
| **Observability** | Visualize traffic, traces, and metrics | Kiali, Jaeger, Grafana dashboards |

## 🚀 Quick Start

### Prerequisites

- **macOS** (scripts use Homebrew; adapt for Linux)
- **Docker Desktop** running
- ~8 GB RAM available for the Minikube cluster

### Step 1: Install Tools

```bash
chmod +x scripts/*.sh
./scripts/01-install-prerequisites.sh
```

This installs `minikube`, `istioctl`, and `kubectl` via Homebrew if not already present.

### Step 2: Start Cluster + Install Istio

```bash
./scripts/02-start-cluster.sh
```

Creates a Minikube cluster (`istio-demo` profile) with 4 CPUs and 8 GB RAM, then installs Istio with the `demo` profile (includes all observability addons).

### Step 3: Build & Deploy the Application

```bash
./scripts/03-deploy-app.sh
```

Builds Docker images inside Minikube's Docker daemon (no registry needed), deploys the services, and configures the Istio gateway.

### Step 4: Access the Application

In a **separate terminal**, start port-forwarding:

```bash
kubectl port-forward svc/frontend 9080:8080 -n istio-demo
```

Open **http://localhost:9080** in your browser.

### Step 5: Run the Demo Scenarios

```bash
./scripts/04-demo-scenarios.sh
```

This walks you through each Istio feature interactively, applying different configurations and showing the results.

## 🎮 Demo Scenarios

### 1. Baseline — All Traffic to v1

```bash
kubectl apply -f istio/traffic-v1-only.yaml
```

All requests hit backend v1 (blue). This is your stable production state.

### 2. Canary Deployment — 80% v1, 20% v2

```bash
kubectl apply -f istio/traffic-canary.yaml
```

Gradually introduce v2. Click "Send 20 Requests" in the UI — you should see roughly 4 green (v2) and 16 blue (v1) responses.

### 3. A/B Testing — 50/50 Split

```bash
kubectl apply -f istio/traffic-50-50.yaml
```

Equal split for comparing versions. The progress bar in the UI will show an even blue/green distribution.

### 4. Header-Based Routing

```bash
kubectl apply -f istio/traffic-header-routing.yaml
```

Default traffic goes to v1. Add the `x-version: v2` header to reach v2:

```bash
# Goes to v1
curl http://localhost:9080/api/backend

# Goes to v2
curl -H "x-version: v2" http://localhost:9080/api/backend
```

### 5. Fault Injection

```bash
kubectl apply -f istio/fault-injection.yaml
```

50% of requests get a 3-second delay, 10% get HTTP 503 errors. Test how your application handles failures **without changing any code**.

### 6. Circuit Breaker

```bash
# Replace the normal destination rule with circuit breaker limits
kubectl apply -f istio/circuit-breaker.yaml
```

Limits to 1 concurrent connection. Excess requests get rejected immediately instead of overloading the backend.

### 7. Mutual TLS

```bash
kubectl apply -f istio/peer-authentication.yaml
```

All service-to-service traffic is now encrypted. Verify with:

```bash
istioctl x describe pod $(kubectl get pod -n istio-demo -l app=backend,version=v1 \
  -o jsonpath='{.items[0].metadata.name}') -n istio-demo
```

### 8. Authorization Policy

```bash
kubectl apply -f istio/authorization-policy.yaml
```

Only the frontend service is allowed to call the backend. Any other service in the mesh would be denied.

## 📊 Observability Dashboards

Istio's demo profile includes Kiali, Grafana, and Jaeger out of the box:

```bash
# Interactive menu
./scripts/open-dashboards.sh

# Or open individually
istioctl dashboard kiali     # Service mesh topology
istioctl dashboard grafana   # Metrics & performance
istioctl dashboard jaeger    # Distributed tracing
```

**Kiali** — Visualize the service mesh topology, see real-time traffic flow between services, and monitor health status.

**Grafana** — Pre-built dashboards for Istio mesh metrics: request rates, latencies, error rates, and resource utilization.

**Jaeger** — Trace individual requests across services. See how long each hop takes and identify bottlenecks.

> 💡 **Tip:** Generate traffic first (use the "Send 20 Requests" button in the UI) so the dashboards have data to display.

## 📁 Project Structure

```
istio-in-action/
├── apps/
│   ├── frontend/          # Web UI (Flask) — calls backend, displays version
│   │   ├── app.py
│   │   ├── Dockerfile
│   │   └── requirements.txt
│   └── backend/           # API service (Flask) — returns version-tagged JSON
│       ├── app.py
│       ├── Dockerfile
│       └── requirements.txt
├── k8s/                   # Kubernetes manifests
│   ├── namespace.yaml     # Namespace with Istio injection label
│   ├── backend-v1.yaml    # Backend deployment (version v1)
│   ├── backend-v2.yaml    # Backend deployment (version v2)
│   ├── backend-service.yaml
│   ├── frontend.yaml
│   └── frontend-service.yaml
├── istio/                 # Istio configuration manifests
│   ├── gateway.yaml              # Ingress gateway
│   ├── destination-rule.yaml     # Subsets (v1, v2) + mTLS
│   ├── traffic-v1-only.yaml      # 100% → v1
│   ├── traffic-canary.yaml       # 80% v1 / 20% v2
│   ├── traffic-50-50.yaml        # 50% v1 / 50% v2
│   ├── traffic-header-routing.yaml  # Header-based routing
│   ├── fault-injection.yaml      # Delays + HTTP errors
│   ├── circuit-breaker.yaml      # Connection limits + outlier detection
│   ├── retry-policy.yaml         # Automatic retries
│   ├── peer-authentication.yaml  # Strict mTLS
│   └── authorization-policy.yaml # Service-to-service access control
├── scripts/               # Automation scripts
│   ├── 01-install-prerequisites.sh
│   ├── 02-start-cluster.sh
│   ├── 03-deploy-app.sh
│   ├── 04-demo-scenarios.sh
│   ├── 05-teardown.sh
│   └── open-dashboards.sh
└── docs/
    └── screenshots/       # Add your screenshots here
```

## 🧹 Teardown

```bash
./scripts/05-teardown.sh
```

Deletes the namespace, uninstalls Istio, and removes the Minikube cluster. Your system is back to clean state.

## 💡 Key Takeaways

1. **Traffic management without code changes** — Istio handles routing, splitting, and failover at the infrastructure layer. Your application doesn't need to know about canary deployments or A/B testing.

2. **Security by default** — mTLS encrypts all traffic automatically. Authorization policies enforce zero-trust at the mesh level.

3. **Observability for free** — Distributed tracing, metrics dashboards, and service topology visualization come built-in. No instrumentation code required.

4. **Resilience without libraries** — Circuit breakers, retries, and fault injection are configured declaratively. No need for application-level resilience libraries.

5. **Progressive delivery** — Ship changes safely with canary deployments, test in production with header-based routing, and roll back instantly by changing a YAML file.

## 📚 Resources

- [Istio Documentation](https://istio.io/latest/docs/)
- [Istio Concepts](https://istio.io/latest/docs/concepts/)
- [Envoy Proxy](https://www.envoyproxy.io/) — The data plane proxy that powers Istio
- [Minikube Documentation](https://minikube.sigs.k8s.io/docs/)

## 📝 License

MIT — Use freely for learning, demos, and presentations.
