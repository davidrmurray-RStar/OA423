#!/data/data/com.termux/files/usr/bin/bash
# OA423 dashboard launcher (Termux).
# Code (HTML, assets, server) auto-updates from GitHub; secrets and docs come from shared storage.

REPO_URL="https://github.com/davidrmurray-RStar/OA423.git"
REPO=~/OA423-repo
SHARED=~/storage/shared/OA423

# Keep Android from sleeping Termux overnight
command -v termux-wake-lock >/dev/null 2>&1 && termux-wake-lock

mkdir -p ~/vrm-dashboard ~/assets ~/docs

# ── 1. Pull latest code from GitHub (non-fatal if offline) ──
command -v git >/dev/null 2>&1 || pkg install -y git >/dev/null 2>&1 || true
OLD_REV=""; NEW_REV=""
if command -v git >/dev/null 2>&1; then
  if [ -d "$REPO/.git" ]; then
    OLD_REV=$(git -C "$REPO" rev-parse HEAD 2>/dev/null)
    timeout 60 git -C "$REPO" pull --ff-only -q 2>/dev/null && echo "Code updated from GitHub" || echo "GitHub pull skipped (offline?)"
  else
    timeout 120 git clone -q --depth 1 "$REPO_URL" "$REPO" 2>/dev/null && echo "Cloned OA423 from GitHub" || echo "GitHub clone skipped (offline?)"
  fi
  NEW_REV=$(git -C "$REPO" rev-parse HEAD 2>/dev/null)
fi

# ── 2. Install code: GitHub copy if available, else shared storage ──
if [ -f "$REPO/MyDashboard.html" ]; then SRC="$REPO"; else SRC="$SHARED"; fi
cp "$SRC/MyDashboard.html"                ~/MyDashboard.html               2>/dev/null || true
cp "$SRC/MaintOverview.html"              ~/MaintOverview.html             2>/dev/null || true
cp "$SRC/SS_app.jpg"                      ~/SS_app.jpg                     2>/dev/null || true
cp -r "$SRC/assets/."                     ~/assets/                        2>/dev/null || true
if [ "$SRC" = "$REPO" ]; then
  cp "$REPO/vrm-dashboard/vrm_dashboard.py" ~/vrm-dashboard/vrm_dashboard.py 2>/dev/null || true
  cp "$REPO/run.sh"                         ~/run.sh.new                     2>/dev/null && mv ~/run.sh.new ~/run.sh && chmod +x ~/run.sh
  # start-at-boot script for the Termux:Boot app
  mkdir -p ~/.termux/boot
  cp "$REPO/boot.sh" ~/.termux/boot/oa423-boot.sh 2>/dev/null && chmod +x ~/.termux/boot/oa423-boot.sh
else
  cp "$SHARED/vrm_dashboard.py"             ~/vrm-dashboard/vrm_dashboard.py 2>/dev/null || true
fi

# ── 3. Secrets + docs always from shared storage (never in GitHub) ──
cp "$SHARED/vrm_token.txt" ~/vrm-dashboard/vrm_token.txt 2>/dev/null || true
cp "$SHARED/go2rtc.yaml"   ~/go2rtc.yaml                 2>/dev/null || true
cp -r "$SHARED/docs/."     ~/docs/                       2>/dev/null || true

# ── 4. go2rtc ──
if pgrep -f go2rtc > /dev/null 2>&1; then
  echo "go2rtc already running"
else
  setsid ~/go2rtc -config ~/go2rtc.yaml >> ~/go2rtc.log 2>&1 </dev/null &
  echo "go2rtc started"
fi

# ── 5. VRM dashboard server (auto-restart loop) ──
if pgrep -f vrm_dashboard > /dev/null 2>&1; then
  if [ -n "$OLD_REV" ] && [ "$OLD_REV" != "$NEW_REV" ]; then
    pkill -f "python3 vrm_dashboard.py"   # loop restarts it with the new code in ~3s
    echo "VRM dashboard restarting with new code"
  else
    echo "VRM dashboard already running at http://localhost:8787/"
  fi
else
  nohup bash -c '
    export VRM_TOKEN="$(cat ~/vrm-dashboard/vrm_token.txt)"
    export PORT=8787
    cd ~/vrm-dashboard
    while true; do
      python3 vrm_dashboard.py
      echo "[$(date)] vrm_dashboard exited, restarting in 3s..." >> ~/vrm.log
      sleep 3
    done
  ' >> ~/vrm.log 2>&1 & disown
  echo "VRM dashboard starting at http://localhost:8787/"
fi
