import SwiftUI

struct GalleryView: View {
    private let categories = ContentCatalog.categories

    var body: some View {
        NavigationStack {
            List {
                ForEach(categories) { cat in
                    Section(cat.title) {
                        ForEach(cat.levels) { level in
                            NavigationLink {
                                PixelArtViewControllerWrapper(imageName: level.imageName)
                                    .ignoresSafeArea()
                            } label: {
                                HStack(spacing: 12) {
                                    Image(level.imageName)
                                        .resizable()
                                        .interpolation(.none)
                                        .frame(width: 44, height: 44)
                                        .cornerRadius(8)
                                    Text(level.title)
                                        .font(.headline)
                                }
                                .padding(.vertical, 6)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Gallery")
            .toolbar {
                NavigationLink {
                    SettingsView()
                } label: {
                    Image(systemName: "gearshape")
                }
            }

        }
    }
}

