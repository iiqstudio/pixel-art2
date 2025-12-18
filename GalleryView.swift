import SwiftUI

struct GalleryView: View {
    private let items: [(title: String, name: String)] = [
        ("Heart", "pixel-heart-200"),
        ("Helmet", "helmet100")
    ]

    var body: some View {
        NavigationStack {
            List(items, id: \.name) { item in
                NavigationLink {
                    PixelArtViewControllerWrapper(imageName: item.name)
                        .ignoresSafeArea()
                } label: {
                    HStack(spacing: 12) {
                        Image(item.name)
                            .resizable()
                            .interpolation(.none)
                            .frame(width: 44, height: 44)
                            .cornerRadius(8)

                        Text(item.title)
                            .font(.headline)
                    }
                    .padding(.vertical, 6)
                }
            }
            .navigationTitle("Gallery")
        }
    }
}
