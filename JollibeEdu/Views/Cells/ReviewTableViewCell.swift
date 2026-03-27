import UIKit

final class ReviewTableViewCell: UITableViewCell {
    static let reuseIdentifier = "ReviewTableViewCell"

    private let nameLabel = UILabel()
    private let starsLabel = UILabel()
    private let reviewLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        selectionStyle = .none
        backgroundColor = .clear

        let card = UIView()
        card.applyCardStyle()
        contentView.addSubview(card)

        nameLabel.font = UIFont.boldSystemFont(ofSize: 15)
        nameLabel.textColor = AppTheme.textPrimary

        starsLabel.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
        starsLabel.textColor = AppTheme.warningYellow

        reviewLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        reviewLabel.textColor = AppTheme.textSecondary
        reviewLabel.numberOfLines = 0

        let stack = UIFactory.makeVerticalStack(spacing: 8)
        stack.addArrangedSubview(nameLabel)
        stack.addArrangedSubview(starsLabel)
        stack.addArrangedSubview(reviewLabel)
        card.addSubview(stack)

        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            card.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            card.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            card.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            stack.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16)
        ])
    }

    func configure(name: String, rating: Int, review: String) {
        nameLabel.text = name
        starsLabel.text = String(repeating: "★", count: max(1, rating))
        reviewLabel.text = review
    }
}
