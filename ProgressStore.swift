import Foundation

enum ProgressStore {

    static func allLevelImageNames() -> [String] {
        Array(
            Set(
                ContentCatalog.categories
                    .flatMap { $0.levels }
                    .map { $0.imageName }
            )
        ).sorted()
    }

    static func resetAllProgress() {
        let ud = UserDefaults.standard
        for name in allLevelImageNames() {
            ud.removeObject(forKey: "painted_v1_\(name)")
            ud.removeObject(forKey: "selected_v1_\(name)")
        }
    }
}

