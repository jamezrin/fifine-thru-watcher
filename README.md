# FIFINE Thru Watcher

A tiny native macOS utility that keeps **Thru (microphone play-through / sidetone monitoring)** disabled for FIFINE USB microphones.

Some FIFINE microphones re-enable **Thru** in **Audio MIDI Setup** whenever the USB device reconnects. This tool checks the device's CoreAudio `kAudioDevicePropertyPlayThru` setting every two seconds and disables it again when necessary.

No third-party dependencies, administrator privileges, microphone recordings, or network connections.

## Requirements

- macOS
- A FIFINE USB audio device that exposes the CoreAudio PlayThru property
- Xcode Command Line Tools (for `swiftc`)

## Install

```bash
git clone https://github.com/jamezrin/fifine-thru-watcher.git
cd fifine-thru-watcher
bash install.sh
```

If the Swift compiler is missing, run `xcode-select --install` and retry.

The installer compiles `fifine-thru.swift` into `~/.local/bin/fifine-thru-watcher` and registers a per-user LaunchAgent named `com.fifine.thru-watcher`. It starts immediately and again whenever you log in.

## Verify

With the microphone plugged in:

```bash
~/.local/bin/fifine-thru-watcher --once
```

Unplug and reconnect the microphone. If Thru turns on again, it should be turned off automatically within approximately two seconds.

Service status:

```bash
launchctl print "gui/$(id -u)/com.fifine.thru-watcher"
```

Logs (entries appear when the watcher starts or changes Thru):

```bash
tail -f ~/Library/Logs/fifine-thru-watcher.log
```

## Uninstall

From the cloned repository:

```bash
bash uninstall.sh
```

The uninstall script removes the LaunchAgent and installed binary, but leaves the log for troubleshooting. The repository directory can then be deleted separately.

## Run without installing

```bash
swift fifine-thru.swift --once
swift fifine-thru.swift
```

Without `--once`, the watcher stays in the foreground. Press Ctrl+C to stop it.

## How it works

1. Enumerates CoreAudio audio devices.
2. Finds devices with `fifine` in their name (case-insensitive).
3. Reads the device's `kAudioDevicePropertyPlayThru` property in the play-through scope.
4. Writes `0` only if the property is currently enabled.
5. Repeats every two seconds, including after USB reconnections.

The `launchd` agent is responsible for starting the watcher at login and restarting it if it exits unexpectedly.

**Limitations:** The setting is not saved into the microphone's firmware. There may be up to two seconds of monitoring after reconnecting. Only devices exposing the CoreAudio PlayThru property are supported. The installer and the Swift implementation have not been independently tested on every macOS version or FIFINE model.

## License

MIT. See [LICENSE](LICENSE).
