import Foundation

struct Course: Codable, Equatable {
    var id: String
    var slug: String?
    var title: String
    var description: String
    var thumbnail: String?
    var instructor_name: String?
    var instructor_email: String?
    var category_id: String?
    var category_name: String?
    var student_count: Int?
    var review_count: Int?
    var rating: Double?
    var duration: String?
    var price: Double?
    var status: String?
    var created_at: String?
    var progress: Double?
    var completed_lessons: Int?
    var total_lessons: Int?
    var version: Int? = 1
    var base_course_id: String? = nil

    var formattedPrice: String {
        AppFormatting.vnd(price)
    }

    var displayTitle: String {
        let versionValue = max(version ?? 1, 1)
        guard versionValue > 1 else { return title }
        return "\(title) v\(versionValue)"
    }

    var progressPercentValue: Double {
        let rawValue = progress ?? 0
        if rawValue > 0, rawValue <= 1 {
            return rawValue * 100
        }
        return rawValue
    }

    var isCompletedCourse: Bool {
        if let completedLessons = completed_lessons,
           let totalLessons = total_lessons,
           totalLessons > 0 {
            return completedLessons >= totalLessons
        }
        return progressPercentValue >= 100
    }
}
