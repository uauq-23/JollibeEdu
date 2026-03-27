import UIKit

final class AdminListTableViewCell: UITableViewCell {
    static let reuseIdentifier = "AdminListTableViewCell"

    var onPrimaryTapped: (() -> Void)?
    var onSecondaryTapped: (() -> Void)?
    var onTertiaryTapped: (() -> Void)?

    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let statusLabel = UILabel()
    private let primaryButton = UIButton(type: .system)
    private let secondaryButton = UIButton(type: .system)
    private let tertiaryButton = UIButton(type: .system)

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        onPrimaryTapped = nil
        onSecondaryTapped = nil
        onTertiaryTapped = nil
    }

    private func setup() {
        selectionStyle = .none
        backgroundColor = .clear

        let card = UIView()
        card.applyCardStyle()
        contentView.addSubview(card)

        titleLabel.font = UIFont.boldSystemFont(ofSize: 16)
        titleLabel.textColor = AppTheme.textPrimary
        titleLabel.numberOfLines = 2

        subtitleLabel.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        subtitleLabel.textColor = AppTheme.textSecondary
        subtitleLabel.numberOfLines = 0

        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.font = UIFont.systemFont(ofSize: 12, weight: .bold)
        statusLabel.textAlignment = .center
        statusLabel.layer.cornerRadius = 12
        statusLabel.clipsToBounds = true
        NSLayoutConstraint.activate([
            statusLabel.heightAnchor.constraint(equalToConstant: 24)
        ])

        primaryButton.applySecondaryOutlineStyle()
        secondaryButton.applyPrimaryStyle()
        tertiaryButton.applyDestructiveOutlineStyle()
        primaryButton.addTarget(self, action: #selector(handlePrimary), for: .touchUpInside)
        secondaryButton.addTarget(self, action: #selector(handleSecondary), for: .touchUpInside)
        tertiaryButton.addTarget(self, action: #selector(handleTertiary), for: .touchUpInside)

        let buttonRow = UIFactory.makeHorizontalStack(spacing: 10, alignment: .center, distribution: .fillEqually)
        buttonRow.addArrangedSubview(primaryButton)
        buttonRow.addArrangedSubview(secondaryButton)
        buttonRow.addArrangedSubview(tertiaryButton)

        let statusRow = UIFactory.makeHorizontalStack(spacing: 8, alignment: .center, distribution: .fill)
        statusRow.addArrangedSubview(statusLabel)
        statusRow.addArrangedSubview(UIView())

        let infoStack = UIFactory.makeVerticalStack(spacing: 8)
        infoStack.addArrangedSubview(titleLabel)
        infoStack.addArrangedSubview(subtitleLabel)
        infoStack.addArrangedSubview(statusRow)
        infoStack.addArrangedSubview(buttonRow)

        card.addSubview(infoStack)
        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            card.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            card.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            card.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),

            infoStack.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            infoStack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            infoStack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            infoStack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16)
        ])
    }

    @objc private func handlePrimary() {
        onPrimaryTapped?()
    }

    @objc private func handleSecondary() {
        onSecondaryTapped?()
    }

    @objc private func handleTertiary() {
        onTertiaryTapped?()
    }

    func configure(title: String, subtitle: String, status: String, primaryTitle: String, secondaryTitle: String, tertiaryTitle: String? = nil, statusStyleKey: String? = nil, tertiaryStyleKey: String? = nil) {
        titleLabel.text = title
        subtitleLabel.text = subtitle
        let normalizedStatus = (statusStyleKey ?? status).lowercased()
        statusLabel.text = "  \(L10n.statusName(for: status))  "
        switch normalizedStatus {
        case "published", "active":
            statusLabel.backgroundColor = AppTheme.successGreen.withAlphaComponent(0.15)
            statusLabel.textColor = AppTheme.successGreen
        case "student":
            statusLabel.backgroundColor = AppTheme.brandOrange.withAlphaComponent(0.12)
            statusLabel.textColor = AppTheme.brandOrangeDark
        case "instructor":
            statusLabel.backgroundColor = AppTheme.warningYellow.withAlphaComponent(0.18)
            statusLabel.textColor = AppTheme.warningYellow
        case "admin":
            statusLabel.backgroundColor = AppTheme.dangerRed.withAlphaComponent(0.12)
            statusLabel.textColor = AppTheme.dangerRed
        default:
            statusLabel.backgroundColor = AppTheme.warningYellow.withAlphaComponent(0.18)
            statusLabel.textColor = AppTheme.warningYellow
        }
        primaryButton.setTitle(primaryTitle, for: .normal)
        secondaryButton.setTitle(secondaryTitle, for: .normal)
        tertiaryButton.setTitle(tertiaryTitle, for: .normal)
        tertiaryButton.isHidden = tertiaryTitle == nil
        if tertiaryStyleKey?.lowercased() == "preview" {
            tertiaryButton.applySecondaryOutlineStyle()
        } else {
            tertiaryButton.applyDestructiveOutlineStyle()
        }
    }
}
