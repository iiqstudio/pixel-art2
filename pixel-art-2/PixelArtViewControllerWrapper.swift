import SwiftUI
import UIKit

struct PixelArtViewControllerWrapper: UIViewControllerRepresentable {

    func makeUIViewController(context: Context) -> UIViewController {
        ViewController() // наш UIKit-контроллер
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // ничего не нужно
    }
}

