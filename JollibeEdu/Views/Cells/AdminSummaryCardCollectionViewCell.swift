import UIKit

final class AdminSummaryCardCollectionViewCell: UICollectionViewCell {
    static let reuseIdentifier = "AdminSummaryCardCollectionViewCell"

    private let titleLabel = UILabel()
    private let valueLabel = UILabel()
    private let iconView = UIImageView()
    private let iconContainer = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        contentView.applyCardStyle()
        iconContainer.translatesAutoresizingMaskIntoConstraints = false
        iconContainer.backgroundColor = AppTheme.mutedOrange.withAlphaComponent(0.35)
        iconContainer.layer.cornerRadius = 18

        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.tintColor = AppTheme.brandOrange
        iconView.contentMode = .scaleAspectFit
        iconContainer.addSubview(iconView)

        titleLabel.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
        titleLabel.textColor = AppTheme.textSecondary
        titleLabel.numberOfLines = 2

        valueLabel.font = UIFont.boldSystemFont(ofSize: 26)
        valueLabel.textColor = AppTheme.textPrimary

        let stack = UIFactory.makeVerticalStack(spacing: 8)
        let iconRow = UIFactory.makeHorizontalStack(spacing: 0, alignment: .center, distribution: .fill)
        iconRow.addArrangedSubview(iconContainer)
        iconRow.addArrangedSubview(UIView())

        stack.addArrangedSubview(iconRow)
        stack.addArrangedSubview(titleLabel)
        stack.addArrangedSubview(valueLabel)

        contentView.addSubview(stack)
        NSLayoutConstraint.activate([
            iconContainer.heightAnchor.constraint(equalToConstant: 36),
            iconContainer.widthAnchor.constraint(equalToConstant: 36),
            iconView.heightAnchor.constraint(equalToConstant: 22),
            iconView.widthAnchor.constraint(equalToConstant: 22),
            iconView.centerXAnchor.constraint(equalTo: iconContainer.centerXAnchor),
            iconView.centerYAnchor.constraint(equalTo: iconContainer.centerYAnchor),
            stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16)
        ])
    }

    func configure(symbol: String, title: String, value: String) {
        iconView.image = UIImage(systemName: symbol)
        titleLabel.text = title
        valueLabel.text = value
    }
}
