#!/usr/bin/env python3
"""
VRM custom dashboard - local server + API proxy.

Why a server (and not just an HTML file)?
  - The VRM API does not send permissive CORS headers, so a browser page
    cannot call vrmapi.victronenergy.com directly. This tiny server proxies
    the calls.
  - Your access token stays here on the server side and is never exposed to
    the browser / front-end.

Setup (one time):
  1. In VRM: Preferences -> Integrations -> Access tokens -> create a
     "Personal access token". Copy it.
  2. Run:
        export VRM_TOKEN="paste-your-token-here"
        python3 vrm_dashboard.py
  3. Open the URL it prints (default http://localhost:8787).

Environment variables:
  VRM_TOKEN       (required)  your VRM personal access token
  VRM_SITE        (optional)  installation id. Default: 931375
  VRM_TOKEN_KIND  (optional)  "Token" (personal access token, default) or "Bearer"
  PORT            (optional)  default 8787
"""

import json
import os
import ssl
import sys
import threading
import time
import urllib.request
import urllib.error
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import urlparse

VRM_BASE = "https://vrmapi.victronenergy.com/v2"
HERE = Path(__file__).resolve().parent

TOKEN = os.environ.get("VRM_TOKEN", "").strip()
SITE = os.environ.get("VRM_SITE", "931375").strip()
TOKEN_KIND = os.environ.get("VRM_TOKEN_KIND", "Token").strip()
PORT = int(os.environ.get("PORT", "8787"))  # 0 = let the OS pick a free port

# Auto-stop: when enabled, the page sends heartbeats and the server shuts itself
# down a few seconds after they stop (i.e. the browser tab was closed). It still
# survives a page refresh, since that gap is shorter than IDLE_TIMEOUT.
AUTOSTOP = os.environ.get("VRM_AUTOSTOP") == "1"
IDLE_TIMEOUT = float(os.environ.get("VRM_IDLE_TIMEOUT", "10"))  # seconds of silence => stop
STARTUP_GRACE = 45.0  # seconds to wait for the first heartbeat before giving up
STATE = {"last_beat": time.time(), "beat_seen": False, "started": time.time()}
URL_FILE = HERE / ".vrm_url"

# Endpoints the front-end is allowed to ask for, mapped to the real VRM path.
# Add more here if you want to surface additional widgets.
ALLOWED = {
    "diagnostics": f"/installations/{SITE}/diagnostics",
    "stats":       f"/installations/{SITE}/stats",
    "overallstats": f"/installations/{SITE}/overallstats",
    "system-overview": f"/installations/{SITE}/system-overview",
}


def build_ssl_context() -> ssl.SSLContext:
    """
    Build a verifying SSL context that works across setups.
      - VRM_INSECURE=1 disables verification (escape hatch; not recommended).
      - VRM_CA_FILE=/path/to/cacert.pem uses an explicit CA bundle.
      - else prefer certifi if installed, otherwise the system default.
    """
    if os.environ.get("VRM_INSECURE") == "1":
        return ssl._create_unverified_context()
    ca = os.environ.get("VRM_CA_FILE", "").strip()
    if ca:
        return ssl.create_default_context(cafile=ca)
    try:
        import certifi  # type: ignore
        return ssl.create_default_context(cafile=certifi.where())
    except Exception:
        return ssl.create_default_context()


SSL_CTX = build_ssl_context()


def vrm_get(path: str, query: str = "") -> tuple[int, bytes]:
    """Call the VRM API with the token header. Returns (status, body bytes)."""
    url = f"{VRM_BASE}{path}"
    if query:
        url += "?" + query
    req = urllib.request.Request(url, method="GET")
    # VRM quirk: header name is X-Authorization, value is "Token <tok>" or "Bearer <tok>"
    req.add_header("X-Authorization", f"{TOKEN_KIND} {TOKEN}")
    req.add_header("Accept", "application/json")
    try:
        with urllib.request.urlopen(req, timeout=30, context=SSL_CTX) as resp:
            return resp.status, resp.read()
    except urllib.error.HTTPError as e:
        return e.code, e.read()
    except urllib.error.URLError as e:
        reason = str(getattr(e, "reason", e))
        hint = ""
        if "CERTIFICATE_VERIFY_FAILED" in reason:
            hint = (" | macOS fix: run the python.org cert installer once, e.g. "
                    "\"/Applications/Python 3.13/Install Certificates.command\", "
                    "or set VRM_CA_FILE, or (last resort) VRM_INSECURE=1")
        msg = json.dumps({"success": False, "error": f"network error: {reason}{hint}"})
        return 502, msg.encode()


class Handler(BaseHTTPRequestHandler):
    def log_message(self, fmt, *args):  # quieter logs
        sys.stderr.write("  %s\n" % (fmt % args))

    def _send(self, status, body, ctype):
        self.send_response(status)
        self.send_header("Content-Type", ctype)
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Cache-Control", "no-store")
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):
        parsed = urlparse(self.path)
        path = parsed.path

        if path == "/heartbeat":
            STATE["last_beat"] = time.time()
            STATE["beat_seen"] = True
            return self._send(200, b"ok", "text/plain")

        if path in ("/", "/index.html"):
            html = (HERE.parent / "MyDashboard.html").read_bytes()
            return self._send(200, html, "text/html; charset=utf-8")

        if path == "/config.js":
            cfg = f'window.VRM_CONFIG = {{ site: "{SITE}" }};'
            return self._send(200, cfg.encode(), "application/javascript")

        if path == "/SS_app.jpg":
            img = HERE.parent / "SS_app.jpg"
            if img.exists():
                return self._send(200, img.read_bytes(), "image/jpeg")
            return self._send(404, b"not found", "text/plain")

        if path == "/assets/custom-gauge-panel.png":
            img = HERE.parent / "assets" / "custom-gauge-panel.png"
            if img.exists():
                return self._send(200, img.read_bytes(), "image/png")
            return self._send(404, b"not found", "text/plain")

        if path.startswith("/api/"):
            name = path[len("/api/"):]
            if name not in ALLOWED:
                return self._send(404, b'{"error":"unknown endpoint"}', "application/json")
            # Pass through query string (e.g. stats type/interval/start/end), add count for diagnostics.
            query = parsed.query
            if name == "diagnostics" and "count=" not in query:
                query = (query + "&" if query else "") + "count=1000"
            status, body = vrm_get(ALLOWED[name], query)
            return self._send(status, body, "application/json")

        self._send(404, b"not found", "text/plain")


def watchdog(server):
    """Stop the server shortly after the browser tab stops sending heartbeats."""
    while True:
        time.sleep(2)
        now = time.time()
        if STATE["beat_seen"]:
            if now - STATE["last_beat"] > IDLE_TIMEOUT:
                print("\npage closed - shutting down.")
                break
        elif now - STATE["started"] > STARTUP_GRACE:
            print("\nno page connected - shutting down.")
            break
    threading.Thread(target=server.shutdown, daemon=True).start()


def main():
    if not TOKEN:
        print("ERROR: VRM_TOKEN is not set.\n"
              "  Create one in VRM -> Preferences -> Integrations -> Access tokens,\n"
              '  then:  export VRM_TOKEN="your-token"  and re-run.', file=sys.stderr)
        sys.exit(1)
    server = ThreadingHTTPServer(("127.0.0.1", PORT), Handler)
    url = f"http://localhost:{server.server_address[1]}/"
    try:
        URL_FILE.write_text(url)
    except OSError:
        pass
    print(f"VRM dashboard for installation {SITE}")
    print(f"  -> open  {url}")
    if AUTOSTOP:
        print("  (auto-stops a few seconds after the browser tab is closed)")
        threading.Thread(target=watchdog, args=(server,), daemon=True).start()
    else:
        print("  (Ctrl+C to stop)")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nstopped.")
    finally:
        try:
            URL_FILE.unlink()
        except OSError:
            pass


if __name__ == "__main__":
    main()
