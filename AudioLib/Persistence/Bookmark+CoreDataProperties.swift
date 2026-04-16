import Foundation
import CoreData

extension Bookmark {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Bookmark> {
        return NSFetchRequest<Bookmark>(entityName: "Bookmark")
    }

    @NSManaged public var createdAt: Date
    @NSManaged public var id: UUID
    @NSManaged public var note: String?
    @NSManaged public var timeSeconds: Double
    @NSManaged public var book: Book

}

extension Bookmark: Identifiable {}
