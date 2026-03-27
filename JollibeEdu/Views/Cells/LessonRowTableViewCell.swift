import UIKit

final class LessonRowTableViewCell: UITableViewCell {
    static let reuseIdentifier = "LessonRowTableViewCell"

    private let numberLabel = UILabel()
    private let titleLabel = UILabel()
    private let durationLabel = UILabel()
    private let statusImageView = UIImageView()
    private let actionLabel = UILabel()

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

        numberLabel.translatesAutoresizingMaskIntoConstraints = false
        numberLabel.font = UIFont.boldSystemFont(ofSize: 16)
        numberLabel.textColor = AppTheme.brandOrangeDark
        numberLabel.textAlignment = .center
        numberLabel.backgroundColor = AppTheme.mutedOrange.withAlphaComponent(0.45)
        numberLabel.layer.cornerRadius = 20
        numberLabel.clipsToBounds = true

        titleLabel.font = UIFont.boldSystemFont(ofSize: 16)
        titleLabel.textColor = AppTheme.textPrimary
        titleLabel.numberOfLines = 2

        durationLabel.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        durationLabel.textColor = AppTheme.textSecondary

        statusImageView.translatesAutoresizingMaskIntoConstraints = false
        statusImageView.contentMode = .scaleAspectFit

        actionLabel.font = UIFont.systemFont(ofSize: 13, weight: .semibold)

        let textStack = UIFactory.makeVerticalStack(spacing: 4)
        textStack.addArrangedSubview(titleLabel)
        textStack.addArrangedSubview(durationLabel)
        textStack.addArrangedSubview(actionLabel)

        let row = UIFactory.makeHorizontalStack(spacing: 14)
        row.addArrangedSubview(numberLabel)
        row.addArrangedSubview(textStack)
        row.addArrangedSubview(statusImageView)

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

            numberLabel.widthAnchor.constraint(equalToConstant: 40),
            numberLabel.heightAnchor.constraint(equalToConstant: 40),
            statusImageView.widthAnchor.constraint(equalToConstant: 22),
            statusImageView.heightAnchor.constraint(equalToConstant: 22)
        ])
    }

    func configure(lesson: Lesson, completed: Bool, locked: Bool, current: Bool) {
        numberLabel.text = "\(lesson.lesson_order)"
        titleLabel.text = lesson.title
        durationLabel.text = lesson.duration ?? "--:--"

        if locked {
            statusImageView.image = UIImage(systemName: "lock.fill")
            statusImageView.tintColor = AppTheme.textSecondary
            actionLabel.text = L10n.tr("lesson.row.locked")
            actionLabel.textColor = AppTheme.textSecondary
        } else if completed {
            statusImageView.image = UIImage(systemName: "checkmark.circle.fill")
            statusImageView.tintColor = AppTheme.successGreen
            actionLabel.text = L10n.tr("lesson.row.completed")
            actionLabel.textColor = AppTheme.successGreen
        } else if current {
            statusImageView.image = UIImage(systemName: "play.circle.fill")
            statusImageView.tintColor = AppTheme.brandOrange
            actionLabel.text = L10n.tr("lesson.row.current")
            actionLabel.textColor = AppTheme.brandOrangeDark
        } else {
            statusImageView.image = UIImage(systemName: "play.circle")
            statusImageView.tintColor = AppTheme.brandOrangeDark
            actionLabel.text = L10n.tr("lesson.row.start")
            actionLabel.textColor = AppTheme.brandOrangeDark
        }
    }
}
