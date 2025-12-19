import Foundation

enum ContentCatalog {
    static let categories: [Category] = [
        Category(
            id: "cristmas",
            title: "❤️ Cristmas",
            levels: [
                Level(id: "gifty", title: "Crismtas gift", imageName: "gifty"),
                Level(id: "heart", title: "Cristmas cap", imageName: "heart"),
                Level(id: "santa", title: "Santa", imageName: "santa"),
                Level(id: "snowman", title: "Snowman", imageName: "snowman"),
            ]
        ),
        Category(
            id: "others",
            title: "🤖 Other",
            levels: [
                Level(id: "clock", title: "Watch", imageName: "clock"),
                Level(id: "rabbit", title: "Rabbit", imageName: "rabbit-100"),
                Level(id: "heart-32", title: "Colored Heart", imageName: "heart-32"),
                Level(id: "alarm-100", title: "Alarmclock", imageName: "alarm-100"),
            ]
        )
    ]
}

