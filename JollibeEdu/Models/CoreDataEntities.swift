import CoreData
import Foundation

@objc(StoredDemoState)
final class StoredDemoState: NSManagedObject {}

extension StoredDemoState {
    @nonobjc class func fetchRequest() -> NSFetchRequest<StoredDemoState> {
        NSFetchRequest<StoredDemoState>(entityName: "StoredDemoState")
    }

    @NSManaged var storeID: String
    @NSManaged var payload: Data
    @NSManaged var updatedAt: Date?
}

@objc(StoredAccount)
final class StoredAccount: NSManagedObject {}

extension StoredAccount {
    @nonobjc class func fetchRequest() -> NSFetchRequest<StoredAccount> {
        NSFetchRequest<StoredAccount>(entityName: "StoredAccount")
    }

    @NSManaged var userID: String
    @NSManaged var fullName: String
    @NSManaged var email: String
    @NSManaged var role: String
    @NSManaged var username: String?
    @NSManaged var avatar: String?
    @NSManaged var createdAt: String?
    @NSManaged var password: String
}

@objc(StoredSession)
final class StoredSession: NSManagedObject {}

extension StoredSession {
    @nonobjc class func fetchRequest() -> NSFetchRequest<StoredSession> {
        NSFetchRequest<StoredSession>(entityName: "StoredSession")
    }

    @NSManaged var token: String
    @NSManaged var userID: String
    @NSManaged var fullName: String
    @NSManaged var email: String
    @NSManaged var role: String
    @NSManaged var username: String?
    @NSManaged var avatar: String?
    @NSManaged var createdAt: String?
}

@objc(StoredPreference)
final class StoredPreference: NSManagedObject {}

extension StoredPreference {
    @nonobjc class func fetchRequest() -> NSFetchRequest<StoredPreference> {
        NSFetchRequest<StoredPreference>(entityName: "StoredPreference")
    }

    @NSManaged var storeID: String
    @NSManaged var rememberedEmail: String?
}

@objc(StoredEnrollment)
final class StoredEnrollment: NSManagedObject {}

extension StoredEnrollment {
    @nonobjc class func fetchRequest() -> NSFetchRequest<StoredEnrollment> {
        NSFetchRequest<StoredEnrollment>(entityName: "StoredEnrollment")
    }

    @NSManaged var userID: String
    @NSManaged var courseID: String
    @NSManaged var status: String
    @NSManaged var progress: Double
}

@objc(StoredProgress)
final class StoredProgress: NSManagedObject {}

extension StoredProgress {
    @nonobjc class func fetchRequest() -> NSFetchRequest<StoredProgress> {
        NSFetchRequest<StoredProgress>(entityName: "StoredProgress")
    }

    @NSManaged var userID: String
    @NSManaged var courseID: String
    @NSManaged var lessonID: String
    @NSManaged var completed: Bool
    @NSManaged var completedAt: String?
}
