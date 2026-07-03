#!/data/data/com.termux/files/usr/bin/bash
set -e

echo "=== OA423 Termux Setup ==="

echo "[1/4] Updating packages..."
pkg update -y && pkg install -y wget python3

echo "[2/4] Downloading go2rtc (arm64)..."
cd ~
wget -q --show-progress https://github.com/AlexxIT/go2rtc/releases/latest/download/go2rtc_linux_arm64 -O go2rtc
chmod +x go2rtc

echo "[3/4] Copying app files..."
cp /sdcard/OA423/go2rtc.yaml ~/go2rtc.yaml
cp /sdcard/OA423/MyDashboard.html ~/MyDashboard.html
cp -r /sdcard/OA423/assets ~/assets

echo "[4/4] Creating start script..."
cat > ~/start.sh << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash
echo "Starting go2rtc..."
~/go2rtc -config ~/go2rtc.yaml &
sleep 2
echo "Starting web server..."
cd ~
python3 -m http.server 8787
EOF
chmod +x ~/start.sh

echo ""
echo "=== Done! ==="
echo "Run:  ~/start.sh"
echo "Then open: http://localhost:8787/MyDashboard.html"
