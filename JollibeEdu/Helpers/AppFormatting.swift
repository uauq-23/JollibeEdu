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

    static func durationString(from seconds: Int, alwaysShowHours: Bool = false) -> String {
        let clampedSeconds = max(0, seconds)
        let hours = clampedSeconds / 3600
        let minutes = (clampedSeconds % 3600) / 60
        let remainingSeconds = clampedSeconds % 60

        if alwaysShowHours || hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, remainingSeconds)
        }
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }

    static func seconds(fromDurationString rawValue: String?) -> Int? {
        guard let rawValue else { return nil }
        let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let components = trimmed.split(separator: ":").compactMap { Int($0) }
        switch components.count {
        case 2:
            let minutes = components[0]
            let seconds = components[1]
            guard minutes >= 0, (0..<60).contains(seconds) else { return nil }
            return (minutes * 60) + seconds
        case 3:
            let hours = components[0]
            let minutes = components[1]
            let seconds = components[2]
            guard hours >= 0, (0..<60).contains(minutes), (0..<60).contains(seconds) else { return nil }
            return (hours * 3600) + (minutes * 60) + seconds
        default:
            return nil
        }
    }
}
