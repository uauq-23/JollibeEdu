import UIKit

final class StatsCardCollectionViewCell: UICollectionViewCell {
    static let reuseIdentifier = "StatsCardCollectionViewCell"

    private let iconView = UIImageView()
    private let titleLabel = UILabel()
    private let valueLabel = UILabel()
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
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.tintColor = AppTheme.brandOrange
        iconView.contentMode = .scaleAspectFit
        iconView.heightAnchor.constraint(equalToConstant: 24).isActive = true
        iconView.widthAnchor.constraint(equalToConstant: 24).isActive = true

        titleLabel.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
        titleLabel.textColor = AppTheme.textSecondary
        titleLabel.numberOfLines = 2

        valueLabel.font = UIFont.boldSystemFont(ofSize: 28)
        valueLabel.textColor = AppTheme.textPrimary

        subtitleLabel.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        subtitleLabel.textColor = AppTheme.textSecondary
        subtitleLabel.numberOfLines = 2

        stack.addArrangedSubview(iconView)
        stack.addArrangedSubview(titleLabel)
        stack.addArrangedSubview(valueLabel)
        stack.addArrangedSubview(subtitleLabel)
        contentView.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16)
        ])
    }

    func configure(symbol: String, title: String, value: String, subtitle: String? = nil) {
        iconView.image = UIImage(systemName: symbol)
        titleLabel.text = title
        valueLabel.text = value
        subtitleLabel.text = subtitle
        subtitleLabel.isHidden = subtitle == nil
    }
}
