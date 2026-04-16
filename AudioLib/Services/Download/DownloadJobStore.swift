import CoreData

class DownloadJobStore {
    /// Creates and persists a new DownloadJob record in the given context.
    @discardableResult
    static func createJob(id: UUID, sourceURL: String, in context: NSManagedObjectContext) -> DownloadJob {
        let job = DownloadJob(context: context)
        job.id = id
        job.sourceURL = sourceURL
        job.state = "queued"
        job.progress = 0
        job.createdAt = Date()
        try? context.save()
        return job
    }
}
