import UIKit

final class MyCourseTableViewCell: UITableViewCell {
    static let reuseIdentifier = "MyCourseTableViewCell"

    var onActionTapped: (() -> Void)?

    private let thumbnailView = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let progressView = UIProgressView(progressViewStyle: .default)
    private let progressLabel = UILabel()
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
        thumbnailView.image = UIImage(systemName: "book.fill")
    }

    private func setup() {
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        let card = UIView()
        card.applyCardStyle()
        contentView.addSubview(card)

        thumbnailView.translatesAutoresizingMaskIntoConstraints = false
        thumbnailView.layer.cornerRadius = 16
        thumbnailView.clipsToBounds = true
        thumbnailView.contentMode = .scaleAspectFill
        thumbnailView.backgroundColor = AppTheme.mutedOrange.withAlphaComponent(0.25)

        titleLabel.font = UIFont.boldSystemFont(ofSize: 17)
        titleLabel.textColor = AppTheme.textPrimary
        titleLabel.numberOfLines = 2

        subtitleLabel.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        subtitleLabel.textColor = AppTheme.textSecondary
        subtitleLabel.numberOfLines = 2

        progressView.translatesAutoresizingMaskIntoConstraints = false
        progressView.progressTintColor = AppTheme.brandOrange
        progressView.trackTintColor = AppTheme.softBorder

        progressLabel.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
        progressLabel.textColor = AppTheme.brandOrangeDark

        actionButton.applySecondaryOutlineStyle()
        actionButton.addTarget(self, action: #selector(handleTap), for: .touchUpInside)

        let rightStack = UIFactory.makeVerticalStack(spacing: 8)
        rightStack.addArrangedSubview(titleLabel)
        rightStack.addArrangedSubview(subtitleLabel)
        rightStack.addArrangedSubview(progressView)
        rightStack.addArrangedSubview(progressLabel)
        rightStack.addArrangedSubview(actionButton)

        let row = UIFactory.makeHorizontalStack(spacing: 14, alignment: .top)
        row.addArrangedSubview(thumbnailView)
        row.addArrangedSubview(rightStack)

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

            thumbnailView.widthAnchor.constraint(equalToConstant: 104),
            thumbnailView.heightAnchor.constraint(equalToConstant: 96)
        ])
    }

    @objc private func handleTap() {
        onActionTapped?()
    }

    func configure(with course: Course, actionTitle: String) {
        ImageLoader.shared.loadImage(from: course.thumbnail, into: thumbnailView, placeholder: UIImage(systemName: "books.vertical.fill"))
        titleLabel.text = course.displayTitle
        subtitleLabel.text = course.instructor_name ?? "JolibeeEdu"
        progressView.progress = Float(course.progressPercentValue / 100)
        progressLabel.text = "Tiến độ: \(AppFormatting.percent(course.progressPercentValue))"
        actionButton.setTitle(actionTitle, for: .normal)
    }
}
