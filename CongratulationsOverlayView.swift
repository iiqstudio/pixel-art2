import UIKit

final class CongratulationsOverlayView: UIView {

    var onBackToGallery: (() -> Void)?
    var onContinue: (() -> Void)?

    private let dim = UIView()
    private let card = UIView()

    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()

    private let backButton = UIButton(type: .system)
    private let continueButton = UIButton(type: .system)

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setup() {
        isHidden = true
        alpha = 0

        dim.backgroundColor = UIColor.black.withAlphaComponent(0.35)
        dim.translatesAutoresizingMaskIntoConstraints = false
        addSubview(dim)

        card.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.92)
        card.layer.cornerRadius = 22
        card.layer.masksToBounds = true
        card.translatesAutoresizingMaskIntoConstraints = false
        addSubview(card)

        titleLabel.text = "Congratulations!"
        titleLabel.font = .systemFont(ofSize: 26, weight: .heavy)
        titleLabel.textAlignment = .center

        subtitleLabel.text = "Picture completed 🎉"
        subtitleLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 0

        backButton.setTitle("Back to Gallery", for: .normal)
        backButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)

        continueButton.setTitle("Continue", for: .normal)
        continueButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        continueButton.tintColor = .systemGreen

        backButton.addTarget(self, action: #selector(didTapBack), for: .touchUpInside)
        continueButton.addTarget(self, action: #selector(didTapContinue), for: .touchUpInside)

        let buttons = UIStackView(arrangedSubviews: [continueButton, backButton])
        buttons.axis = .vertical
        buttons.spacing = 10

        let content = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel, buttons])
        content.axis = .vertical
        content.spacing = 14
        content.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(content)

        NSLayoutConstraint.activate([
            dim.leadingAnchor.constraint(equalTo: leadingAnchor),
            dim.trailingAnchor.constraint(equalTo: trailingAnchor),
            dim.topAnchor.constraint(equalTo: topAnchor),
            dim.bottomAnchor.constraint(equalTo: bottomAnchor),

            card.centerXAnchor.constraint(equalTo: centerXAnchor),
            card.centerYAnchor.constraint(equalTo: centerYAnchor),
            card.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 24),
            card.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -24),
            card.widthAnchor.constraint(lessThanOrEqualToConstant: 340),

            content.topAnchor.constraint(equalTo: card.topAnchor, constant: 20),
            content.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 20),
            content.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -20),
            content.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -20),
        ])

        // чтобы тап по затемнению тоже закрывал (Continue)
        let tap = UITapGestureRecognizer(target: self, action: #selector(didTapContinue))
        dim.addGestureRecognizer(tap)
    }

    func show(animated: Bool = true) {
        isHidden = false
        if animated {
            alpha = 0
            UIView.animate(withDuration: 0.18) { self.alpha = 1 }
            card.transform = CGAffineTransform(scaleX: 0.96, y: 0.96)
            UIView.animate(withDuration: 0.22, delay: 0, usingSpringWithDamping: 0.86, initialSpringVelocity: 0.4) {
                self.card.transform = .identity
            }
        } else {
            alpha = 1
        }
    }

    func hide(animated: Bool = true) {
        if animated {
            UIView.animate(withDuration: 0.15, animations: { self.alpha = 0 }) { _ in
                self.isHidden = true
            }
        } else {
            alpha = 0
            isHidden = true
        }
    }

    @objc private func didTapBack() { onBackToGallery?() }
    @objc private func didTapContinue() { onContinue?() }
}

