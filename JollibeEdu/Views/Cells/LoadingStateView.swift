import UIKit

final class LoadingStateView: UIView {
    private let spinner = UIActivityIndicatorView(style: .large)
    private let label = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        applyCardStyle()

        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.color = AppTheme.brandOrange
        spinner.startAnimating()

        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Đang tải dữ liệu..."
        label.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        label.textColor = AppTheme.textSecondary

        let stack = UIFactory.makeVerticalStack(spacing: 12)
        stack.alignment = .center
        stack.addArrangedSubview(spinner)
        stack.addArrangedSubview(label)

        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 20),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -20)
        ])
    }
}
