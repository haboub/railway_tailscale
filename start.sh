#!/bin/sh
set -eu

TS_SOCKET="${TS_SOCKET:-/tmp/tailscaled.sock}"
TS_STATE_DIR="${TS_STATE_DIR:-/var/lib/tailscale}"
TS_HOSTNAME="${TS_HOSTNAME:-railway-ts}"
ADVERTISE_EXIT_NODE="${ADVERTISE_EXIT_NODE:-true}"
PORT="${PORT:-8080}"

if [ -z "${TAILSCALE_AUTHKEY:-}" ]; then
  echo "TAILSCALE_AUTHKEY is required" >&2
  exit 1
fi

mkdir -p "$TS_STATE_DIR" "$(dirname "$TS_SOCKET")"

tailscaled \
  --state="${TS_STATE_DIR}/tailscaled.state" \
  --socket="${TS_SOCKET}" \
  --tun=userspace-networking \
  --socks5-server=localhost:1055 \
  --outbound-http-proxy-listen=localhost:1055 &
TAILSCALED_PID=$!

cleanup() {
  kill "$TAILSCALED_PID" 2>/dev/null || true
  wait "$TAILSCALED_PID" 2>/dev/null || true
}
trap cleanup EXIT INT TERM

# Wait for the daemon socket to be ready
i=0
while [ $i -lt 50 ]; do
  if tailscale --socket="${TS_SOCKET}" status >/dev/null 2>&1; then
    break
  fi
  i=$((i + 1))
  sleep 0.2
done

TAILSCALE_UP_FLAGS="--authkey=${TAILSCALE_AUTHKEY} --accept-dns=false --accept-routes=false --hostname=${TS_HOSTNAME} --reset"

if [ "${ADVERTISE_EXIT_NODE}" = "true" ]; then
  TAILSCALE_UP_FLAGS="${TAILSCALE_UP_FLAGS} --advertise-exit-node"
fi

tailscale --socket="${TS_SOCKET}" up ${TAILSCALE_UP_FLAGS}

# Exit if tailscaled stops unexpectedly
( wait "$TAILSCALED_PID"; echo "tailscaled exited" >&2; kill $$ ) 2>/dev/null &

# Minimal HTTP server to satisfy Railway health checks
python3 - <<'PY'
import http.server
import socketserver
import os

class Handler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        body = b"OK"
        self.send_response(200)
        self.send_header("Content-Type", "text/plain")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, fmt, *args):
        return

port = int(os.environ.get("PORT", "8080"))
with socketserver.TCPServer(("", port), Handler) as httpd:
    httpd.serve_forever()
PY
