import UIKit

final class ViewController: UIViewController, UIScrollViewDelegate {

    private let scrollView = UIScrollView()
    private let gridView = TiledGridView()

    private var imageName: String
    init(imageName: String) {
        self.imageName = imageName
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }
    private let brushOverlay = BrushOverlayView()
    private let brushRadiusCells: Int = 1   // 0 = 1x1, 1 = 3x3, 2 = 5x5
    private let paintHaptic = UIImpactFeedbackGenerator(style: .light)
    private var lastHapticTime: CFTimeInterval = 0
    private let hapticInterval: CFTimeInterval = 0.07
    private let progressHUD = ProgressHUDView()
    private var saveKeyPainted: String { "painted_v1_\(imageName)" }
    private var saveKeySelected: String { "selected_v1_\(imageName)" }
    private let paletteScroll = UIScrollView()
    private let particlesView = ParticleBurstView()
    private var lastParticlesTime: CFTimeInterval = 0
    private let particlesInterval: CFTimeInterval = 0.06
    private let paletteNumbers: [UInt8] = Array(1...29)
    private let paletteColors: [UInt8: UIColor] = GamePalette.uiColors
    private var selectedNumber: UInt8 = 1 // или что хочешь дефолтом
    private var hapticsEnabled = true
    private var particlesEnabled = true
    private let paletteBar = UIStackView()
    private var paletteButtons: [UIButton] = []
    private var totalForSelected = 0
    private var paintedForSelected = 0
    private var isPainting = false
    private var lastPaintedCell: (x: Int, y: Int)? = nil
    private var pendingSaveWork: DispatchWorkItem?
    private let saveDebounce: TimeInterval = 0.5
    private let congratsOverlay = CongratulationsOverlayView()
    private var totalPaintable = 0      // сколько клеток нужно закрасить (numbers != 0)
    private var paintedTotal = 0        // сколько уже закрашено (painted != 0)
    private var didShowCongrats = false // чтобы показать модалку 1 раз

    private func recalcOverallProgress() {
    let w = gridView.gridWidth
    let h = gridView.gridHeight
    guard w > 0, h > 0 else { return }

    var total = 0
    var painted = 0

    for i in 0..<(w * h) {
        if gridView.numbers[i] != 0 { total += 1 }
        if gridView.painted[i] != 0 { painted += 1 }
    }

        totalPaintable = total
        paintedTotal = painted
    }

    private func maybeShowCongratulations() {
    guard !didShowCongrats else { return }
    guard totalPaintable > 0 else { return }                 // важно: пока не загрузили картинку — не показывать
    guard paintedTotal >= totalPaintable else { return }      // 100%

    didShowCongrats = true
    view.bringSubviewToFront(congratsOverlay)
    congratsOverlay.show()

        if hapticsEnabled {
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        }
    }



    private func setupProgressHUD() {
        progressHUD.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(progressHUD)

        NSLayoutConstraint.activate([
            progressHUD.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            progressHUD.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 12),
            progressHUD.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -12),
            progressHUD.heightAnchor.constraint(equalToConstant: 78)
        ])
    }


    private func scheduleSaveProgress() {
        pendingSaveWork?.cancel()
        let work = DispatchWorkItem { [weak self] in
            self?.saveProgressNow()
        }
        pendingSaveWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + saveDebounce, execute: work)
    }

    private func saveProgressNow() {
        guard gridView.gridWidth > 0, gridView.gridHeight > 0 else { return }

        // painted[] -> Data
        let data = Data(gridView.painted)

        UserDefaults.standard.set(data, forKey: saveKeyPainted)
        UserDefaults.standard.set(Int(selectedNumber), forKey: saveKeySelected)
    }

    private func setupCongratsOverlay() {
    congratsOverlay.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(congratsOverlay)

    NSLayoutConstraint.activate([
        congratsOverlay.leadingAnchor.constraint(equalTo: view.leadingAnchor),
        congratsOverlay.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        congratsOverlay.topAnchor.constraint(equalTo: view.topAnchor),
        congratsOverlay.bottomAnchor.constraint(equalTo: view.bottomAnchor)
    ])

    // Кнопки
    congratsOverlay.onContinue = { [weak self] in
        self?.congratsOverlay.hide()
    }

    congratsOverlay.onBackToGallery = { [weak self] in
        self?.navigationController?.popViewController(animated: true)
    }
}


    
    private func paintBrush(atX x: Int, y: Int) -> Int {
        let r = brushRadiusCells
        var newlyPainted = 0

        for yy in (y - r)...(y + r) {
            for xx in (x - r)...(x + r) {
                // paintIfMatches должен возвращать true только если закрасили (у тебя так сейчас, если клетка новая)
                let ok = gridView.paintIfMatches(x: xx, y: yy, selected: selectedNumber)
                if ok { newlyPainted += 1 }
            }
        }
        return newlyPainted
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        
        setupProgressHUD()
        setupScrollView()
        setupGridView()
        applySettings()
        setupPaletteBar()
        convertInBackground()
        setupCongratsOverlay()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        applySettings()
    }

    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scrollView.frame = view.bounds
        centerIfNeeded()
    }

    private func selectColor(_ n: UInt8, animatedScroll: Bool) {
    selectedNumber = n
    gridView.selectedNumber = n

    let c = paletteColors[n] ?? .white
    brushOverlay.strokeColor = c
    brushOverlay.brushColor = c

    updatePaletteSelectionUI()
    recalcProgress()

    if animatedScroll, let btn = paletteButtons.first(where: { UInt8($0.tag) == n }) {
        paletteScroll.scrollRectToVisible(btn.frame.insetBy(dx: -12, dy: -12), animated: true)
    }
    }

    private func findNextIncompleteColor(after current: UInt8) -> UInt8? {
    // делаем циклический обход 1...29
    let all = paletteNumbers
    guard !all.isEmpty else { return nil }

    // стартуем со следующего после current
    let startIndex = (all.firstIndex(of: current) ?? 0) + 1

    for offset in 0..<all.count {
        let idx = (startIndex + offset) % all.count
        let n = all[idx]

        // есть ли вообще клетки этого номера?
        var total = 0
        var painted = 0

        let w = gridView.gridWidth
        let h = gridView.gridHeight
        guard w > 0, h > 0 else { return nil }

        for i in 0..<(w * h) {
            if gridView.numbers[i] == n {
                total += 1
                if gridView.painted[i] == n { painted += 1 }
            }
        }

        if total > 0 && painted < total {
            return n
        }
    }

    return nil
    }

    private func autoAdvanceIfCompletedSelected() {
    guard totalForSelected > 0 else { return }
    guard paintedForSelected >= totalForSelected else { return }

    // текущий цвет завершён → ищем следующий незавершённый
    if let next = findNextIncompleteColor(after: selectedNumber) {
        selectColor(next, animatedScroll: true)

        // лёгкий хаптик “переключение”
        if hapticsEnabled {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }
    }
    }



    
    private func refreshHUD() {
        guard !progressHUD.isHidden else { return }
        let barColor = paletteColors[selectedNumber] ?? .systemBlue
        progressHUD.set(
            colorNumber: selectedNumber,
            painted: paintedForSelected,
            total: totalForSelected,
            barColor: barColor
        )
    }

    
    private func setupPaletteBar() {
        // Контейнер (фон + скругление)
        paletteBar.axis = .horizontal
        paletteBar.alignment = .center
        paletteBar.distribution = .fill
        paletteBar.spacing = 8
        paletteBar.translatesAutoresizingMaskIntoConstraints = false
        paletteBar.isLayoutMarginsRelativeArrangement = true
        paletteBar.layoutMargins = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)

        paletteScroll.translatesAutoresizingMaskIntoConstraints = false
        paletteScroll.showsHorizontalScrollIndicator = false
        paletteScroll.alwaysBounceHorizontal = true
        paletteScroll.backgroundColor = UIColor.secondarySystemBackground.withAlphaComponent(0.95)
        paletteScroll.layer.cornerRadius = 14
        paletteScroll.layer.masksToBounds = true

        view.addSubview(paletteScroll)

        NSLayoutConstraint.activate([
            paletteScroll.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 12),
            paletteScroll.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -12),
            paletteScroll.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12),
            paletteScroll.heightAnchor.constraint(equalToConstant: 64)
        ])

        paletteScroll.addSubview(paletteBar)

        // ВАЖНО: фиксируем stack внутри scroll через contentLayoutGuide/frameLayoutGuide
        NSLayoutConstraint.activate([
            paletteBar.leadingAnchor.constraint(equalTo: paletteScroll.contentLayoutGuide.leadingAnchor),
            paletteBar.trailingAnchor.constraint(equalTo: paletteScroll.contentLayoutGuide.trailingAnchor),
            paletteBar.topAnchor.constraint(equalTo: paletteScroll.contentLayoutGuide.topAnchor),
            paletteBar.bottomAnchor.constraint(equalTo: paletteScroll.contentLayoutGuide.bottomAnchor),

            // высота stack = высота scroll (чтобы центрировалось по вертикали)
            paletteBar.heightAnchor.constraint(equalTo: paletteScroll.frameLayoutGuide.heightAnchor)
        ])

        paletteButtons = paletteNumbers.map { n in
            let b = makePaletteButton(number: n, color: paletteColors[n] ?? .clear)

            // фикс ширины, чтобы не скукоживалось
            b.translatesAutoresizingMaskIntoConstraints = false
            b.widthAnchor.constraint(equalToConstant: 44).isActive = true
            b.heightAnchor.constraint(equalToConstant: 44).isActive = true

            paletteBar.addArrangedSubview(b)
            return b
        }

        updatePaletteSelectionUI()
    }
    
    private func applySettings() {
        let ud = UserDefaults.standard

        // отображение (это уже есть в TiledGridView)
        let showGrid = ud.object(forKey: SettingsKeys.showGrid) as? Bool ?? true
        let showNumbers = ud.object(forKey: SettingsKeys.showNumbers) as? Bool ?? true
        gridView.showGrid = showGrid
        gridView.showNumbers = showNumbers

        // эффекты (флаги внутри VC)
        hapticsEnabled = ud.object(forKey: SettingsKeys.hapticsEnabled) as? Bool ?? true
        particlesEnabled = ud.object(forKey: SettingsKeys.particlesEnabled) as? Bool ?? true

        gridView.setNeedsDisplay()
        let showHUD = ud.object(forKey: SettingsKeys.showHUD) as? Bool ?? true
        progressHUD.isHidden = !showHUD
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
        gridView.selectedNumber = selectedNumber
        brushOverlay.strokeColor = paletteColors[selectedNumber] ?? .white
        brushOverlay.brushColor = paletteColors[selectedNumber] ?? .systemGreen
        updatePaletteSelectionUI()
        recalcProgress() // у тебя уже есть :contentReference[oaicite:2]{index=2}
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        
        if let idx = paletteButtons.firstIndex(of: sender) {
            let btn = paletteButtons[idx]
            paletteScroll.scrollRectToVisible(btn.frame.insetBy(dx: -12, dy: -12), animated: true)
        }

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
        refreshHUD()
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

            let added = paintBrush(atX: x, y: y)
            guard added > 0 else { return }

            paintedForSelected += added
            paintedTotal += added
            maybeShowCongratulations()

            refreshHUD()
            autoAdvanceIfCompletedSelected()
            scheduleSaveProgress()

            let now = CACurrentMediaTime()

            // ✅ Хаптик (троттлим, чтобы не “пулемётило”)
            if hapticsEnabled, now - lastHapticTime > hapticInterval {
                paintHaptic.impactOccurred(intensity: 0.45)
                paintHaptic.prepare()
                lastHapticTime = now
            }

            // ✅ Пузырьки (троттлим)
            if particlesEnabled, now - lastParticlesTime > particlesInterval {
                let color = paletteColors[selectedNumber] ?? .white
                let pt = CGPoint(x: CGFloat(x) + 0.5, y: CGFloat(y) + 0.5)
                particlesView.burst(at: pt, color: color)
                lastParticlesTime = now
            }


            // ✅ Прогресс (пока через print)
            if totalForSelected > 0 {
                let pct = Int((Double(paintedForSelected) / Double(totalForSelected)) * 100.0)
                print("Selected \(selectedNumber): \(paintedForSelected)/\(totalForSelected) = \(pct)%")
            }
        }



        switch gr.state {
        case .began:
            isPainting = true
            lastPaintedCell = nil
            scrollView.isScrollEnabled = false
            paintAt(x, y)
            let p = gr.location(in: gridView)
            brushOverlay.touchPoint = p


        case .changed:
            guard isPainting else { return }
            paintAt(x, y)
            let p = gr.location(in: gridView)
            brushOverlay.touchPoint = p


        case .ended, .cancelled, .failed:
            isPainting = false
            lastPaintedCell = nil
            brushOverlay.hide()
            scrollView.isScrollEnabled = true

        default:
            break
        }
    }


    private func setupGridView() {
        brushOverlay.brushColor = paletteColors[selectedNumber] ?? .systemGreen
        gridView.selectedNumber = selectedNumber
        gridView.backgroundColor = .clear
        gridView.isOpaque = false
        scrollView.addSubview(gridView)
        
        brushOverlay.frame = gridView.bounds
        brushOverlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        gridView.addSubview(brushOverlay)
        particlesView.frame = gridView.bounds
        particlesView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        gridView.addSubview(particlesView)

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
                self.loadProgressIfAny()
                self.recalcOverallProgress()
                self.maybeShowCongratulations()
                self.recalcProgress()
                self.applyGridSize(w: result.w, h: result.h)
            }
        }
    }
    
    private func loadProgressIfAny() {
        let w = gridView.gridWidth
        let h = gridView.gridHeight
        guard w > 0, h > 0 else { return }

        if let data = UserDefaults.standard.data(forKey: saveKeyPainted) {
            let arr = [UInt8](data)
            if arr.count == w * h {
                gridView.applyPainted(arr)
            }
        }

        let savedSelected = UserDefaults.standard.integer(forKey: saveKeySelected)
        if savedSelected > 0 && savedSelected <= 255 {
            selectedNumber = UInt8(savedSelected)
            gridView.selectedNumber = selectedNumber
            updatePaletteSelectionUI()
        }

        recalcProgress()
    }


    @objc private func handleTap(_ gr: UITapGestureRecognizer) {
        let p = gr.location(in: gridView)
        brushOverlay.touchPoint = p
        if isPainting { return }

        let x = Int(floor(p.x))
        let y = Int(floor(p.y))

        let added = paintBrush(atX: x, y: y)
        if added > 0 {
            paintedForSelected += added
            paintedTotal += added
            maybeShowCongratulations()
            refreshHUD()
            autoAdvanceIfCompletedSelected()
            scheduleSaveProgress()
            // ✅ Хаптик (тап — можно без троттла)
            if hapticsEnabled {
                paintHaptic.impactOccurred(intensity: 0.55)
                paintHaptic.prepare()
            }
            // ✅ Пузырьки
            if particlesEnabled {
                let color = paletteColors[selectedNumber] ?? .white
                particlesView.burst(at: p, color: color)
            }


            // ✅ Прогресс (пока через print)
            if totalForSelected > 0 {
                let pct = Int((Double(paintedForSelected) / Double(totalForSelected)) * 100.0)
                print("Selected \(selectedNumber): \(paintedForSelected)/\(totalForSelected) = \(pct)%")
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            self.brushOverlay.hide()
        }
    }




    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        gridView
    }

    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        gridView.currentZoomScale = scrollView.zoomScale
        centerIfNeeded()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        pendingSaveWork?.cancel()
        saveProgressNow()
    }
}

