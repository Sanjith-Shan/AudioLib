import Foundation
import CoreData

extension NoteDoc {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<NoteDoc> {
        return NSFetchRequest<NoteDoc>(entityName: "NoteDoc")
    }

    @NSManaged public var createdAt: Date
    @NSManaged public var id: UUID
    @NSManaged public var linkedBookID: UUID?
    @NSManaged public var rtfData: Data?
    @NSManaged public var title: String
    @NSManaged public var updatedAt: Date

}

extension NoteDoc: Identifiable {}
