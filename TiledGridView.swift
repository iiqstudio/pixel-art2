import UIKit

final class TiledGridView: UIView {

    // MARK: - CATiledLayer
    override class var layerClass: AnyClass { CATiledLayer.self }

    private var tiledLayer: CATiledLayer { layer as! CATiledLayer }

    // MARK: - Data
    var gridWidth: Int = 0
    var gridHeight: Int = 0
    var numbers: [UInt8] = []          // номер цвета на клетку
    var painted: [UInt8] = []          // 0 = не закрашено, иначе номер цвета

    // Размер клетки в "логических" координатах вью (у нас 1 клетка = 1 point)
    // При зуме scrollView увеличит вью, и клетка станет большой на экране.
    var cellSize: CGFloat = 1

    // Включать ли цифры
    var showNumbers: Bool = true

    // Порог, когда цифры можно рисовать (чтобы не убивать FPS)
    var minCellPixelsForText: CGFloat = 18

    // Цвета для заливки по номеру (пример)
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

        // Настройка тайлинга
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

    // MARK: - Drawing
    override func draw(_ rect: CGRect) {
        guard gridWidth > 0, gridHeight > 0, numbers.count == gridWidth * gridHeight else { return }
        guard let ctx = UIGraphicsGetCurrentContext() else { return }

        // Определяем какие клетки попали в rect
        let x0 = max(Int(floor(rect.minX / cellSize)), 0)
        let y0 = max(Int(floor(rect.minY / cellSize)), 0)
        let x1 = min(Int(ceil(rect.maxX / cellSize)), gridWidth)
        let y1 = min(Int(ceil(rect.maxY / cellSize)), gridHeight)

        // Текущая "видимая" величина клетки на экране (в пикселях) — грубо:
        let screenScale = UIScreen.main.scale
        // rect уже в координатах view; реальный размер на экране зависит от zoom, его мы сюда не знаем точно,
        // но можно ориентироваться по текущему transform.a (он ~ zoomScale).
        let approxZoom = self.transform.a
        let cellPixels = cellSize * approxZoom * screenScale

        // Рисуем клетки
        for y in y0..<y1 {
            for x in x0..<x1 {
                let idx = y * gridWidth + x
                let num = numbers[idx]

                let cellRect = CGRect(
                    x: CGFloat(x) * cellSize,
                    y: CGFloat(y) * cellSize,
                    width: cellSize,
                    height: cellSize
                )

                // Заливка если закрашено
                let paintedNum = painted[idx]
                if paintedNum != 0, let c = fillColors[paintedNum] {
                    ctx.setFillColor(c.cgColor)
                    ctx.fill(cellRect)
                }

                // Контур клетки (тонкий)
                ctx.setStrokeColor(UIColor(white: 0, alpha: 0.08).cgColor)
                ctx.setLineWidth(0.5 / (approxZoom > 0 ? approxZoom : 1))
                ctx.stroke(cellRect)

                // Цифры рисуем только когда клетка достаточно крупная
                if showNumbers, num != 0, cellPixels >= minCellPixelsForText, paintedNum == 0 {
                    let text = "\(num)"
                    let attrs: [NSAttributedString.Key: Any] = [
                        .font: UIFont.systemFont(ofSize: min(14, cellPixels * 0.55), weight: .medium),
                        .foregroundColor: UIColor(white: 0, alpha: 0.55)
                    ]
                    let ns = NSString(string: text)
                    let size = ns.size(withAttributes: attrs)
                    let tRect = CGRect(
                        x: cellRect.midX - size.width/2,
                        y: cellRect.midY - size.height/2,
                        width: size.width,
                        height: size.height
                    )
                    ns.draw(in: tRect, withAttributes: attrs)
                }
            }
        }
    }
}

