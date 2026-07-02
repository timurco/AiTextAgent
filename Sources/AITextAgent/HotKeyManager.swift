import Carbon
import Foundation

/// Manages global hotkey registration (multiple hotkeys, identified by id)
class HotKeyManager {
    struct HotKey {
        let id: UInt32
        let keyCode: UInt32
        let modifiers: UInt32
        let label: String
    }

    private var hotKeyRefs: [EventHotKeyRef] = []
    private var eventHandler: EventHandlerRef?
    private var callback: ((UInt32) -> Void)?
    private var selfRetained: Unmanaged<HotKeyManager>?

    /// Register global hotkeys; callback receives the pressed hotkey's id
    func registerHotKeys(_ hotKeys: [HotKey], callback: @escaping (UInt32) -> Void) {
        self.callback = callback

        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))

        // Retain self for the event handler
        selfRetained = Unmanaged.passRetained(self)

        // Install single event handler for all hotkeys
        InstallEventHandler(GetApplicationEventTarget(), { (nextHandler, event, userData) -> OSStatus in
            guard let userData = userData, let event = event else {
                return OSStatus(eventNotHandledErr)
            }

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
            guard status == noErr else {
                return status
            }

            let manager = Unmanaged<HotKeyManager>.fromOpaque(userData).takeUnretainedValue()
            manager.callback?(hotKeyID.id)
            return noErr
        }, 1, &eventType, selfRetained?.toOpaque(), &eventHandler)

        // Register each hotkey
        for hotKey in hotKeys {
            let hotKeyID = EventHotKeyID(signature: OSType(0x4149), id: hotKey.id)
            var ref: EventHotKeyRef?
            let status = RegisterEventHotKey(hotKey.keyCode, hotKey.modifiers, hotKeyID, GetApplicationEventTarget(), 0, &ref)
            if status == noErr, let ref = ref {
                hotKeyRefs.append(ref)
                print("🔑 Registered hotkey: \(hotKey.label)")
            } else {
                print("❌ Failed to register hotkey: \(hotKey.label) (status: \(status))")
            }
        }
    }

    deinit {
        for hotKeyRef in hotKeyRefs {
            UnregisterEventHotKey(hotKeyRef)
        }
        if let eventHandler = eventHandler {
            RemoveEventHandler(eventHandler)
        }
        // Release the retained self
        selfRetained?.release()
    }
}
