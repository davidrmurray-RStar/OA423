#!/bin/bash
# Double-click to launch the VRM dashboard.
# Starts the local server, opens your browser, and the server shuts itself
# down a few seconds after you close the dashboard tab.

cd "$(dirname "$0")" || exit 1

# --- token: prefer env var, else read vrm_token.txt (one line) ---
if [ -z "$VRM_TOKEN" ] && [ -f vrm_token.txt ]; then
  VRM_TOKEN="$(tr -d '\r\n' < vrm_token.txt)"
  export VRM_TOKEN
fi
if [ -z "$VRM_TOKEN" ]; then
  echo "No VRM token found."
  echo "Create a file named  vrm_token.txt  in this folder containing only your"
  echo "VRM personal access token, then double-click this launcher again."
  echo
  read -n 1 -s -r -p "Press any key to close..."
  exit 1
fi

# Let the OS pick a free port; the server writes the real URL to .vrm_url
export PORT=0
export VRM_AUTOSTOP=1
rm -f .vrm_url

python3 vrm_dashboard.py &
SERVER_PID=$!

# Wait for the server to report its URL, then open the browser
URL=""
for _ in $(seq 1 40); do
  if [ -f .vrm_url ]; then URL="$(cat .vrm_url)"; break; fi
  sleep 0.1
done

if [ -n "$URL" ]; then
  open "$URL"
else
  echo "Server did not start in time."
fi

# Keep this window tied to the server; it exits when the tab is closed.
wait "$SERVER_PID"
echo "Dashboard stopped."
