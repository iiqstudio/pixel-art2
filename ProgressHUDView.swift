import UIKit

final class ProgressHUDView: UIView {

    private let titleLabel = UILabel()
    private let detailLabel = UILabel()
    private let barBackground = UIView()
    private let barFill = UIView()

    private var barFillWidth: NSLayoutConstraint!

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setup() {
        backgroundColor = UIColor.secondarySystemBackground.withAlphaComponent(0.92)
        layer.cornerRadius = 14
        layer.masksToBounds = true

        titleLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        detailLabel.font = .systemFont(ofSize: 12, weight: .regular)
        detailLabel.textColor = .secondaryLabel

        barBackground.backgroundColor = UIColor.tertiarySystemFill
        barBackground.layer.cornerRadius = 6
        barBackground.layer.masksToBounds = true

        barFill.backgroundColor = .systemBlue
        barFill.layer.cornerRadius = 6
        barFill.layer.masksToBounds = true

        let labels = UIStackView(arrangedSubviews: [titleLabel, detailLabel])
        labels.axis = .vertical
        labels.spacing = 2

        let root = UIStackView(arrangedSubviews: [labels, barBackground])
        root.axis = .vertical
        root.spacing = 8
        root.translatesAutoresizingMaskIntoConstraints = false

        addSubview(root)

        barBackground.translatesAutoresizingMaskIntoConstraints = false
        barFill.translatesAutoresizingMaskIntoConstraints = false
        barBackground.addSubview(barFill)

        barFillWidth = barFill.widthAnchor.constraint(equalToConstant: 0)

        NSLayoutConstraint.activate([
            root.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            root.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            root.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            root.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10),

            barBackground.heightAnchor.constraint(equalToConstant: 12),

            barFill.leadingAnchor.constraint(equalTo: barBackground.leadingAnchor),
            barFill.topAnchor.constraint(equalTo: barBackground.topAnchor),
            barFill.bottomAnchor.constraint(equalTo: barBackground.bottomAnchor),
            barFillWidth
        ])

        // дефолтный текст, чтобы сразу видно было
        titleLabel.text = "Color 1"
        detailLabel.text = "0 / 0 (0%)"
    }

    func set(colorNumber: UInt8, painted: Int, total: Int, barColor: UIColor) {
        titleLabel.text = "Color \(colorNumber)"

        let p: CGFloat
        if total > 0 {
            let pct = Int((Double(painted) / Double(total)) * 100.0)
            detailLabel.text = "\(painted) / \(total)  (\(pct)%)"
            p = CGFloat(Double(painted) / Double(total))
        } else {
            detailLabel.text = "0 cells"
            p = 0
        }

        barFill.backgroundColor = barColor

        // обновляем ширину бара
        layoutIfNeeded()
        let full = barBackground.bounds.width
        barFillWidth.constant = full * max(0, min(1, p))

        UIView.animate(withDuration: 0.12) {
            self.layoutIfNeeded()
        }
    }
}

