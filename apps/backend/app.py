import os
import time
import random
from flask import Flask, jsonify, request

app = Flask(__name__)

VERSION = os.environ.get("APP_VERSION", "v1")
COLOR = os.environ.get("APP_COLOR", "blue")
HOSTNAME = os.environ.get("HOSTNAME", "unknown")

# Simulate occasional slowness for circuit breaker demos
SIMULATE_DELAY = os.environ.get("SIMULATE_DELAY", "false").lower() == "true"
DELAY_PROBABILITY = float(os.environ.get("DELAY_PROBABILITY", "0.0"))
DELAY_SECONDS = float(os.environ.get("DELAY_SECONDS", "5.0"))


@app.route("/api/data")
def get_data():
    # Optional: simulate delay for resilience testing
    if SIMULATE_DELAY and random.random() < DELAY_PROBABILITY:
        time.sleep(DELAY_SECONDS)

    return jsonify({
        "version": VERSION,
        "color": COLOR,
        "message": f"Hello from Backend {VERSION}!",
        "hostname": HOSTNAME,
        "headers": {
            "x-request-id": request.headers.get("x-request-id", ""),
            "x-b3-traceid": request.headers.get("x-b3-traceid", ""),
        }
    })


@app.route("/health")
def health():
    return jsonify({"status": "healthy", "version": VERSION})


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)
