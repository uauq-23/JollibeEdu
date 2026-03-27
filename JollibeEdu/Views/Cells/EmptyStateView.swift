import UIKit

final class EmptyStateView: UIView {
    var onActionTapped: (() -> Void)?

    private let iconView = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let button = UIButton(type: .system)

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

        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.tintColor = AppTheme.brandOrange
        iconView.contentMode = .scaleAspectFit

        titleLabel.font = UIFont.boldSystemFont(ofSize: 20)
        titleLabel.textColor = AppTheme.textPrimary
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0

        subtitleLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        subtitleLabel.textColor = AppTheme.textSecondary
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 0

        button.applyPrimaryStyle()
        button.isHidden = true
        button.addTarget(self, action: #selector(handleAction), for: .touchUpInside)

        let stack = UIFactory.makeVerticalStack(spacing: 10)
        stack.alignment = .center
        stack.addArrangedSubview(iconView)
        stack.addArrangedSubview(titleLabel)
        stack.addArrangedSubview(subtitleLabel)
        stack.addArrangedSubview(button)
        addSubview(stack)

        NSLayoutConstraint.activate([
            iconView.heightAnchor.constraint(equalToConstant: 48),
            iconView.widthAnchor.constraint(equalToConstant: 48),
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 24),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -24)
        ])
    }

    @objc private func handleAction() {
        onActionTapped?()
    }

    func configure(icon: String, title: String, subtitle: String, actionTitle: String? = nil) {
        iconView.image = UIImage(systemName: icon)
        titleLabel.text = title
        subtitleLabel.text = subtitle
        button.isHidden = actionTitle == nil
        button.setTitle(actionTitle, for: .normal)
    }
}
