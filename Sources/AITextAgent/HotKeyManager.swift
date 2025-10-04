import Carbon
import Foundation

/// Manages global hotkey registration (Cmd+Shift+Space)
class HotKeyManager {
    private var hotKeyRef: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?
    private var callback: (() -> Void)?
    private var selfRetained: Unmanaged<HotKeyManager>?

    /// Register global hotkey with callback
    func registerHotKey(callback: @escaping () -> Void) {
        self.callback = callback

        // Hotkey: Cmd+Shift+Space
        let keyCode: UInt32 = 49 // Space key
        let modifiers: UInt32 = UInt32(cmdKey | shiftKey)

        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))

        // Retain self for the event handler
        selfRetained = Unmanaged.passRetained(self)

        // Install event handler
        InstallEventHandler(GetApplicationEventTarget(), { (nextHandler, event, userData) -> OSStatus in
            guard let userData = userData else {
                return OSStatus(eventNotHandledErr)
            }

            let manager = Unmanaged<HotKeyManager>.fromOpaque(userData).takeUnretainedValue()
            manager.callback?()
            return noErr
        }, 1, &eventType, selfRetained?.toOpaque(), &eventHandler)

        // Register hotkey
        let hotKeyID = EventHotKeyID(signature: OSType(0x4149), id: 1)
        RegisterEventHotKey(keyCode, modifiers, hotKeyID, GetApplicationEventTarget(), 0, &hotKeyRef)

        print("🔑 Registered hotkey: Cmd+Shift+Space")
    }

    deinit {
        if let hotKeyRef = hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
        }
        if let eventHandler = eventHandler {
            RemoveEventHandler(eventHandler)
        }
        // Release the retained self
        selfRetained?.release()
    }
}
