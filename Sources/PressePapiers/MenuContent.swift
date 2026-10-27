import SwiftUI
import ServiceManagement

/// Contenu du menu de l'icône dans la barre des menus.
struct MenuContent: View {
    @ObservedObject var store: ClipboardStore

    var body: some View {
        Button("Ouvrir l'historique") { PanelController.shared.show() }
            .keyboardShortcut("v", modifiers: [.command, .shift])

        Divider()

        let recent = Array(store.sortedItems.prefix(15))
        if recent.isEmpty {
            Text("Historique vide")
        } else {
            ForEach(recent) { item in
                Button((item.pinned ? "📌 " : "") + item.menuTitle) {
                    store.copy(item)
                    Paster.paste()
                }
            }
        }

        Divider()

        if !Paster.isAllowed {
            Button("Activer le collage automatique…") { Paster.askForPermission() }
        }
        Toggle("Lancer au démarrage", isOn: Binding(
            get: { SMAppService.mainApp.status == .enabled },
            set: { enabled in
                try? enabled ? SMAppService.mainApp.register() : SMAppService.mainApp.unregister()
            }
        ))
        Button("Effacer l'historique (sauf épinglés)") { store.clearUnpinned() }

        Divider()

        Button("Quitter PressePapiers") { NSApp.terminate(nil) }
            .keyboardShortcut("q")
    }
}
