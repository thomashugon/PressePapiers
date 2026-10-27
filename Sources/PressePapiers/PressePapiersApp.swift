import SwiftUI
import Carbon.HIToolbox

@main
struct PressePapiersApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        MenuBarExtra("PressePapiers", systemImage: "doc.on.clipboard") {
            MenuContent(store: ClipboardStore.shared)
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var hotKey: HotKey?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Pas d'icône dans le Dock : l'app vit uniquement dans la barre de menus.
        NSApp.setActivationPolicy(.accessory)
        ClipboardStore.shared.startMonitoring()

        // Raccourci global : ⌘⇧V
        hotKey = HotKey(keyCode: UInt32(kVK_ANSI_V), modifiers: UInt32(cmdKey | shiftKey)) {
            Task { @MainActor in PanelController.shared.toggle() }
        }
    }
}
