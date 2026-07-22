import Carbon
import Foundation

final class GlobalHotkeyManager: @unchecked Sendable {
    static let shared = GlobalHotkeyManager()

    nonisolated(unsafe) fileprivate var handlers: [UInt32: @MainActor () -> Void] = [:]
    nonisolated(unsafe) private var hotKeyRefs: [EventHotKeyRef] = []
    nonisolated(unsafe) private var eventHandlerInstalled = false

    private init() {}

    func register(id: UInt32, keyCode: UInt32, modifiers: UInt32, handler: @escaping @MainActor () -> Void) {
        handlers[id] = handler

        var hotKeyRef: EventHotKeyRef?
        let hotKeyID = EventHotKeyID(signature: 0x5453, id: id)

        let status = RegisterEventHotKey(
            keyCode,
            modifiers,
            hotKeyID,
            GetEventDispatcherTarget(),
            0,
            &hotKeyRef
        )

        guard status == noErr, let ref = hotKeyRef else {
            return
        }

        hotKeyRefs.append(ref)

        if !eventHandlerInstalled {
            installEventHandler()
            eventHandlerInstalled = true
        }
    }

    private func installEventHandler() {
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        let unmanaged = Unmanaged.passUnretained(self)

        InstallEventHandler(
            GetEventDispatcherTarget(),
            globalHotkeyCallback,
            1,
            &eventType,
            unmanaged.toOpaque(),
            nil
        )
    }
}

private let globalHotkeyCallback: @convention(c) (
    EventHandlerCallRef?,
    EventRef?,
    UnsafeMutableRawPointer?
) -> OSStatus = { _, event, userData in
    guard let userData else { return noErr }
    let manager = Unmanaged<GlobalHotkeyManager>.fromOpaque(userData).takeUnretainedValue()

    var hotKeyID = EventHotKeyID()
    let err = GetEventParameter(
        event,
        EventParamName(kEventParamDirectObject),
        EventParamType(typeEventHotKeyID),
        nil,
        MemoryLayout<EventHotKeyID>.size,
        nil,
        &hotKeyID
    )
    guard err == noErr else { return err }

    if let handler = manager.handlers[hotKeyID.id] {
        Task { @MainActor in
            handler()
        }
    }
    return noErr
}
