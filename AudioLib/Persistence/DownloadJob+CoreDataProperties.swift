import Foundation
import CoreData

extension DownloadJob {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<DownloadJob> {
        return NSFetchRequest<DownloadJob>(entityName: "DownloadJob")
    }

    @NSManaged public var createdAt: Date
    @NSManaged public var errorMessage: String?
    @NSManaged public var id: UUID
    @NSManaged public var progress: Double
    @NSManaged public var resultingBookID: UUID?
    @NSManaged public var sourceURL: String
    @NSManaged public var state: String

}

extension DownloadJob: Identifiable {}
