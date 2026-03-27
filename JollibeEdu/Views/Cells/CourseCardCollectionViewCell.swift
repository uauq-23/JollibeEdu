import UIKit

final class CourseCardCollectionViewCell: UICollectionViewCell {
    static let reuseIdentifier = "CourseCardCollectionViewCell"

    var onActionTapped: (() -> Void)?

    private let thumbnailView = UIImageView()
    private let categoryButton = UIButton(type: .system)
    private let titleLabel = UILabel()
    private let descriptionLabel = UILabel()
    private let instructorLabel = UILabel()
    private let metaLabel = UILabel()
    private let priceLabel = UILabel()
    private let actionButton = UIButton(type: .system)

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        thumbnailView.image = UIImage(systemName: "play.square.stack")
        onActionTapped = nil
    }

    private func setup() {
        contentView.applyCardStyle(backgroundColor: AppTheme.cardBackground)

        thumbnailView.translatesAutoresizingMaskIntoConstraints = false
        thumbnailView.contentMode = .scaleAspectFill
        thumbnailView.clipsToBounds = true
        thumbnailView.backgroundColor = AppTheme.mutedOrange.withAlphaComponent(0.25)
        thumbnailView.layer.cornerRadius = 16
        thumbnailView.tintColor = AppTheme.brandOrange

        categoryButton.applyPillStyle()
        categoryButton.isUserInteractionEnabled = false
        categoryButton.titleLabel?.font = UIFont.systemFont(ofSize: 12, weight: .bold)

        titleLabel.font = UIFont.boldSystemFont(ofSize: 18)
        titleLabel.textColor = AppTheme.textPrimary
        titleLabel.numberOfLines = 2

        descriptionLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        descriptionLabel.textColor = AppTheme.textSecondary
        descriptionLabel.numberOfLines = 2

        instructorLabel.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
        instructorLabel.textColor = AppTheme.textPrimary
        instructorLabel.numberOfLines = 1

        metaLabel.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        metaLabel.textColor = AppTheme.textSecondary
        metaLabel.numberOfLines = 1
        metaLabel.adjustsFontSizeToFitWidth = true
        metaLabel.minimumScaleFactor = 0.85

        priceLabel.font = UIFont.boldSystemFont(ofSize: 20)
        priceLabel.textColor = AppTheme.brandOrangeDark
        priceLabel.numberOfLines = 1
        priceLabel.adjustsFontSizeToFitWidth = true
        priceLabel.minimumScaleFactor = 0.85

        actionButton.applyPrimaryStyle()
        actionButton.setTitle(L10n.tr("course.card.viewDetails"), for: .normal)
        actionButton.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        actionButton.addTarget(self, action: #selector(handleAction), for: .touchUpInside)

        let stack = UIFactory.makeVerticalStack(spacing: 8)
        stack.addArrangedSubview(thumbnailView)
        stack.addArrangedSubview(categoryButton)
        stack.addArrangedSubview(titleLabel)
        stack.addArrangedSubview(priceLabel)
        stack.addArrangedSubview(descriptionLabel)
        stack.addArrangedSubview(instructorLabel)
        stack.addArrangedSubview(metaLabel)
        stack.addArrangedSubview(actionButton)

        contentView.addSubview(stack)
        NSLayoutConstraint.activate([
            thumbnailView.heightAnchor.constraint(equalToConstant: 136),
            actionButton.heightAnchor.constraint(equalToConstant: 40),
            stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16)
        ])
    }

    @objc private func handleAction() {
        onActionTapped?()
    }

    func configure(with course: Course, actionTitle: String? = nil) {
        ImageLoader.shared.loadImage(from: course.thumbnail, into: thumbnailView, placeholder: UIImage(systemName: "photo.on.rectangle.angled"))
        categoryButton.setTitle(course.category_name ?? L10n.tr("course.card.fallbackCategory"), for: .normal)
        titleLabel.text = course.displayTitle
        descriptionLabel.text = course.description
        instructorLabel.text = L10n.tr("course.card.instructor", course.instructor_name ?? L10n.tr("course.detail.fallbackInstructorName"))
        metaLabel.text = L10n.tr("course.card.studentsMeta", course.student_count ?? 0, course.rating ?? 0)
        priceLabel.text = course.formattedPrice
        actionButton.setTitle(actionTitle ?? L10n.tr("course.card.viewDetails"), for: .normal)
    }
}
