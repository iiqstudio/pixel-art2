import SwiftUI
import UIKit

struct PixelArtViewControllerWrapper: UIViewControllerRepresentable {
    let imageName: String

    func makeUIViewController(context: Context) -> UIViewController {
        ViewController(imageName: imageName)
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}

