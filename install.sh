#!/usr/bin/env bash
set -euo pipefail

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "This tool only runs on macOS." >&2
  exit 1
fi

if ! xcrun --find swiftc >/dev/null 2>&1; then
  echo "Swift compiler not found. Install the Xcode Command Line Tools:" >&2
  echo "  xcode-select --install" >&2
  exit 1
fi

REPO_DIR="$(cd -- "$(dirname -- "$0")" && pwd)"
LABEL="com.fifine.thru-watcher"
DOMAIN="gui/$(id -u)"
BIN_DIR="$HOME/.local/bin"
BIN="$BIN_DIR/fifine-thru-watcher"
PLIST_DIR="$HOME/Library/LaunchAgents"
PLIST="$PLIST_DIR/$LABEL.plist"
LOG="$HOME/Library/Logs/fifine-thru-watcher.log"

mkdir -p "$BIN_DIR" "$PLIST_DIR" "$HOME/Library/Logs"

echo "Compiling watcher..."
TEMP_BIN="$BIN.tmp.$$"
trap 'rm -f "$TEMP_BIN"' EXIT
xcrun swiftc -O -framework CoreAudio "$REPO_DIR/fifine-thru.swift" -o "$TEMP_BIN"

# Stop the old service before replacing its executable.
launchctl bootout "$DOMAIN/$LABEL" >/dev/null 2>&1 || true
mv -f "$TEMP_BIN" "$BIN"

cat > "$PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>$LABEL</string>
    <key>ProgramArguments</key>
    <array>
        <string>$BIN</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardErrorPath</key>
    <string>$LOG</string>
</dict>
</plist>
EOF

plutil -lint "$PLIST" >/dev/null
launchctl bootstrap "$DOMAIN" "$PLIST"

echo
echo "Installed and started $LABEL"
echo "Check status: launchctl print $DOMAIN/$LABEL"
echo "View logs:    tail -f \"$LOG\""
echo "Test once:    \"$BIN\" --once"
