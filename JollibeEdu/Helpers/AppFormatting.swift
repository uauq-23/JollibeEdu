import Foundation

enum AppFormatting {
    private static let vndFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "VND"
        formatter.currencySymbol = "₫"
        formatter.maximumFractionDigits = 0
        formatter.locale = Locale(identifier: "vi_VN")
        return formatter
    }()

    static func vnd(_ amount: Double?) -> String {
        guard let amount else { return L10n.tr("common.contact") }
        guard amount > 0 else { return L10n.tr("common.free") }
        return vndFormatter.string(from: NSNumber(value: amount)) ?? "\(Int(amount)) ₫"
    }

    static func percent(_ value: Double?) -> String {
        let clamped = max(0, min(100, Int((value ?? 0).rounded())))
        return "\(clamped)%"
    }

    static func initials(from name: String) -> String {
        let parts = name.split(separator: " ").prefix(2)
        let letters = parts.compactMap { $0.first }
        return String(letters).uppercased()
    }

    static func shortDate(_ rawValue: String?) -> String {
        guard let rawValue, !rawValue.isEmpty else { return L10n.tr("common.today") }
        return rawValue.prefix(10).description
    }
}
