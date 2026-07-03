#!/data/data/com.termux/files/usr/bin/bash
mkdir -p ~/vrm-dashboard
cp ~/storage/shared/OA423/vrm_token.txt ~/vrm-dashboard/vrm_token.txt
cp ~/storage/shared/OA423/vrm_dashboard.py ~/vrm-dashboard/vrm_dashboard.py
cp ~/storage/shared/OA423/MyDashboard.html ~/MyDashboard.html
cp ~/storage/shared/OA423/go2rtc.yaml ~/go2rtc.yaml
cp -r ~/storage/shared/OA423/assets ~/assets 2>/dev/null || true

export VRM_TOKEN="$(cat ~/vrm-dashboard/vrm_token.txt)"
export PORT=8787

echo "Starting go2rtc..."
pkill -f go2rtc 2>/dev/null; sleep 1
nohup ~/go2rtc -config ~/go2rtc.yaml > ~/go2rtc.log 2>&1 & disown
sleep 3

if pgrep -f go2rtc > /dev/null; then
  echo "go2rtc running OK on port 1984"
else
  echo "go2rtc FAILED:"
  cat ~/go2rtc.log
fi

echo "Starting VRM dashboard at http://localhost:8787 ..."
cd ~/vrm-dashboard
python3 vrm_dashboard.py
