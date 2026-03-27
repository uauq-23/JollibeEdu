import Foundation

struct ReportSummary: Codable, Equatable {
    var totalUsers: Int
    var totalCourses: Int
    var totalEnrollments: Int
    var monthlyRevenue: Double
}
