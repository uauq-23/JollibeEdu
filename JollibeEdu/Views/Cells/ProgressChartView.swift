import UIKit

final class ProgressChartView: UIView {
    private let stackView = UIStackView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        applyCardStyle()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.alignment = .bottom
        stackView.distribution = .fillEqually
        stackView.spacing = 12

        addSubview(stackView)
        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 220),
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: 24),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 18),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -18),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -18)
        ])
    }

    func setValues(_ values: [Double], labels: [String]) {
        stackView.arrangedSubviews.forEach { view in
            stackView.removeArrangedSubview(view)
            view.removeFromSuperview()
        }

        let maxValue = max(values.max() ?? 1, 1)
        for (index, value) in values.enumerated() {
            let container = UIFactory.makeVerticalStack(spacing: 8)
            container.alignment = .center

            let barBackground = UIView()
            barBackground.translatesAutoresizingMaskIntoConstraints = false
            barBackground.backgroundColor = AppTheme.softBorder
            barBackground.layer.cornerRadius = 12

            let barFill = UIView()
            barFill.translatesAutoresizingMaskIntoConstraints = false
            barFill.backgroundColor = AppTheme.brandOrange
            barFill.layer.cornerRadius = 12
            barBackground.addSubview(barFill)

            let height = max(CGFloat(value / maxValue) * 120, 12)
            NSLayoutConstraint.activate([
                barBackground.widthAnchor.constraint(equalToConstant: 24),
                barBackground.heightAnchor.constraint(equalToConstant: 120),
                barFill.leadingAnchor.constraint(equalTo: barBackground.leadingAnchor),
                barFill.trailingAnchor.constraint(equalTo: barBackground.trailingAnchor),
                barFill.bottomAnchor.constraint(equalTo: barBackground.bottomAnchor),
                barFill.heightAnchor.constraint(equalToConstant: height)
            ])

            let valueLabel = UILabel()
            valueLabel.font = UIFont.systemFont(ofSize: 12, weight: .bold)
            valueLabel.textColor = AppTheme.textPrimary
            valueLabel.text = "\(Int(value))"

            let label = UILabel()
            label.font = UIFont.systemFont(ofSize: 12, weight: .semibold)
            label.textColor = AppTheme.textSecondary
            label.text = labels.indices.contains(index) ? labels[index] : "T\(index + 1)"

            container.addArrangedSubview(valueLabel)
            container.addArrangedSubview(barBackground)
            container.addArrangedSubview(label)
            stackView.addArrangedSubview(container)
        }
    }
}
