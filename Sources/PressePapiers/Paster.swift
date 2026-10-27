import AppKit
import Carbon.HIToolbox

/// Simule ⌘V dans l'app au premier plan. Nécessite l'autorisation « Accessibilité » ;
/// sans elle, l'élément est simplement copié et il suffit de faire ⌘V soi-même.
enum Paster {
    static var isAllowed: Bool { AXIsProcessTrusted() }

    static func paste() {
        guard isAllowed else {
            askForPermission()
            return
        }
        // Petit délai pour laisser la fenêtre se fermer et l'app d'origine reprendre le focus.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            let source = CGEventSource(stateID: .combinedSessionState)
            let keyDown = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(kVK_ANSI_V), keyDown: true)
            let keyUp = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(kVK_ANSI_V), keyDown: false)
            keyDown?.flags = .maskCommand
            keyUp?.flags = .maskCommand
            keyDown?.post(tap: .cghidEventTap)
            keyUp?.post(tap: .cghidEventTap)
        }
    }

    /// Ouvre la demande système d'autorisation Accessibilité.
    static func askForPermission() {
        let options = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
    }
}
