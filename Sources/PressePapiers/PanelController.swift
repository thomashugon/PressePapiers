import AppKit
import SwiftUI
import Carbon.HIToolbox

/// Panneau flottant qui peut recevoir le clavier sans voler le focus de l'app en cours.
final class KeyPanel: NSPanel {
    override var canBecomeKey: Bool { true }
}

@MainActor
final class PanelState: ObservableObject {
    @Published var query = "" { didSet { selection = 0 } }
    @Published var selection = 0

    func filtered(_ items: [ClipboardItem]) -> [ClipboardItem] {
        let q = query.trimmingCharacters(in: .whitespaces)
        return q.isEmpty ? items : items.filter { $0.text.localizedCaseInsensitiveContains(q) }
    }
}

@MainActor
final class PanelController: NSObject, NSWindowDelegate {
    static let shared = PanelController()

    private var panel: KeyPanel?
    private let state = PanelState()
    private var keyMonitor: Any?

    func toggle() {
        if panel?.isVisible == true { close() } else { show() }
    }

    func show() {
        state.query = ""
        state.selection = 0
        let panel = self.panel ?? makePanel()
        self.panel = panel
        positionNearMouse(panel)
        panel.makeKeyAndOrderFront(nil)
        installKeyMonitor()
    }

    func close() {
        panel?.orderOut(nil)
        if let keyMonitor { NSEvent.removeMonitor(keyMonitor) }
        keyMonitor = nil
    }

    func windowDidResignKey(_ notification: Notification) {
        close()
    }

    private func pick(_ item: ClipboardItem) {
        close()
        ClipboardStore.shared.copy(item)
        Paster.paste()
    }

    private func makePanel() -> KeyPanel {
        let panel = KeyPanel(
            contentRect: NSRect(x: 0, y: 0, width: 420, height: 460),
            styleMask: [.nonactivatingPanel, .titled, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.hidesOnDeactivate = false
        panel.isMovableByWindowBackground = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        [.closeButton, .miniaturizeButton, .zoomButton].forEach {
            panel.standardWindowButton($0)?.isHidden = true
        }
        panel.contentView = NSHostingView(
            rootView: PanelView(state: state, store: ClipboardStore.shared) { [weak self] item in
                self?.pick(item)
            }
        )
        panel.delegate = self
        return panel
    }

    private func positionNearMouse(_ panel: NSPanel) {
        let mouse = NSEvent.mouseLocation
        let screen = NSScreen.screens.first { NSMouseInRect(mouse, $0.frame, false) } ?? NSScreen.main
        guard let visible = screen?.visibleFrame else { panel.center(); return }
        let size = panel.frame.size
        var origin = NSPoint(x: mouse.x - size.width / 2, y: mouse.y - size.height - 10)
        origin.x = min(max(origin.x, visible.minX + 8), visible.maxX - size.width - 8)
        origin.y = min(max(origin.y, visible.minY + 8), visible.maxY - size.height - 8)
        panel.setFrameOrigin(origin)
    }

    private func installKeyMonitor() {
        guard keyMonitor == nil else { return }
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            MainActor.assumeIsolated {
                guard let self, event.window === self.panel else { return event }
                return self.handle(event) ? nil : event
            }
        }
    }

    /// Navigation au clavier : ↑ ↓ ↩ échap et ⌘1 à ⌘9.
    private func handle(_ event: NSEvent) -> Bool {
        let items = state.filtered(ClipboardStore.shared.sortedItems)
        switch Int(event.keyCode) {
        case kVK_Escape:
            close()
            return true
        case kVK_DownArrow:
            state.selection = items.isEmpty ? 0 : min(state.selection + 1, items.count - 1)
            return true
        case kVK_UpArrow:
            state.selection = max(state.selection - 1, 0)
            return true
        case kVK_Return, kVK_ANSI_KeypadEnter:
            if items.indices.contains(state.selection) { pick(items[state.selection]) }
            return true
        default:
            if event.modifierFlags.contains(.command),
               let digit = event.charactersIgnoringModifiers.flatMap({ Int($0) }),
               (1...9).contains(digit), digit <= items.count {
                pick(items[digit - 1])
                return true
            }
            return false
        }
    }
}
