#!/usr/bin/env bash
set -euo pipefail

SETUP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PLIST_PATH="$HOME/Library/LaunchAgents/com.patrickleet.macbook-setup.mise-updates.plist"
LOG_DIR="$HOME/Library/Logs"
STDOUT_LOG="$LOG_DIR/macbook-setup-mise-updates.log"
STDERR_LOG="$LOG_DIR/macbook-setup-mise-updates.err.log"

mkdir -p "$HOME/Library/LaunchAgents" "$LOG_DIR"

cat > "$PLIST_PATH" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>com.patrickleet.macbook-setup.mise-updates</string>

  <key>ProgramArguments</key>
  <array>
    <string>/bin/bash</string>
    <string>$SETUP_DIR/scripts/update-tools.sh</string>
  </array>

  <key>RunAtLoad</key>
  <true/>

  <key>StartInterval</key>
  <integer>86400</integer>

  <key>StandardOutPath</key>
  <string>$STDOUT_LOG</string>

  <key>StandardErrorPath</key>
  <string>$STDERR_LOG</string>

  <key>WorkingDirectory</key>
  <string>$SETUP_DIR</string>
</dict>
</plist>
EOF

launchctl unload "$PLIST_PATH" >/dev/null 2>&1 || true
launchctl load "$PLIST_PATH"

echo "Installed LaunchAgent:"
echo "  $PLIST_PATH"
echo ""
echo "It will run on login and then every 24 hours."
echo "Logs:"
echo "  $STDOUT_LOG"
echo "  $STDERR_LOG"
