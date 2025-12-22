import UIKit

final class TiledGridView: UIView {

    override class var layerClass: AnyClass { CATiledLayer.self }
    private var tiledLayer: CATiledLayer { layer as! CATiledLayer }
    private let highlightFillColor = UIColor(white: 0.60, alpha: 0.55)

    var gridWidth: Int = 0
    var gridHeight: Int = 0
    var numbers: [UInt8] = []
    var painted: [UInt8] = []

    var cellSize: CGFloat = 1
    var showNumbers: Bool = true
    var showGrid: Bool = true

    var currentZoomScale: CGFloat = 1 {
        didSet { setNeedsDisplay() }
    }
    
    var selectedNumber: UInt8 = 0 {
        didSet {
            setNeedsDisplay()
        }
    }

    var minCellPixelsForText: CGFloat = 26

    var baseFillColor: UIColor = UIColor(white: 0.92, alpha: 1)

    private let fillColors: [UInt8: UIColor] = GamePalette.uiColors



    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    func applyPainted(_ newPainted: [UInt8]) {
        guard newPainted.count == gridWidth * gridHeight else { return }
        painted = newPainted
        setNeedsDisplay()
    }

    func resetPainted() {
        painted = Array(repeating: 0, count: gridWidth * gridHeight)
        setNeedsDisplay()
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
        let idx = y * gridWidth + x
        guard numbers.indices.contains(idx), numbers[idx] != 0 else { return }

        painted[idx] = colorNumber

        let rect = CGRect(
            x: CGFloat(x) * cellSize,
            y: CGFloat(y) * cellSize,
            width: cellSize,
            height: cellSize
        )
        setNeedsDisplay(rect)
    }
    
    func numberAt(x: Int, y: Int) -> UInt8 {
        guard x >= 0, y >= 0, x < gridWidth, y < gridHeight else { return 0 }
        return numbers[y * gridWidth + x]
    }

    func paintIfMatches(x: Int, y: Int, selected: UInt8) -> Bool {
        guard x >= 0, y >= 0, x < gridWidth, y < gridHeight else { return false }
        let idx = y * gridWidth + x
        let n = numbers[idx]
        guard n != 0 else { return false }
        guard n == selected else { return false }
        if painted[idx] == selected { return true }

        painted[idx] = selected
        let rect = CGRect(x: CGFloat(x) * cellSize, y: CGFloat(y) * cellSize, width: cellSize, height: cellSize)
        setNeedsDisplay(rect)
        return true
    }


    override func draw(_ rect: CGRect) {
        guard gridWidth > 0,
              gridHeight > 0,
              numbers.count == gridWidth * gridHeight,
              let ctx = UIGraphicsGetCurrentContext()
        else { return }

        ctx.clear(rect)

        ctx.setAllowsAntialiasing(true)
        ctx.setShouldAntialias(true)

        let x0 = max(Int(floor(rect.minX / cellSize)), 0)
        let y0 = max(Int(floor(rect.minY / cellSize)), 0)
        let x1 = min(Int(ceil(rect.maxX / cellSize)), gridWidth)
        let y1 = min(Int(ceil(rect.maxY / cellSize)), gridHeight)

        let zoom = max(currentZoomScale, 1)
        let cellPixels = cellSize * zoom * UIScreen.main.scale
        let onePixel = 1.0 / (UIScreen.main.scale * zoom)

        if showGrid {
            ctx.setLineWidth(onePixel)
            ctx.setStrokeColor(UIColor(white: 0, alpha: 0.22).cgColor)
        }

        let inset = onePixel * 0.5

        for y in y0..<y1 {
            for x in x0..<x1 {
                let idx = y * gridWidth + x
                let num = numbers[idx]
                if num == 0 { continue }

                let cellRect = CGRect(
                    x: CGFloat(x) * cellSize,
                    y: CGFloat(y) * cellSize,
                    width: cellSize,
                    height: cellSize
                )

                let p = painted[idx]

                if p != 0, let c = fillColors[p] {
                    // уже закрашено — рисуем цвет
                    ctx.setFillColor(c.cgColor)
                    ctx.fill(cellRect)
                } else {
                    // фон
                    ctx.setFillColor(baseFillColor.cgColor)
                    ctx.fill(cellRect)

                    // 👇 СЕРАЯ ПОДСВЕТКА нужных клеток
                    if num == selectedNumber {
                        ctx.setFillColor(highlightFillColor.cgColor)
                        ctx.fill(cellRect)
                    }
                }


                if showGrid {
                    ctx.stroke(cellRect.insetBy(dx: inset, dy: inset))
                }
            }
        }

        guard showNumbers, cellPixels >= minCellPixelsForText else { return }

        let fontSize = min(max((cellPixels * 0.55) / (UIScreen.main.scale * zoom), 6.0 / zoom), 14.0 / zoom)
        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.monospacedDigitSystemFont(ofSize: fontSize, weight: .semibold),
            .foregroundColor: UIColor(white: 0, alpha: 0.55)
        ]

        for y in y0..<y1 {
            for x in x0..<x1 {
                let idx = y * gridWidth + x
                if numbers[idx] == 0 { continue }
                if painted[idx] != 0 { continue }

                let num = numbers[idx]
                let text = "\(num)"
                let s = NSString(string: text)
                let size = s.size(withAttributes: attrs)

                let cellRect = CGRect(
                    x: CGFloat(x) * cellSize,
                    y: CGFloat(y) * cellSize,
                    width: cellSize,
                    height: cellSize
                )

                let r = CGRect(
                    x: cellRect.midX - size.width / 2,
                    y: cellRect.midY - size.height / 2,
                    width: size.width,
                    height: size.height
                )

                s.draw(in: r, withAttributes: attrs)
            }
        }
    }
}

