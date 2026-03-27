import Foundation

final class ProgressService {
    static let shared = ProgressService()
    private let demoStore = DemoDataStore.shared

    private init() {}

    func updateProgress(lessonId: String, courseId: String) async throws -> ProgressRecord {
        return try demoStore.updateProgress(lessonID: lessonId, courseID: courseId)
    }

    func getStudentProgress(courseId: String) async throws -> [ProgressRecord] {
        return try demoStore.studentProgress(courseID: courseId)
    }

    func getMyProgress() async throws -> [Course] {
        return try demoStore.myProgress()
    }

    func checkCompletion(lessonId: String) async throws -> Bool {
        return try demoStore.hasCompleted(lessonID: lessonId)
    }

    func getCourseStats(courseId: String) async throws -> DashboardStats {
        return demoStore.courseStats(courseID: courseId)
    }
}
