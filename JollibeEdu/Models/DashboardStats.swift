import Foundation

struct DashboardStats: Codable, Equatable {
    var inProgressCount: Int
    var completedCount: Int
    var totalLessons: Int
    var averageProgress: Int
}
