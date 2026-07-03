#!/data/data/com.termux/files/usr/bin/bash

# Sync latest files from shared storage (non-fatal if sdcard unavailable)
mkdir -p ~/vrm-dashboard
cp ~/storage/shared/OA423/vrm_token.txt   ~/vrm-dashboard/vrm_token.txt  2>/dev/null || true
cp ~/storage/shared/OA423/vrm_dashboard.py ~/vrm-dashboard/vrm_dashboard.py 2>/dev/null || true
cp ~/storage/shared/OA423/MyDashboard.html ~/MyDashboard.html             2>/dev/null || true
cp ~/storage/shared/OA423/go2rtc.yaml      ~/go2rtc.yaml                  2>/dev/null || true
cp -r ~/storage/shared/OA423/assets        ~/assets                        2>/dev/null || true

# Start go2rtc if not already running
if pgrep -f go2rtc > /dev/null 2>&1; then
  echo "go2rtc already running"
else
  nohup ~/go2rtc -config ~/go2rtc.yaml > ~/go2rtc.log 2>&1 & disown
  echo "go2rtc started"
fi

# Start VRM dashboard with auto-restart loop (runs in background)
if pgrep -f vrm_dashboard > /dev/null 2>&1; then
  echo "VRM dashboard already running at http://localhost:8787/"
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
