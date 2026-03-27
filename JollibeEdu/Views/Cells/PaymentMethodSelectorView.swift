import UIKit

final class PaymentMethodSelectorView: UIView {
    enum Method: String, CaseIterable {
        case bankCard = "bank_card"
        case momo = "momo_qr"

        var title: String {
            switch self {
            case .bankCard:
                return L10n.tr("payment.method.bankCard")
            case .momo:
                return L10n.tr("payment.method.momo")
            }
        }
    }

    var onMethodChanged: ((Method) -> Void)?

    private let segmentedControl = UISegmentedControl(items: Method.allCases.map(\.title))

    var selectedMethod: Method {
        Method.allCases[segmentedControl.selectedSegmentIndex]
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        applyCardStyle(backgroundColor: AppTheme.cardBackground)
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        segmentedControl.selectedSegmentIndex = 0
        segmentedControl.addTarget(self, action: #selector(valueChanged), for: .valueChanged)
        addSubview(segmentedControl)

        NSLayoutConstraint.activate([
            segmentedControl.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            segmentedControl.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            segmentedControl.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            segmentedControl.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12)
        ])
    }

    @objc private func valueChanged() {
        onMethodChanged?(selectedMethod)
    }
}
