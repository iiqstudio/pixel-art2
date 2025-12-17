import UIKit

final class ViewController: UIViewController, UIScrollViewDelegate {

    private let scrollView = UIScrollView()
    private let gridView = TiledGridView()

    private let imageName = "pixel-heart-200"
    
    private var selectedNumber: UInt8 = 4
    private let paletteNumbers: [UInt8] = [1,2,3,4,5,6,7,8,9]
    private let paletteColors: [UInt8: UIColor] = [
        1: .systemRed,
        2: .systemOrange,
        3: .systemYellow,
        4: .systemGreen,
        5: .systemMint,
        6: .systemTeal,
        7: .systemBlue,
        8: .systemIndigo,
        9: .systemPurple
    ]

    private let paletteBar = UIStackView()
    private var paletteButtons: [UIButton] = []


    private var totalForSelected = 0
    private var paintedForSelected = 0
    
    private var isPainting = false
    private var lastPaintedCell: (x: Int, y: Int)? = nil


    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        setupScrollView()
        setupGridView()
        setupPaletteBar()
        convertInBackground()
    }
    

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scrollView.frame = view.bounds
        centerIfNeeded()
    }
    
    private func setupPaletteBar() {
        paletteBar.axis = .horizontal
        paletteBar.alignment = .center
        paletteBar.distribution = .fillEqually
        paletteBar.spacing = 8
        paletteBar.translatesAutoresizingMaskIntoConstraints = false

        // лёгкая подложка, чтобы было видно на любом фоне
        paletteBar.backgroundColor = UIColor.secondarySystemBackground.withAlphaComponent(0.95)
        paletteBar.layer.cornerRadius = 14
        paletteBar.layer.masksToBounds = true
        paletteBar.isLayoutMarginsRelativeArrangement = true
        paletteBar.layoutMargins = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)

        view.addSubview(paletteBar)

        NSLayoutConstraint.activate([
            paletteBar.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 12),
            paletteBar.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -12),
            paletteBar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12),
            paletteBar.heightAnchor.constraint(equalToConstant: 64)
        ])

        paletteButtons = paletteNumbers.map { n in
            let b = makePaletteButton(number: n, color: paletteColors[n] ?? .clear)
            paletteBar.addArrangedSubview(b)
            return b
        }

        updatePaletteSelectionUI()
    }
    
    private func makePaletteButton(number: UInt8, color: UIColor) -> UIButton {
        var config = UIButton.Configuration.plain()
        config.title = "\(number)"
        config.baseForegroundColor = .white
        config.contentInsets = NSDirectionalEdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0)

        let b = UIButton(configuration: config)
        b.tag = Int(number)
        b.backgroundColor = color
        b.layer.cornerRadius = 12
        b.layer.masksToBounds = true
        b.titleLabel?.font = .systemFont(ofSize: 16, weight: .heavy)

        b.addTarget(self, action: #selector(didTapPalette(_:)), for: .touchUpInside)
        return b
    }

    @objc private func didTapPalette(_ sender: UIButton) {
        selectedNumber = UInt8(sender.tag)

        // если нужно — прокинь в gridView (если у тебя есть такое свойство)
        // gridView.selectedNumber = selectedNumber

        updatePaletteSelectionUI()
        recalcProgress() // у тебя уже есть :contentReference[oaicite:2]{index=2}

        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    private func updatePaletteSelectionUI() {
        for b in paletteButtons {
            let isSelected = UInt8(b.tag) == selectedNumber
            b.layer.borderWidth = isSelected ? 3 : 0
            b.layer.borderColor = UIColor.white.withAlphaComponent(0.85).cgColor
            b.transform = isSelected ? CGAffineTransform(scaleX: 1.06, y: 1.06) : .identity
        }
    }


    
    private func recalcProgress() {
        let w = gridView.gridWidth
        let h = gridView.gridHeight
        guard w > 0, h > 0 else { return }

        let selected = selectedNumber

        var total = 0
        var paintedCount = 0

        for i in 0..<(w * h) {
            if gridView.numbers[i] == selected {
                total += 1
                if gridView.painted[i] == selected { paintedCount += 1 }
            }
        }

        totalForSelected = total
        paintedForSelected = paintedCount

        if total > 0 {
            let pct = Int((Double(paintedCount) / Double(total)) * 100.0)
            print("Selected \(selected): \(paintedCount)/\(total) = \(pct)%")
        } else {
            print("Selected \(selected): 0 cells")
        }
    }

    private func bumpProgressIfNeeded(painted: Bool) {
        guard painted else { return }
        paintedForSelected += 1
        if totalForSelected > 0 {
            let pct = Int((Double(paintedForSelected) / Double(totalForSelected)) * 100.0)
            print("Selected \(selectedNumber): \(paintedForSelected)/\(totalForSelected) = \(pct)%")
        }
    }


    private func setupScrollView() {
        scrollView.frame = view.bounds
        scrollView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        scrollView.delegate = self
        scrollView.bouncesZoom = true
        scrollView.maximumZoomScale = 30
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.decelerationRate = .fast
        scrollView.contentInsetAdjustmentBehavior = .never
        view.addSubview(scrollView)
    }
    
    @objc private func handleLongPress(_ gr: UILongPressGestureRecognizer) {
        let p = gr.location(in: gridView)
        let x = Int(floor(p.x))
        let y = Int(floor(p.y))

        func paintAt(_ x: Int, _ y: Int) {
            if let last = lastPaintedCell, last.x == x, last.y == y { return }
            lastPaintedCell = (x, y)

            let ok = gridView.paintIfMatches(x: x, y: y, selected: selectedNumber)
            if ok { bumpProgressIfNeeded(painted: true) }
        }

        switch gr.state {
        case .began:
            isPainting = true
            lastPaintedCell = nil
            scrollView.isScrollEnabled = false
            paintAt(x, y)

        case .changed:
            guard isPainting else { return }
            paintAt(x, y)

        case .ended, .cancelled, .failed:
            isPainting = false
            lastPaintedCell = nil
            scrollView.isScrollEnabled = true

        default:
            break
        }
    }


    private func setupGridView() {
        gridView.backgroundColor = .clear
        gridView.isOpaque = false
        scrollView.addSubview(gridView)

        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        longPress.minimumPressDuration = 0.18
        longPress.allowableMovement = 1000
        longPress.cancelsTouchesInView = false
        gridView.addGestureRecognizer(longPress)

        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        tap.cancelsTouchesInView = false
        gridView.addGestureRecognizer(tap)
    }


    private func applyGridSize(w: Int, h: Int) {
        let size = CGSize(width: w, height: h)

        gridView.frame = CGRect(origin: .zero, size: size)
        scrollView.contentSize = size

        let fitScale = min(view.bounds.width / size.width, view.bounds.height / size.height)
        scrollView.minimumZoomScale = fitScale
        scrollView.zoomScale = fitScale

        gridView.currentZoomScale = scrollView.zoomScale
        centerIfNeeded()
    }

    private func centerIfNeeded() {
        let bounds = scrollView.bounds.size
        let frame = gridView.frame.size

        var insetX: CGFloat = 0
        var insetY: CGFloat = 0

        if frame.width < bounds.width { insetX = (bounds.width - frame.width) * 0.5 }
        if frame.height < bounds.height { insetY = (bounds.height - frame.height) * 0.5 }

        scrollView.contentInset = UIEdgeInsets(top: insetY, left: insetX, bottom: insetY, right: insetX)
    }

    private func convertInBackground() {
        DispatchQueue.global(qos: .userInitiated).async {
            let result = PixelArtConverter.convert(imageName: self.imageName)
            DispatchQueue.main.async {
                guard let result else { return }
                self.gridView.cellSize = 1
                self.gridView.configure(width: result.w, height: result.h, numbers: result.numbers)
                self.recalcProgress()
                self.applyGridSize(w: result.w, h: result.h)
            }
        }
    }

    @objc private func handleTap(_ gr: UITapGestureRecognizer) {
        if isPainting { return }

        let p = gr.location(in: gridView)
        let x = Int(floor(p.x))
        let y = Int(floor(p.y))

        let ok = gridView.paintIfMatches(x: x, y: y, selected: selectedNumber)
        if ok {
            bumpProgressIfNeeded(painted: true)
        }
    }



    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        gridView
    }

    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        gridView.currentZoomScale = scrollView.zoomScale
        centerIfNeeded()
    }
}

