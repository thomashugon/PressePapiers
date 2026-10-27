import AppKit

struct ClipboardItem: Codable, Identifiable, Equatable {
    var id = UUID()
    var text: String
    var date = Date()
    var pinned = false

    /// Texte sur une seule ligne, pour l'affichage dans les listes.
    var preview: String {
        let flat = text.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\n", with: " ⏎ ")
            .replacingOccurrences(of: "\t", with: " ")
        return String(flat.prefix(200))
    }

    var menuTitle: String {
        preview.count > 50 ? String(preview.prefix(50)) + "…" : preview
    }
}

@MainActor
final class ClipboardStore: ObservableObject {
    static let shared = ClipboardStore()

    @Published private(set) var items: [ClipboardItem] = []

    /// Nombre maximum d'éléments non épinglés conservés.
    private let maxItems = 50
    private var lastChangeCount = NSPasteboard.general.changeCount
    private var timer: Timer?
    private let fileURL: URL

    /// Éléments épinglés d'abord, puis les plus récents.
    var sortedItems: [ClipboardItem] {
        items.filter(\.pinned) + items.filter { !$0.pinned }
    }

    private init() {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("PressePapiers", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        fileURL = dir.appendingPathComponent("historique.json")
        load()
    }

    func startMonitoring() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.checkPasteboard() }
        }
    }

    private func checkPasteboard() {
        let pasteboard = NSPasteboard.general
        guard pasteboard.changeCount != lastChangeCount else { return }
        lastChangeCount = pasteboard.changeCount

        // Les gestionnaires de mots de passe marquent leurs copies comme « confidentielles » : on les ignore.
        let ignored: Set<String> = ["org.nspasteboard.ConcealedType", "org.nspasteboard.TransientType"]
        if let types = pasteboard.types, types.contains(where: { ignored.contains($0.rawValue) }) { return }

        guard let text = pasteboard.string(forType: .string),
              !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        add(text)
    }

    private func add(_ text: String) {
        var pinned = false
        if let index = items.firstIndex(where: { $0.text == text }) {
            pinned = items[index].pinned
            items.remove(at: index)
        }
        items.insert(ClipboardItem(text: text, pinned: pinned), at: 0)
        trim()
        save()
    }

    /// Remet l'élément dans le presse-papiers et le place en tête de l'historique.
    func copy(_ item: ClipboardItem) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(item.text, forType: .string)
        lastChangeCount = pasteboard.changeCount
        add(item.text)
    }

    func togglePin(_ item: ClipboardItem) {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[index].pinned.toggle()
        trim()
        save()
    }

    func delete(_ item: ClipboardItem) {
        items.removeAll { $0.id == item.id }
        save()
    }

    func clearUnpinned() {
        items.removeAll { !$0.pinned }
        save()
    }

    private func trim() {
        var unpinnedSeen = 0
        items = items.filter { item in
            if item.pinned { return true }
            unpinnedSeen += 1
            return unpinnedSeen <= maxItems
        }
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let saved = try? JSONDecoder().decode([ClipboardItem].self, from: data) else { return }
        items = saved
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(items) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
