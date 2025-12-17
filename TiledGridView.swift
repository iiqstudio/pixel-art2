import UIKit

final class TiledGridView: UIView {

    override class var layerClass: AnyClass { CATiledLayer.self }
    private var tiledLayer: CATiledLayer { layer as! CATiledLayer }

    var gridWidth: Int = 0
    var gridHeight: Int = 0
    var numbers: [UInt8] = []
    var painted: [UInt8] = []

    var cellSize: CGFloat = 1
    var showNumbers: Bool = true

    // ВАЖНО: выставляем из ViewController = scrollView.zoomScale
    var currentZoomScale: CGFloat = 1 {
        didSet {
            // при смене зума можно не дёргать, но так цифры/линии будут обновляться
            setNeedsDisplay()
        }
    }
    var minCellPixelsForText: CGFloat = 18

    private let fillColors: [UInt8: UIColor] = [
        1: UIColor(white: 0.6, alpha: 1),
        2: .blue,
        3: .orange,
        4: UIColor(red: 254/255, green: 0, blue: 0, alpha: 1),
        5: .white,
        9: .black
    ]

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        backgroundColor = .clear
        isOpaque = false

        tiledLayer.levelsOfDetail = 4
        tiledLayer.levelsOfDetailBias = 4
        tiledLayer.tileSize = CGSize(width: 256, height: 256)
        tiledLayer.contentsScale = UIScreen.main.scale
    }

    func configure(width: Int, height: Int, numbers: [UInt8]) {
        self.gridWidth = width
        self.gridHeight = height
        self.numbers = numbers
        self.painted = Array(repeating: 0, count: width * height)
        setNeedsDisplay()
    }

    func paintCell(x: Int, y: Int, colorNumber: UInt8) {
        guard x >= 0, y >= 0, x < gridWidth, y < gridHeight else { return }
        painted[y * gridWidth + x] = colorNumber

        let rect = CGRect(
            x: CGFloat(x) * cellSize,
            y: CGFloat(y) * cellSize,
            width: cellSize,
            height: cellSize
        )
        setNeedsDisplay(rect)
    }

    override func draw(_ rect: CGRect) {
        guard gridWidth > 0,
              gridHeight > 0,
              numbers.count == gridWidth * gridHeight,
              let ctx = UIGraphicsGetCurrentContext()
        else { return }

        ctx.clear(rect)

        // Для сетки лучше оставить антиалиасинг ВКЛ, иначе будут "точки"
        ctx.setAllowsAntialiasing(true)
        ctx.setShouldAntialias(true)

        let x0 = max(Int(floor(rect.minX / cellSize)), 0)
        let y0 = max(Int(floor(rect.minY / cellSize)), 0)
        let x1 = min(Int(ceil(rect.maxX / cellSize)), gridWidth)
        let y1 = min(Int(ceil(rect.maxY / cellSize)), gridHeight)

        let zoom = max(currentZoomScale, 1)

        // 1 экранный пиксель
        let onePixel = 1.0 / (UIScreen.main.scale * zoom)
        ctx.setLineWidth(onePixel)
        ctx.setStrokeColor(UIColor(white: 0, alpha: 0.25).cgColor)

        // 1) закрашенные клетки (если есть)
        for y in y0..<y1 {
            for x in x0..<x1 {
                let idx = y * gridWidth + x
                let paintedNum = painted[idx]
                if paintedNum != 0, let color = fillColors[paintedNum] {
                    let cellRect = CGRect(
                        x: CGFloat(x) * cellSize,
                        y: CGFloat(y) * cellSize,
                        width: cellSize,
                        height: cellSize
                    )
                    ctx.setFillColor(color.cgColor)
                    ctx.fill(cellRect)
                }
            }
        }

        // 2) классическая сетка: обводим каждую клетку
        // Чтобы линии не "двоились", рисуем strokeInset на полпикселя
        let inset = onePixel * 0.5

        for y in y0..<y1 {
            for x in x0..<x1 {
                let r = CGRect(
                    x: CGFloat(x) * cellSize,
                    y: CGFloat(y) * cellSize,
                    width: cellSize,
                    height: cellSize
                ).insetBy(dx: inset, dy: inset)

                ctx.stroke(r)
            }
        }

        // 3) цифры
        let cellPixels = cellSize * zoom * UIScreen.main.scale
        guard showNumbers, cellPixels >= minCellPixelsForText else { return }
        let fontSize = max(min((cellPixels * 0.55) / (UIScreen.main.scale * zoom), 14.0 / zoom), 3.0 / zoom)
        guard cellPixels >= 22 else { return }
        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.monospacedDigitSystemFont(
                ofSize: fontSize,
                weight: .semibold
            ),
            .foregroundColor: UIColor(white: 0, alpha: 0.55)
        ]


        for y in y0..<y1 {
            for x in x0..<x1 {
                let idx = y * gridWidth + x
                if painted[idx] != 0 { continue }

                let num = numbers[idx]
                if num == 0 { continue }

                let cellRect = CGRect(
                    x: CGFloat(x) * cellSize,
                    y: CGFloat(y) * cellSize,
                    width: cellSize,
                    height: cellSize
                )

                let text = "\(num)"
                let s = NSString(string: text)
                let size = s.size(withAttributes: attrs)
                let tr = CGRect(
                    x: cellRect.midX - size.width / 2,
                    y: cellRect.midY - size.height / 2,
                    width: size.width,
                    height: size.height
                )
                s.draw(in: tr, withAttributes: attrs)
            }
        }
    }

}

