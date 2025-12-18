import UIKit

final class ParticleBurstView: UIView {

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        backgroundColor = .clear
        isOpaque = false
    }

    required init?(coder: NSCoder) { fatalError() }

    func burst(at point: CGPoint, color: UIColor) {
        let emitter = CAEmitterLayer()
        emitter.emitterPosition = point
        emitter.emitterShape = .point
        emitter.emitterSize = .zero

        let cell = CAEmitterCell()
        cell.contents = ParticleBurstView.makeDotImage().cgImage

        // сколько частиц
        cell.birthRate = 120

        // как далеко улетают: velocity * lifetime ≈ 4
        cell.lifetime = 0.22
        cell.lifetimeRange = 0.08

        cell.velocity = 18
        cell.velocityRange = 6
        cell.emissionRange = .pi * 2

        // размер: примерно 0.5 клетки
        cell.scale = 0.025
        cell.scaleRange = 0.01

        // быстро исчезают
        cell.alphaSpeed = -2.2

        // вращение можно почти убрать
        cell.spinRange = 0.5

        cell.color = color.withAlphaComponent(0.9).cgColor


        emitter.emitterCells = [cell]
        layer.addSublayer(emitter)

        // быстро “погасить” эмиссию, чтобы это был именно burst, а не фонтан
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.03) {
            emitter.birthRate = 0
        }

        // убрать слой после окончания жизни частиц
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            emitter.removeFromSuperlayer()
        }
    }

    private static func makeDotImage() -> UIImage {
        let size = CGSize(width: 18, height: 18)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            let r = CGRect(x: 0, y: 0, width: size.width, height: size.height)
            ctx.cgContext.setFillColor(UIColor.white.cgColor)
            ctx.cgContext.fillEllipse(in: r)
        }
    }
}

