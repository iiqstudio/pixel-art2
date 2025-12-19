import Foundation

struct Level: Identifiable {
    let id: String        // удобно = imageName
    let title: String
    let imageName: String
}

struct Category: Identifiable {
    let id: String
    let title: String
    let levels: [Level]
}

