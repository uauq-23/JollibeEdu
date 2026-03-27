import UIKit

final class ContinueLearningTableViewCell: UITableViewCell {
    static let reuseIdentifier = "ContinueLearningTableViewCell"

    var onActionTapped: (() -> Void)?

    private let thumbnailView = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let progressView = UIProgressView(progressViewStyle: .default)
    private let actionButton = UIButton(type: .system)

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
        onActionTapped = nil
        thumbnailView.image = UIImage(systemName: "play.square")
    }

    private func setup() {
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        let card = UIView()
        card.applyCardStyle()
        contentView.addSubview(card)

        thumbnailView.translatesAutoresizingMaskIntoConstraints = false
        thumbnailView.backgroundColor = AppTheme.mutedOrange.withAlphaComponent(0.3)
        thumbnailView.layer.cornerRadius = 14
        thumbnailView.clipsToBounds = true
        thumbnailView.tintColor = AppTheme.brandOrangeDark
        thumbnailView.contentMode = .scaleAspectFill

        titleLabel.font = UIFont.boldSystemFont(ofSize: 16)
        titleLabel.textColor = AppTheme.textPrimary
        titleLabel.numberOfLines = 2

        subtitleLabel.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        subtitleLabel.textColor = AppTheme.textSecondary
        subtitleLabel.numberOfLines = 0

        progressView.translatesAutoresizingMaskIntoConstraints = false
        progressView.progressTintColor = AppTheme.brandOrange
        progressView.trackTintColor = AppTheme.softBorder

        actionButton.applyPrimaryStyle()
        actionButton.setTitle(L10n.tr("continueLearning.button"), for: .normal)
        actionButton.addTarget(self, action: #selector(handleTap), for: .touchUpInside)

        let infoStack = UIFactory.makeVerticalStack(spacing: 8)
        infoStack.addArrangedSubview(titleLabel)
        infoStack.addArrangedSubview(subtitleLabel)
        infoStack.addArrangedSubview(progressView)
        infoStack.addArrangedSubview(actionButton)

        let row = UIFactory.makeHorizontalStack(spacing: 14, alignment: .top)
        row.addArrangedSubview(thumbnailView)
        row.addArrangedSubview(infoStack)

        card.addSubview(row)
        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            card.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            card.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            card.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),

            row.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            row.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            row.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            row.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16),

            thumbnailView.widthAnchor.constraint(equalToConstant: 92),
            thumbnailView.heightAnchor.constraint(equalToConstant: 92)
        ])
    }

    @objc private func handleTap() {
        onActionTapped?()
    }

    func configure(with course: Course, buttonTitle: String? = nil) {
        ImageLoader.shared.loadImage(from: course.thumbnail, into: thumbnailView, placeholder: UIImage(systemName: "play.square.stack"))
        titleLabel.text = course.displayTitle
        subtitleLabel.text = L10n.tr("continueLearning.subtitle", course.completed_lessons ?? 0, course.total_lessons ?? 0)
        progressView.progress = Float(course.progressPercentValue / 100)
        actionButton.setTitle(buttonTitle ?? L10n.tr("continueLearning.button"), for: .normal)
    }
}
