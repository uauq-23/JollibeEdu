import Foundation

struct Payment: Codable, Equatable {
    var id: Int
    var course_id: String
    var amount: Double
    var status: String
    var payment_method: String?
}
