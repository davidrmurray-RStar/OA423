# VRM dashboard server (Sunset Serenade / OA423)

The local server behind the tablet-hosted dashboard. It does three things:

1. **Bridges live data from the Cerbo GX** over MQTT (LAN, no cloud) and caches it, so the Electrical tab's gauges update ~every second without hitting VRM's cloud API.
2. **Proxies the VRM cloud API** (`vrmapi.victronenergy.com`) for anything not covered by the MQTT bridge (featured cards, fallback if MQTT drops). The VRM access token stays server-side and is never sent to the browser.
3. **Serves the dashboard itself** (`MyDashboard.html`, at the repo root — *not* `dashboard.html` in this folder, see Legacy files below) and provides a couple of maintenance endpoints (server/camera restart).

## Where this actually runs

Not on a Mac — on the boat's tablet, via **Termux** (Android), at **192.168.0.50** (static reservation), SSH port 8022.

- `sshd` must be started manually in Termux after the tablet reboots.
- Once SSH is up, everything else auto-starts via `~/.bashrc` → `~/run.sh`:
  - Syncs `MyDashboard.html`, `vrm_dashboard.py`, `go2rtc.yaml`, `vrm_token.txt`, and `assets/` from `~/storage/shared/OA423/` (so files dropped there via the Android Files app or AirDrop-equivalent land in the right place)
  - Starts **go2rtc** (RTSP → WebRTC bridge for the boat's camera)
  - Starts `vrm_dashboard.py` in an auto-restart loop (`while true; do python3 vrm_dashboard.py; sleep 3; done`), logging to `~/vrm.log`

To deploy a change: SCP the updated file to **both** `~/<file>` and `~/storage/shared/OA423/<file>` on the tablet, then restart the relevant service (`pkill -f vrm_dashboard.py` or `pkill -f go2rtc`, followed by `bash ~/run.sh`).

## Files (this folder)

| File | Purpose |
|---|---|
| `vrm_dashboard.py` | The server — MQTT bridge, VRM API proxy, static file serving. Python 3 standard library only, plus `paho-mqtt` (installed on the tablet via `pip install paho-mqtt`). |
| `README.md` | This file. |

The actual dashboard UI (`MyDashboard.html`), the camera config (`go2rtc.yaml`), and the go2rtc binary live at the repo root / home directory on the tablet, not in this folder.

## Setup (one time)

1. **Get a VRM token.** VRM Portal → Preferences → Integrations → Access tokens → create a *Personal access token*. Copy it — shown once.
2. On the tablet, put the token in `~/vrm-dashboard/vrm_token.txt` (and `~/storage/shared/OA423/vrm_token.txt`, since `run.sh` syncs from there) — **never** in code or committed files.
3. Confirm the Cerbo GX has **MQTT on LAN (Plaintext)** enabled: Settings → Services on the Cerbo/GX Touch, or via VRM Remote Console.
4. Run manually to test: `export VRM_TOKEN="$(cat vrm_token.txt)"; python3 vrm_dashboard.py`, then open `http://192.168.0.50:8787`.

## Config (environment variables)

| Var | Default | Purpose |
|---|---|---|
| `VRM_TOKEN` | *(required)* | Your VRM personal access token |
| `VRM_SITE` | `931375` | VRM installation id |
| `VRM_TOKEN_KIND` | `Token` | `Token` for personal access tokens, `Bearer` for login-session tokens |
| `PORT` | `8787` | Server port |
| `CERBO_HOST` | `192.168.0.55` | Cerbo GX IP for the MQTT bridge — **static reservation on the router**, set 2026-08-07 after repeated DHCP-lease drift silently broke live data (see Troubleshooting) |
| `CERBO_MQTT_PORT` | `1883` | Cerbo MQTT-on-LAN port |
| `CERBO_PORTAL_ID` | `c0619abb114f` | Cerbo Portal ID, used as the MQTT topic prefix |
| `VRM_AUTOSTOP` | unset | `1` = stop the server shortly after the last browser tab's heartbeat stops (not used in the tablet deployment, which runs continuously) |
| `VRM_IDLE_TIMEOUT` | `10` | Seconds of no heartbeat before auto-stop fires (only relevant if `VRM_AUTOSTOP=1`) |
| `VRM_INSECURE` | unset | `1` disables TLS verification for the VRM API call (escape hatch, not recommended) |
| `VRM_CA_FILE` | unset | Path to an explicit CA bundle for the VRM API call |

## Endpoints

| Endpoint | Purpose |
|---|---|
| `/api/live` | Returns the cached MQTT snapshot: `{ok, connected, data}`. Polled every ~1s by the browser. |
| `/api/diagnostics`, `/api/stats`, `/api/overallstats`, `/api/system-overview` | Proxied straight through to the matching VRM cloud API endpoint. |
| `/api/restart-server` | Exits the process; the `run.sh` auto-restart loop brings it back up in ~3s. |
| `/api/restart-camera` | Kills and restarts `go2rtc` (used by the Cameras tab's restart button). |
| `/heartbeat` | Used by the browser to signal it's still open (relevant only if `VRM_AUTOSTOP=1`). |

## Troubleshooting

- **Live gauges stuck / "VRM server not running"**: check `~/vrm.log` on the tablet for `MQTT bridge: Connection refused` — usually means the Cerbo's IP has drifted (it's on DHCP unless you've set a router reservation). Find it with a quick port scan from the tablet: `for i in $(seq 2 254); do timeout 0.3 bash -c "echo > /dev/tcp/192.168.0.$i/1883" 2>/dev/null && echo "$i OPEN"; done`, then update `CERBO_HOST` in `vrm_dashboard.py` and restart.
- **Camera feed dead**: same drift issue can hit the camera (RTSP port 554 instead of 1883) — update the IP in `~/go2rtc.yaml`'s `streams.camera1` line and restart go2rtc.
- **`/api/diagnostics` returns 401**: the VRM token has expired — generate a new one (Setup step 1–2) and restart the server.

## Legacy files (not part of the current deployment)

`dashboard.html`, `VRM Dashboard.app`, and `start.command` in this folder are from an earlier Mac-based prototype (standalone app, no Termux/tablet, no MQTT bridge, no camera integration). They predate the current architecture and aren't used by the boat's actual setup — left in place for now but safe to ignore.

API reference: https://vrm-api-docs.victronenergy.com/
