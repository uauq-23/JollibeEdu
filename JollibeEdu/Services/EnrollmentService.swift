import Foundation

final class EnrollmentService {
    static let shared = EnrollmentService()
    private let demoStore = DemoDataStore.shared

    private init() {}

    func getMyEnrolledCourses(page: Int, limit: Int) async throws -> [Course] {
        return try demoStore.myEnrolledCourses(page: page, limit: limit)
    }

    func getEnrolledStudents(courseId: String, page: Int, limit: Int) async throws -> [User] {
        return try demoStore.enrolledStudents(courseID: courseId, page: page, limit: limit)
    }

    func checkEnrollment(courseId: String) async throws -> Bool {
        return try demoStore.isEnrolled(courseID: courseId)
    }

    func enroll(courseId: String) async throws -> Enrollment {
        return try demoStore.enroll(courseID: courseId)
    }

    func unenroll(courseId: String) async throws {
        try demoStore.unenroll(courseID: courseId)
    }

    func updateStatus(courseId: String, status: String) async throws {
        try demoStore.updateEnrollmentStatus(courseID: courseId, status: status)
    }
}
