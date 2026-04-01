#!/usr/bin/env bash
set -euo pipefail

PLIST_PATH="$HOME/Library/LaunchAgents/com.patrickleet.macbook-setup.mise-updates.plist"
STDOUT_LOG="$HOME/Library/Logs/macbook-setup-mise-updates.log"
STDERR_LOG="$HOME/Library/Logs/macbook-setup-mise-updates.err.log"

launchctl unload "$PLIST_PATH" >/dev/null 2>&1 || true
rm -f "$PLIST_PATH"

echo "Removed LaunchAgent:"
echo "  $PLIST_PATH"
echo ""
echo "Existing logs were left in place:"
echo "  $STDOUT_LOG"
echo "  $STDERR_LOG"
