import Foundation
import CoreData

extension Book {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Book> {
        return NSFetchRequest<Book>(entityName: "Book")
    }

    @NSManaged public var artFilename: String?
    @NSManaged public var audioFilename: String
    @NSManaged public var author: String?
    @NSManaged public var dateAdded: Date
    @NSManaged public var durationSeconds: Double
    @NSManaged public var id: UUID
    @NSManaged public var lastPlayedAt: Date?
    @NSManaged public var playbackRate: Float
    @NSManaged public var progressSeconds: Double
    @NSManaged public var series: String?
    @NSManaged public var seriesIndex: Int16
    @NSManaged public var sourceURL: String
    @NSManaged public var title: String
    @NSManaged public var bookmarks: NSSet?
    @NSManaged public var chapters: NSSet?

}

// MARK: - Bookmark accessors

extension Book {
    @objc(addBookmarksObject:)
    @NSManaged public func addToBookmarks(_ value: Bookmark)

    @objc(removeBookmarksObject:)
    @NSManaged public func removeFromBookmarks(_ value: Bookmark)

    @objc(addBookmarks:)
    @NSManaged public func addToBookmarks(_ values: NSSet)

    @objc(removeBookmarks:)
    @NSManaged public func removeFromBookmarks(_ values: NSSet)
}

// MARK: - Chapter accessors

extension Book {
    @objc(addChaptersObject:)
    @NSManaged public func addToChapters(_ value: Chapter)

    @objc(removeChaptersObject:)
    @NSManaged public func removeFromChapters(_ value: Chapter)

    @objc(addChapters:)
    @NSManaged public func addToChapters(_ values: NSSet)

    @objc(removeChapters:)
    @NSManaged public func removeFromChapters(_ values: NSSet)
}

extension Book: Identifiable {}
