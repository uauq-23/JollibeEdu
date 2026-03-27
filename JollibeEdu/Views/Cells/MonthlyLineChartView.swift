import UIKit

final class MonthlyLineChartView: UIView {
    private let titleLabel = UILabel()
    private let lineLayer = CAShapeLayer()
    private let gridLayer = CAShapeLayer()
    private let labelsStack = UIStackView()
    private var values: [Double] = []
    private var labels: [String] = []

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
        layer.addSublayer(gridLayer)
        layer.addSublayer(lineLayer)

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = UIFont.boldSystemFont(ofSize: 18)
        titleLabel.textColor = AppTheme.textPrimary
        titleLabel.text = "Monthly Trend"

        labelsStack.translatesAutoresizingMaskIntoConstraints = false
        labelsStack.axis = .horizontal
        labelsStack.spacing = 8
        labelsStack.distribution = .fillEqually

        addSubview(titleLabel)
        addSubview(labelsStack)

        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 240),
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 18),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 18),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -18),
            labelsStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 18),
            labelsStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -18),
            labelsStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -14)
        ])

        gridLayer.strokeColor = AppTheme.softBorder.cgColor
        gridLayer.fillColor = UIColor.clear.cgColor
        gridLayer.lineWidth = 1
        gridLayer.lineDashPattern = [4, 4]

        lineLayer.strokeColor = AppTheme.brandOrange.cgColor
        lineLayer.fillColor = UIColor.clear.cgColor
        lineLayer.lineWidth = 3
        lineLayer.lineJoin = .round
        lineLayer.lineCap = .round
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        redraw()
    }

    func setData(labels: [String], values: [Double]) {
        self.labels = labels
        self.values = values

        labelsStack.arrangedSubviews.forEach { view in
            labelsStack.removeArrangedSubview(view)
            view.removeFromSuperview()
        }

        for labelText in labels {
            let label = UILabel()
            label.text = labelText
            label.font = UIFont.systemFont(ofSize: 12, weight: .semibold)
            label.textColor = AppTheme.textSecondary
            label.textAlignment = .center
            labelsStack.addArrangedSubview(label)
        }

        redraw()
    }

    private func redraw() {
        guard !values.isEmpty else { return }

        let chartFrame = CGRect(x: 18, y: 56, width: bounds.width - 36, height: 130)
        let gridPath = UIBezierPath()
        for step in 0 ... 3 {
            let y = chartFrame.minY + (chartFrame.height / 3) * CGFloat(step)
            gridPath.move(to: CGPoint(x: chartFrame.minX, y: y))
            gridPath.addLine(to: CGPoint(x: chartFrame.maxX, y: y))
        }
        gridLayer.path = gridPath.cgPath

        let maxValue = max(values.max() ?? 1, 1)
        let spacing = chartFrame.width / CGFloat(max(values.count - 1, 1))
        let path = UIBezierPath()

        for (index, value) in values.enumerated() {
            let x = chartFrame.minX + spacing * CGFloat(index)
            let y = chartFrame.maxY - (CGFloat(value / maxValue) * chartFrame.height)
            let point = CGPoint(x: x, y: y)

            if index == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }

            let dot = UIBezierPath(arcCenter: point, radius: 4, startAngle: 0, endAngle: .pi * 2, clockwise: true)
            path.append(dot)
        }

        lineLayer.path = path.cgPath
    }
}
