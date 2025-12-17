import UIKit

final class ViewController: UIViewController, UIScrollViewDelegate {

    private let scrollView = UIScrollView()

    private let contentView = UIView()      // то, что зумим
    private let previewImageView = UIImageView()
    private let gridView = TiledGridView()

    private let imageName = "pixel-heart-200"

    // когда зум больше этого — показываем сетку
    private let gridThreshold: CGFloat = 6.0

    // состояние
    private var gridReady = false
    private var gridW = 0
    private var gridH = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        setupScrollView()
        setupPreview()
        setupGridView()
        layoutInitial()

        // Конвертация PNG -> grid в фоне (важно: без фризов)
        convertInBackground()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scrollView.frame = view.bounds
        scrollView.contentInsetAdjustmentBehavior = .never
        centerContentIfNeeded()
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
        view.addSubview(scrollView)
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.addSubview(contentView)
    }

    private func setupPreview() {
        guard let img = UIImage(named: imageName) else {
            assertionFailure("Не найден ассет \(imageName)")
            return
        }

        previewImageView.image = img
        previewImageView.contentMode = .scaleToFill

        // пиксели без мыла
        previewImageView.layer.magnificationFilter = .nearest
        previewImageView.layer.minificationFilter = .nearest

        contentView.addSubview(previewImageView)
    }

    private func setupGridView() {
        contentView.backgroundColor = .clear
        gridView.backgroundColor = .clear

        gridView.isHidden = true
        gridView.alpha = 1

        contentView.addSubview(gridView)

        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        tap.cancelsTouchesInView = false
        contentView.addGestureRecognizer(tap)
    }


    private func layoutInitial() {
        let size = CGSize(width: 200, height: 200)

        contentView.frame = CGRect(origin: .zero, size: size)
        contentView.frame.origin = .zero
        previewImageView.frame = contentView.bounds
        gridView.frame = contentView.bounds

        scrollView.contentSize = size

        // fit в экран
        let fitScale = min(view.bounds.width / size.width, view.bounds.height / size.height)
        scrollView.minimumZoomScale = fitScale
        scrollView.zoomScale = fitScale

        updateLOD()
    }

    private func centerContentIfNeeded() {
        let boundsSize = scrollView.bounds.size
        let frameSize = contentView.frame.size   // важно: именно frame, а не contentSize

        var center = CGPoint(x: frameSize.width * 0.5,
                             y: frameSize.height * 0.5)

        if frameSize.width < boundsSize.width {
            center.x = boundsSize.width * 0.5
        }
        if frameSize.height < boundsSize.height {
            center.y = boundsSize.height * 0.5
        }

        contentView.center = center
    }




    // MARK: - LOD (preview <-> grid)
    private func updateLOD() {
        let showGrid = gridReady && (scrollView.zoomScale >= gridThreshold)

        previewImageView.isHidden = false
        previewImageView.alpha = 1

        if showGrid {
            gridView.isHidden = false
            gridView.alpha = 1
            gridView.showNumbers = true
        } else {
            gridView.alpha = 0
            gridView.isHidden = true
            gridView.showNumbers = false
        }
    }
    
    private func makeGrayscalePreview(w: Int, h: Int, numbers: [UInt8]) -> UIImage? {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bytesPerPixel = 4
        let bytesPerRow = w * bytesPerPixel
        var data = [UInt8](repeating: 0, count: h * bytesPerRow)

        func putPixel(x: Int, y: Int, r: UInt8, g: UInt8, b: UInt8, a: UInt8) {
            let i = y * bytesPerRow + x * bytesPerPixel
            data[i] = r
            data[i + 1] = g
            data[i + 2] = b
            data[i + 3] = a
        }

        for y in 0..<h {
            for x in 0..<w {
                let n = numbers[y * w + x]

                // прозрачные пиксели (если есть)
                if n == 0 {
                    putPixel(x: x, y: y, r: 0, g: 0, b: 0, a: 0)
                    continue
                }

                // одинаковый светлый тон для всех клеток
                // (можно сделать разные оттенки по номеру — но пока так)
                let v: UInt8 = 235
                putPixel(x: x, y: y, r: v, g: v, b: v, a: 255)
            }
        }

        guard let ctx = CGContext(
            data: &data,
            width: w,
            height: h,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ), let cg = ctx.makeImage() else { return nil }

        return UIImage(cgImage: cg, scale: 1, orientation: .up)
    }



    

    // MARK: - Background convert
    private func convertInBackground() {
        DispatchQueue.global(qos: .userInitiated).async {
            let result = PixelArtConverter.convert(imageName: self.imageName)
            DispatchQueue.main.async {
                guard let result else { return }
                self.gridW = result.w
                self.gridH = result.h
                self.gridReady = true

                // Важно: если картинка не 200x200, подстроим размеры контента под неё
                let size = CGSize(width: result.w, height: result.h)
                self.contentView.bounds = CGRect(origin: .zero, size: size)
                self.contentView.frame.size = size
                self.previewImageView.frame = self.contentView.bounds
                self.gridView.frame = self.contentView.bounds

                self.scrollView.contentSize = size

                self.gridView.cellSize = 1
                self.gridView.configure(width: result.w, height: result.h, numbers: result.numbers)
                if let preview = self.makeGrayscalePreview(w: result.w, h: result.h, numbers: result.numbers) {
                    self.previewImageView.image = preview
                    self.previewImageView.layer.magnificationFilter = .nearest
                    self.previewImageView.layer.minificationFilter = .nearest
                }

                self.gridView.setNeedsDisplay()


                // пересчитать fit scale под реальный размер
                let fitScale = min(self.view.bounds.width / size.width, self.view.bounds.height / size.height)
                self.scrollView.minimumZoomScale = fitScale
                if self.scrollView.zoomScale < fitScale {
                    self.scrollView.zoomScale = fitScale
                }

                self.updateLOD()
                self.centerContentIfNeeded()
            }
        }
    }

    // MARK: - Tap -> paint
    @objc private func handleTap(_ gr: UITapGestureRecognizer) {
        guard gridReady else { return }

        // координаты тапа в contentView (логические)
        let p = gr.location(in: contentView)

        let x = Int(floor(p.x))
        let y = Int(floor(p.y))

        // Для теста красим красным (#4)
        gridView.paintCell(x: x, y: y, colorNumber: 4)
    }

    // MARK: - UIScrollViewDelegate
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        contentView
    }

    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        centerContentIfNeeded()
        gridView.currentZoomScale = scrollView.zoomScale
        updateLOD()
    }
}

