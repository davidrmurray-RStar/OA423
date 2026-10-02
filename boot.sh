#!/data/data/com.termux/files/usr/bin/bash
# OA423 boot launcher — installed by run.sh into ~/.termux/boot/ and run by the Termux:Boot app
# after the tablet restarts. Starts the server, waits for it, then opens the dashboard.
LOG=~/boot.log
echo "[$(date)] boot start" >> "$LOG"
command -v termux-wake-lock >/dev/null 2>&1 && termux-wake-lock

sleep 20                                   # let Wi-Fi come up so the GitHub pull and Cerbo link work
bash ~/run.sh >> "$LOG" 2>&1

# wait up to 2 min for the dashboard server to answer
for i in $(seq 1 60); do
  (echo > /dev/tcp/127.0.0.1/8787) 2>/dev/null && break
  sleep 2
done

am start -a android.intent.action.VIEW -d "http://localhost:8787/" >> "$LOG" 2>&1
echo "[$(date)] boot done (server wait loops: $i)" >> "$LOG"
