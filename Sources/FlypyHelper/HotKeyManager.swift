import AppKit
import Carbon.HIToolbox

final class HotKeyManager: ObservableObject, @unchecked Sendable {
    @MainActor private var actions: [UInt32: () -> Void] = [:]

    private var hotKeyRefs: [EventHotKeyRef] = []
    private var eventHandlerRef: EventHandlerRef?

    init() {
        install()
    }

    deinit {
        for hotKeyRef in hotKeyRefs {
            UnregisterEventHotKey(hotKeyRef)
        }

        if let eventHandlerRef {
            RemoveEventHandler(eventHandlerRef)
        }
    }

    @MainActor
    func setActions(reference: @escaping () -> Void, practice: @escaping () -> Void) {
        actions[HotKey.reference.rawValue] = reference
        actions[HotKey.practice.rawValue] = practice
    }

    @MainActor
    private func performAction(for id: UInt32) {
        actions[id]?()
    }

    private func install() {
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        InstallEventHandler(
            GetApplicationEventTarget(),
            { _, event, userData in
                guard let userData else { return noErr }

                let manager = Unmanaged<HotKeyManager>
                    .fromOpaque(userData)
                    .takeUnretainedValue()

                var hotKeyID = EventHotKeyID()
                let status = GetEventParameter(
                    event,
                    EventParamName(kEventParamDirectObject),
                    EventParamType(typeEventHotKeyID),
                    nil,
                    MemoryLayout<EventHotKeyID>.size,
                    nil,
                    &hotKeyID
                )

                guard status == noErr else { return status }

                Task { @MainActor in
                    manager.performAction(for: hotKeyID.id)
                }

                return noErr
            },
            1,
            &eventType,
            Unmanaged.passUnretained(self).toOpaque(),
            &eventHandlerRef
        )

        register(keyCode: kVK_ANSI_K, id: HotKey.reference.rawValue)
        register(keyCode: kVK_ANSI_P, id: HotKey.practice.rawValue)
    }

    private func register(keyCode: Int, id: UInt32) {
        let hotKeyID = EventHotKeyID(
            signature: "FLYP".fourCharCode,
            id: id
        )

        var hotKeyRef: EventHotKeyRef?

        RegisterEventHotKey(
            UInt32(keyCode),
            UInt32(cmdKey | optionKey),
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )

        if let hotKeyRef {
            hotKeyRefs.append(hotKeyRef)
        }
    }
}

private enum HotKey: UInt32 {
    case reference = 1
    case practice = 2
}

private extension String {
    var fourCharCode: FourCharCode {
        unicodeScalars.reduce(0) { result, scalar in
            (result << 8) + FourCharCode(scalar.value)
        }
    }
}
