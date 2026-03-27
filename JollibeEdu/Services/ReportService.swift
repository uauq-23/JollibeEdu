import Foundation

final class ReportService {
    static let shared = ReportService()
    private let demoStore = DemoDataStore.shared

    private init() {}

    func getSystemStatistics() async throws -> ReportSummary {
        return demoStore.systemStatistics()
    }

    func getCourseStatistics(courseId: String) async throws -> CourseStatistic {
        return try demoStore.courseStatistics(courseID: courseId)
    }

    func getStudentStatistics(courseId: String, page: Int, limit: Int) async throws -> [StudentStatistic] {
        return try demoStore.studentStatistics(courseID: courseId, page: page, limit: limit)
    }

    func getInstructorStatistics(instructorId: String) async throws -> InstructorStatistic {
        return try demoStore.instructorStatistics(instructorID: instructorId)
    }

    func getTopCourses(limit: Int) async throws -> [Course] {
        return demoStore.topCourses(limit: limit)
    }

    func getMonthlyReport(year: Int, month: Int) async throws -> MonthlyReport {
        return demoStore.monthlyReport(year: year, month: month)
    }
}
