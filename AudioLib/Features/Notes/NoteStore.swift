import CoreData

class NoteStore {
    static func create(title: String, in context: NSManagedObjectContext) -> NoteDoc {
        let note = NoteDoc(context: context)
        note.id = UUID()
        note.title = title.isEmpty ? "Untitled" : title
        note.rtfData = nil
        note.createdAt = Date()
        note.updatedAt = Date()
        try? context.save()
        return note
    }

    static func save(_ note: NoteDoc, attributedString: NSAttributedString, in context: NSManagedObjectContext) {
        note.title = Self.extractTitle(from: attributedString) ?? note.title
        note.rtfData = Self.toRTF(attributedString)
        note.updatedAt = Date()
        try? context.save()
    }

    static func toRTF(_ attrStr: NSAttributedString) -> Data? {
        guard attrStr.length > 0 else { return nil }
        return try? attrStr.data(
            from: NSRange(location: 0, length: attrStr.length),
            documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf]
        )
    }

    static func fromRTF(_ data: Data) -> NSAttributedString? {
        return try? NSAttributedString(
            data: data,
            options: [.documentType: NSAttributedString.DocumentType.rtf],
            documentAttributes: nil
        )
    }

    // Use first non-empty line as title (max 50 chars)
    static func extractTitle(from attrStr: NSAttributedString) -> String? {
        let text = attrStr.string
        let firstLine = text.components(separatedBy: "\n").first(where: { !$0.trimmingCharacters(in: .whitespaces).isEmpty })
        guard let line = firstLine, !line.isEmpty else { return nil }
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        return trimmed.count > 50 ? String(trimmed.prefix(50)) : trimmed
    }
}
