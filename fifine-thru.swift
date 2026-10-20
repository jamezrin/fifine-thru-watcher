import CoreAudio
import Foundation

// Automatically disable hardware/software play-through on FIFINE USB microphones.
// Run with --once for a single check, or without arguments to watch continuously.

private let system = AudioObjectID(kAudioObjectSystemObject)
private let pollInterval: TimeInterval = 2.0

private func deviceName(_ device: AudioDeviceID) -> String? {
    var address = AudioObjectPropertyAddress(
        mSelector: kAudioObjectPropertyName,
        mScope: kAudioObjectPropertyScopeGlobal,
        mElement: kAudioObjectPropertyElementMain
    )

    // CoreAudio returns a retained CFString. Unmanaged avoids the Swift warning
    // about passing an Optional<CFString> across an UnsafeMutableRawPointer.
    var unmanagedName: Unmanaged<CFString>?
    var size = UInt32(MemoryLayout<Unmanaged<CFString>?>.size)

    let status = withUnsafeMutablePointer(to: &unmanagedName) { pointer in
        AudioObjectGetPropertyData(device, &address, 0, nil, &size, pointer)
    }

    guard status == noErr, let unmanagedName else {
        return nil
    }
    return unmanagedName.takeRetainedValue() as String
}

private func audioDevices() -> [AudioDeviceID] {
    var address = AudioObjectPropertyAddress(
        mSelector: kAudioHardwarePropertyDevices,
        mScope: kAudioObjectPropertyScopeGlobal,
        mElement: kAudioObjectPropertyElementMain
    )

    var size: UInt32 = 0
    guard AudioObjectGetPropertyDataSize(
        system, &address, 0, nil, &size
    ) == noErr else {
        return []
    }

    let count = Int(size) / MemoryLayout<AudioDeviceID>.size
    guard count > 0 else {
        return []
    }

    var devices = [AudioDeviceID](repeating: 0, count: count)
    let status = devices.withUnsafeMutableBufferPointer { buffer in
        AudioObjectGetPropertyData(
            system, &address, 0, nil, &size, buffer.baseAddress!
        )
    }

    guard status == noErr else {
        return []
    }
    return devices
}

private func checkFifine(verbose: Bool = false) {
    var found = false

    for device in audioDevices() {
        guard let name = deviceName(device),
              name.localizedCaseInsensitiveContains("fifine") else {
            continue
        }
        found = true

        var thruAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyPlayThru,
            mScope: kAudioDevicePropertyScopePlayThrough,
            mElement: kAudioObjectPropertyElementMain
        )

        guard AudioObjectHasProperty(device, &thruAddress) else {
            if verbose {
                print("\(name): CoreAudio Thru property is unavailable")
            }
            continue
        }

        var current: UInt32 = 0
        var size = UInt32(MemoryLayout<UInt32>.size)

        let readStatus = AudioObjectGetPropertyData(
            device, &thruAddress, 0, nil, &size, &current
        )

        guard readStatus == noErr else {
            if verbose {
                print("\(name): cannot read Thru (error \(readStatus))")
            }
            continue
        }

        guard current != 0 else {
            if verbose {
                print("\(name): Thru is already off")
            }
            continue
        }

        var off: UInt32 = 0
        let writeStatus = AudioObjectSetPropertyData(
            device, &thruAddress, 0, nil,
            UInt32(MemoryLayout<UInt32>.size), &off
        )

        if writeStatus == noErr {
            NSLog("%@: Thru disabled", name)
        } else {
            NSLog("%@: failed to disable Thru (error %d)", name, writeStatus)
        }
    }

    if verbose && !found {
        print("No FIFINE audio device found")
    }
}

if CommandLine.arguments.contains("--once") {
    checkFifine(verbose: true)
} else {
    NSLog("FIFINE Thru watcher started (checking every %.0f seconds)", pollInterval)
    checkFifine()

    let timer = Timer(timeInterval: pollInterval, repeats: true) { _ in
        checkFifine()
    }
    RunLoop.main.add(timer, forMode: .common)
    RunLoop.main.run()
}
