import Foundation
import CoreData

extension Chapter {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Chapter> {
        return NSFetchRequest<Chapter>(entityName: "Chapter")
    }

    @NSManaged public var endSeconds: Double
    @NSManaged public var id: UUID
    @NSManaged public var startSeconds: Double
    @NSManaged public var title: String
    @NSManaged public var book: Book

}

extension Chapter: Identifiable {}
