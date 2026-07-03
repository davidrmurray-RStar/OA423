#!/data/data/com.termux/files/usr/bin/bash
mkdir -p ~/vrm-dashboard
cp ~/storage/shared/OA423/vrm_token.txt ~/vrm-dashboard/vrm_token.txt
cp ~/storage/shared/OA423/vrm_dashboard.py ~/vrm-dashboard/vrm_dashboard.py
cp ~/storage/shared/OA423/MyDashboard.html ~/MyDashboard.html
cp -r ~/storage/shared/OA423/assets ~/assets 2>/dev/null || true

export VRM_TOKEN="$(cat ~/vrm-dashboard/vrm_token.txt)"
export PORT=8787

echo "Starting go2rtc..."
~/go/bin/go2rtc -config ~/go2rtc.yaml &
sleep 2

echo "Starting VRM dashboard at http://localhost:8787 ..."
cd ~/vrm-dashboard
python3 vrm_dashboard.py
