#!/usr/bin/env bash
set -euo pipefail

LABEL="com.fifine.thru-watcher"
DOMAIN="gui/$(id -u)"
PLIST="$HOME/Library/LaunchAgents/$LABEL.plist"
BIN="$HOME/.local/bin/fifine-thru-watcher"

launchctl bootout "$DOMAIN/$LABEL" >/dev/null 2>&1 || true
rm -f "$PLIST" "$BIN"

echo "FIFINE Thru watcher removed."
echo "The log file, if any, remains at ~/Library/Logs/fifine-thru-watcher.log"
