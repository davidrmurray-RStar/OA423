# VRM custom dashboard (installation 931375)

A small, dependency-free custom dashboard for your Victron VRM installation. It
talks to the **official VRM API** — no scraping of the VRM web page. A tiny local
Python server proxies the API so your token stays server-side and the browser
isn't blocked by CORS.

## Files
- `vrm_dashboard.py` — local server + VRM API proxy (Python 3 standard library only)
- `dashboard.html` — the dashboard UI (themeable: edit the CSS variables and CONFIG block)
- `VRM Dashboard.app` — Dock-able app (custom icon; starts server, opens browser, auto-stops on close)
- `start.command` — alternative double-click launcher (same behavior, no icon)
- `vrm_token.txt` — (you create this) your VRM token, one line, used by the app/launcher
- `README.md` — this file

## Dock-able app (easiest)
1. Create `vrm_token.txt` in this folder with **only** your VRM token (`chmod 600 vrm_token.txt`).
2. Double-click **`VRM Dashboard.app`** (or drag it onto your Dock and click it there).
   It opens the dashboard and stops the server a few seconds after you close the tab.
   - Keep the `.app` in this folder. If you move it elsewhere (e.g. `/Applications`),
     it falls back to the hard-coded project path near the top of
     `VRM Dashboard.app/Contents/MacOS/VRMDashboard` — edit that if your folder moves.
   - If a token is missing it shows a dialog instead of failing silently.

## Setup
1. **Get a token.** In VRM: **Preferences → Integrations → Access tokens →**
   create a *Personal access token*. Copy it (you only see it once).

### Easiest: double-click launcher (recommended)
1. Create a file `vrm_token.txt` in this folder containing **only** your token.
   (Keep it private: `chmod 600 vrm_token.txt`.)
2. **Double-click `start.command`.** It starts the server, opens the dashboard in
   your browser, and **shuts the server down a few seconds after you close the tab.**
   A refresh is fine — it only stops when the tab is actually closed.

### Or run manually (stays up until Ctrl+C)
```bash
cd vrm-dashboard
export VRM_TOKEN="paste-your-token-here"
python3 vrm_dashboard.py
```
Then open the URL it prints (default **http://localhost:8787**).

## Customize
- **Look & feel:** edit the `:root { --bg / --accent / ... }` CSS variables at the
  top of `dashboard.html`.
- **Featured tiles:** edit the `FEATURED` array in the `<script>` CONFIG block.
  Each entry matches a measurement by a substring of its description
  (e.g. `"state of charge"`, `"pv power"`). First match wins; reorder/add/remove freely.
- **Refresh rate / stale threshold:** `REFRESH_MS` and `STALE_SEC` in the same block.
- **More data sources:** the server already allows `diagnostics`, `stats`,
  `overallstats`, and `system-overview`. Add more VRM endpoints to the `ALLOWED`
  dict in `vrm_dashboard.py` and fetch them from the front-end at `/api/<name>`.

## Config (environment variables)
| Var | Default | Purpose |
|-----|---------|---------|
| `VRM_TOKEN` | *(required)* | your VRM personal access token |
| `VRM_SITE` | `931375` | installation id |
| `VRM_TOKEN_KIND` | `Token` | `Token` for personal access tokens, `Bearer` for login-session tokens |
| `PORT` | `8787` | local server port (`0` = OS picks a free port; the launcher uses this) |
| `VRM_AUTOSTOP` | unset | `1` = stop the server shortly after the browser tab closes (set by the launcher) |
| `VRM_IDLE_TIMEOUT` | `10` | seconds of no heartbeat before auto-stop fires |

## How it maps to the VRM API
- Live tile data comes from `GET /v2/installations/931375/diagnostics` — a
  self-describing list of every current measurement (device, description,
  formatted value, raw value, age).
- Historical kWh/energy is available via `GET /v2/installations/931375/stats`
  (already proxied at `/api/stats`) if you want to add charts later.

API reference: https://vrm-api-docs.victronenergy.com/
