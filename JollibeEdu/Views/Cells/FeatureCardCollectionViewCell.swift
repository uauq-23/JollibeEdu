import UIKit

final class FeatureCardCollectionViewCell: UICollectionViewCell {
    static let reuseIdentifier = "FeatureCardCollectionViewCell"

    private let iconView = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        contentView.applyCardStyle(backgroundColor: AppTheme.cardBackground)

        let stack = UIFactory.makeVerticalStack(spacing: 10)
        let iconBadge = UIView()
        iconBadge.translatesAutoresizingMaskIntoConstraints = false
        iconBadge.backgroundColor = AppTheme.mutedOrange.withAlphaComponent(0.5)
        iconBadge.layer.cornerRadius = 24
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.tintColor = AppTheme.brandOrangeDark
        iconView.contentMode = .scaleAspectFit
        iconBadge.addSubview(iconView)
        NSLayoutConstraint.activate([
            iconBadge.heightAnchor.constraint(equalToConstant: 48),
            iconBadge.widthAnchor.constraint(equalToConstant: 48),
            iconView.centerXAnchor.constraint(equalTo: iconBadge.centerXAnchor),
            iconView.centerYAnchor.constraint(equalTo: iconBadge.centerYAnchor),
            iconView.heightAnchor.constraint(equalToConstant: 24),
            iconView.widthAnchor.constraint(equalToConstant: 24)
        ])

        titleLabel.font = UIFont.boldSystemFont(ofSize: 18)
        titleLabel.textColor = AppTheme.textPrimary
        titleLabel.numberOfLines = 2

        subtitleLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        subtitleLabel.textColor = AppTheme.textSecondary
        subtitleLabel.numberOfLines = 0

        stack.addArrangedSubview(iconBadge)
        stack.addArrangedSubview(titleLabel)
        stack.addArrangedSubview(subtitleLabel)

        contentView.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 18),
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 18),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -18),
            stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -18)
        ])
    }

    func configure(icon: String, title: String, subtitle: String) {
        iconView.image = UIImage(systemName: icon)
        titleLabel.text = title
        subtitleLabel.text = subtitle
    }
}
