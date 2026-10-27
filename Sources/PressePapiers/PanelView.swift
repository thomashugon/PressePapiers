import SwiftUI

struct PanelView: View {
    @ObservedObject var state: PanelState
    @ObservedObject var store: ClipboardStore
    let onPick: (ClipboardItem) -> Void

    @FocusState private var searchFocused: Bool

    var body: some View {
        let items = state.filtered(store.sortedItems)

        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                TextField("Rechercher dans l'historique…", text: $state.query)
                    .textFieldStyle(.plain)
                    .font(.title3)
                    .focused($searchFocused)
            }
            .padding(12)

            Divider()

            if items.isEmpty {
                Spacer()
                Text(store.items.isEmpty ? "Copiez du texte (⌘C) pour remplir l'historique." : "Aucun résultat.")
                    .foregroundStyle(.secondary)
                Spacer()
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 2) {
                            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                                ItemRow(item: item, index: index, selected: index == state.selection)
                                    .id(item.id)
                                    .onTapGesture { onPick(item) }
                                    .onHover { if $0 { state.selection = index } }
                                    .contextMenu {
                                        Button(item.pinned ? "Désépingler" : "Épingler") { store.togglePin(item) }
                                        Button("Supprimer", role: .destructive) { store.delete(item) }
                                    }
                            }
                        }
                        .padding(6)
                    }
                    .onChange(of: state.selection) { _, newValue in
                        if items.indices.contains(newValue) { proxy.scrollTo(items[newValue].id) }
                    }
                }
            }

            Divider()

            Text("↑↓ choisir · ↩ coller · ⌘1–9 accès direct · clic droit : épingler")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(8)
        }
        .frame(width: 420, height: 460)
        .background(.regularMaterial)
        .onAppear { searchFocused = true }
    }
}

struct ItemRow: View {
    let item: ClipboardItem
    let index: Int
    let selected: Bool

    var body: some View {
        HStack(spacing: 8) {
            Text(index < 9 ? "\(index + 1)" : "")
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(width: 14)
            Text(item.preview)
                .lineLimit(1)
                .truncationMode(.tail)
            Spacer(minLength: 4)
            if item.pinned {
                Image(systemName: "pin.fill").font(.caption).foregroundStyle(.orange)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(selected ? Color.accentColor.opacity(0.25) : Color.clear)
        )
        .contentShape(Rectangle())
        .help(String(item.text.prefix(500)))
    }
}
