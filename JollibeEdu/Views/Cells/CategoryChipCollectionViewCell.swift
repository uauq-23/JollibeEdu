import UIKit

final class CategoryChipCollectionViewCell: UICollectionViewCell {
    static let reuseIdentifier = "CategoryChipCollectionViewCell"

    private let titleLabel = UILabel()

    override var isSelected: Bool {
        didSet { updateStyle() }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        contentView.layer.cornerRadius = AppTheme.pillCornerRadius
        contentView.layer.borderWidth = 1

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        titleLabel.textAlignment = .center

        contentView.addSubview(titleLabel)
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 9),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 14),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -14),
            titleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -9)
        ])
        updateStyle()
    }

    private func updateStyle() {
        contentView.backgroundColor = isSelected ? AppTheme.brandOrange : AppTheme.cardBackground
        contentView.layer.borderColor = (isSelected ? AppTheme.brandOrange : AppTheme.softBorder).cgColor
        titleLabel.textColor = isSelected ? .white : AppTheme.brandOrangeDark
    }

    func configure(title: String) {
        titleLabel.text = title
    }
}
