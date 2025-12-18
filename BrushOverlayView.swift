import UIKit

final class BrushOverlayView: UIView {
    var brushColor: UIColor = .systemGreen {
        didSet { setNeedsDisplay() }
    }

    var fillAlpha: CGFloat = 0.16
    var strokeAlpha: CGFloat = 0.85
    var innerGlowAlpha: CGFloat = 0.35

    var strokeWidth: CGFloat = 2.0


    var touchPoint: CGPoint? {
        didSet { setNeedsDisplay() }
    }
    
    var strokeColor: UIColor = UIColor(white: 0.2, alpha: 0.6) {
        didSet { setNeedsDisplay() }
    }

    var radius: CGFloat = 3

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        backgroundColor = .clear
        isOpaque = false
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    override func draw(_ rect: CGRect) {
        guard let p = touchPoint, let ctx = UIGraphicsGetCurrentContext() else { return }

        ctx.clear(rect)

        let circleRect = CGRect(
            x: p.x - radius,
            y: p.y - radius,
            width: radius * 2,
            height: radius * 2
        )

        ctx.saveGState()
        ctx.setAllowsAntialiasing(true)
        ctx.setShouldAntialias(true)

        // 1) Fill — цвет кисти, очень прозрачно
        ctx.setFillColor(brushColor.withAlphaComponent(fillAlpha).cgColor)
        ctx.fillEllipse(in: circleRect)

        // 2) Inner glow — тонкое белое кольцо внутри
        let glowInset = strokeWidth * 0.9
        let innerRect = circleRect.insetBy(dx: glowInset, dy: glowInset)
        ctx.setStrokeColor(UIColor.white.withAlphaComponent(innerGlowAlpha).cgColor)
        ctx.setLineWidth(max(1.0, strokeWidth * 0.55))
        ctx.strokeEllipse(in: innerRect)

        // 3) Outer stroke — рамка цветом кисти
        ctx.setStrokeColor(brushColor.withAlphaComponent(strokeAlpha).cgColor)
        ctx.setLineWidth(strokeWidth)
        ctx.strokeEllipse(in: circleRect)

        ctx.restoreGState()
    }



    func hide() {
        touchPoint = nil
    }
}

