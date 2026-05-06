import os
import requests
from flask import Flask, render_template_string, request

app = Flask(__name__)

BACKEND_URL = os.environ.get("BACKEND_URL", "http://backend:8080")

HTML_TEMPLATE = """
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Istio in Action - Frontend</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: 'Segoe UI', system-ui, -apple-system, sans-serif;
            background: #0f172a;
            color: #e2e8f0;
            min-height: 100vh;
            display: flex;
            flex-direction: column;
            align-items: center;
            padding: 2rem;
        }
        h1 {
            font-size: 2rem;
            margin-bottom: 0.5rem;
            background: linear-gradient(135deg, #38bdf8, #818cf8);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
        }
        .subtitle { color: #94a3b8; margin-bottom: 2rem; }
        .card {
            background: #1e293b;
            border-radius: 12px;
            padding: 2rem;
            max-width: 600px;
            width: 100%;
            border: 1px solid #334155;
            margin-bottom: 1rem;
        }
        .version-badge {
            display: inline-block;
            padding: 0.25rem 0.75rem;
            border-radius: 9999px;
            font-weight: 700;
            font-size: 1.1rem;
            margin-bottom: 1rem;
        }
        .v1 { background: #1e40af; color: #93c5fd; }
        .v2 { background: #166534; color: #86efac; }
        .error { background: #991b1b; color: #fca5a5; }
        .info-row {
            display: flex;
            justify-content: space-between;
            padding: 0.5rem 0;
            border-bottom: 1px solid #334155;
        }
        .info-label { color: #94a3b8; }
        .info-value { color: #f1f5f9; font-family: monospace; }
        .message {
            font-size: 1.25rem;
            margin: 1rem 0;
            padding: 1rem;
            border-radius: 8px;
            text-align: center;
        }
        .message.blue { background: rgba(59, 130, 246, 0.15); border: 1px solid #3b82f6; }
        .message.green { background: rgba(34, 197, 94, 0.15); border: 1px solid #22c55e; }
        .message.red { background: rgba(239, 68, 68, 0.15); border: 1px solid #ef4444; }
        button {
            background: linear-gradient(135deg, #3b82f6, #6366f1);
            color: white;
            border: none;
            padding: 0.75rem 2rem;
            border-radius: 8px;
            font-size: 1rem;
            cursor: pointer;
            margin-top: 1rem;
            transition: opacity 0.2s;
        }
        button:hover { opacity: 0.9; }
        .counter { color: #94a3b8; font-size: 0.85rem; margin-top: 1.5rem; }
        .bar-container { display: flex; height: 8px; border-radius: 4px; overflow: hidden; margin-top: 0.5rem; }
        .bar-v1 { background: #3b82f6; }
        .bar-v2 { background: #22c55e; }
        #history {
            max-width: 600px; width: 100%;
            margin-top: 1rem;
        }
        .history-item {
            display: flex; align-items: center; gap: 0.5rem;
            padding: 0.25rem 0; font-size: 0.85rem; color: #94a3b8;
        }
        .dot { width: 8px; height: 8px; border-radius: 50%; }
        .dot.blue { background: #3b82f6; }
        .dot.green { background: #22c55e; }
        .dot.red { background: #ef4444; }
    </style>
</head>
<body>
    <h1>⛵ Istio in Action</h1>
    <p class="subtitle">Service Mesh Traffic Demo</p>

    <div class="card" id="response-card">
        <p style="color: #64748b; text-align: center;">Click the button to call the backend service</p>
    </div>

    <button onclick="callBackend()">🔄 Call Backend Service</button>
    <button onclick="runBurst()" style="background: linear-gradient(135deg, #6366f1, #a855f7);">
        ⚡ Send 20 Requests
    </button>

    <div class="counter" id="counter"></div>
    <div class="bar-container" id="bar" style="display:none; max-width: 600px; width: 100%;"></div>

    <div id="history"></div>

    <script>
        let counts = { v1: 0, v2: 0, error: 0 };
        let history = [];

        async function callBackend() {
            try {
                const res = await fetch('/api/backend');
                const data = await res.json();
                counts[data.version] = (counts[data.version] || 0) + 1;
                history.unshift(data);
                if (history.length > 20) history.pop();
                renderResponse(data);
            } catch (err) {
                counts.error++;
                renderError(err.message);
            }
            renderStats();
        }

        async function runBurst() {
            for (let i = 0; i < 20; i++) {
                await callBackend();
                await new Promise(r => setTimeout(r, 200));
            }
        }

        function renderResponse(data) {
            const vclass = data.version === 'v1' ? 'v1' : 'v2';
            const mclass = data.color || 'blue';
            document.getElementById('response-card').innerHTML = `
                <span class="version-badge ${vclass}">${data.version.toUpperCase()}</span>
                <div class="message ${mclass}">${data.message}</div>
                <div class="info-row"><span class="info-label">Hostname</span><span class="info-value">${data.hostname}</span></div>
                <div class="info-row"><span class="info-label">Trace ID</span><span class="info-value">${data.headers['x-b3-traceid'] || 'N/A'}</span></div>
            `;
        }

        function renderError(msg) {
            document.getElementById('response-card').innerHTML = `
                <span class="version-badge error">ERROR</span>
                <div class="message red">${msg}</div>
            `;
        }

        function renderStats() {
            const total = counts.v1 + counts.v2 + counts.error;
            document.getElementById('counter').textContent =
                `Total: ${total} | v1: ${counts.v1} (${pct(counts.v1, total)}) | v2: ${counts.v2} (${pct(counts.v2, total)}) | errors: ${counts.error}`;

            const bar = document.getElementById('bar');
            bar.style.display = 'flex';
            bar.innerHTML = `
                <div class="bar-v1" style="width:${pct(counts.v1, total)}"></div>
                <div class="bar-v2" style="width:${pct(counts.v2, total)}"></div>
            `;

            const hEl = document.getElementById('history');
            hEl.innerHTML = history.slice(0, 10).map(d => `
                <div class="history-item">
                    <div class="dot ${d.color}"></div>
                    <span>${d.version} — ${d.hostname}</span>
                </div>
            `).join('');
        }

        function pct(n, total) { return total ? Math.round(n/total*100) + '%' : '0%'; }
    </script>
</body>
</html>
"""


@app.route("/")
def index():
    return render_template_string(HTML_TEMPLATE)


PROPAGATED_HEADERS = [
    "x-version",
    "x-request-id",
    "x-b3-traceid",
    "x-b3-spanid",
    "x-b3-parentspanid",
    "x-b3-sampled",
    "x-b3-flags",
    "x-ot-span-context",
]


@app.route("/api/backend")
def proxy_backend():
    try:
        headers = {h: request.headers[h] for h in PROPAGATED_HEADERS if h in request.headers}
        resp = requests.get(f"{BACKEND_URL}/api/data", headers=headers, timeout=5)
        return resp.json()
    except requests.exceptions.Timeout:
        return {"version": "error", "color": "red", "message": "Backend timeout!", "hostname": "N/A", "headers": {}}, 504
    except Exception as e:
        return {"version": "error", "color": "red", "message": str(e), "hostname": "N/A", "headers": {}}, 502


@app.route("/health")
def health():
    return {"status": "healthy", "service": "frontend"}


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)
