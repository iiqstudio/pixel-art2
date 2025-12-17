import UIKit

final class ViewController: UIViewController, UIScrollViewDelegate {

    private let scrollView = UIScrollView()
    private let gridView = TiledGridView()

    private let imageName = "pixel-heart-200"

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        setupScrollView()
        setupGridView()
        convertInBackground()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scrollView.frame = view.bounds
        centerIfNeeded()
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

    private func setupGridView() {
        gridView.backgroundColor = .clear
        gridView.isOpaque = false
        scrollView.addSubview(gridView)

        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
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
                self.applyGridSize(w: result.w, h: result.h)
            }
        }
    }

    @objc private func handleTap(_ gr: UITapGestureRecognizer) {
        let p = gr.location(in: gridView)
        let x = Int(floor(p.x))
        let y = Int(floor(p.y))
        gridView.paintCell(x: x, y: y, colorNumber: 4)
    }

    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        gridView
    }

    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        gridView.currentZoomScale = scrollView.zoomScale
        centerIfNeeded()
    }
}

