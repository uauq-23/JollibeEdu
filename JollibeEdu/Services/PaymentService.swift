import Foundation

final class PaymentService {
    static let shared = PaymentService()
    private let demoStore = DemoDataStore.shared

    private init() {}

    func create(courseId: String, method: String = "bank_card") async throws -> Payment {
        return try demoStore.createPayment(courseID: courseId, paymentMethod: method)
    }

    func confirm(paymentId: Int) async throws -> Payment {
        return try demoStore.confirmPayment(paymentID: paymentId)
    }
}
