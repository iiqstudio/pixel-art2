import SwiftUI

struct ContentView: View {
    var body: some View {
        PixelArtViewControllerWrapper()
            .ignoresSafeArea() // чтобы было во весь экран
    }
}

#Preview {
    ContentView()
}

