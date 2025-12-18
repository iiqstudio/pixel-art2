import UIKit

enum GamePalette {

    // MARK: - UI colors (кнопки палитры + заливка)

    static let uiColors: [UInt8: UIColor] = [
        1:  UIColor(hex: 0x000000), // Черный
        2:  UIColor(hex: 0x45FF2A), // Ярко-зеленый
        3:  UIColor(hex: 0xE51D2E), // Красный
        4:  UIColor(hex: 0xE87D8B), // Розовая пастель
        5:  UIColor(hex: 0xE31B23), // Алый
        6:  UIColor(hex: 0xF1DAF1), // Бледно-лиловый
        7:  UIColor(hex: 0xE7B5F0), // Светло-сиреневый
        8:  UIColor(hex: 0xE491E9), // Розово-пурпурный
        9:  UIColor(hex: 0xEDC7F0), // Нежно-розовый
        10: UIColor(hex: 0xF2F2F2), // Почти белый
        11: UIColor(hex: 0xBCF1F2), // Аквамарин
        12: UIColor(hex: 0x57B9EB), // Небесно-голубой
        13: UIColor(hex: 0xE36DDE), // Орхидея
        14: UIColor(hex: 0xC25227), // Терракотовый
        15: UIColor(hex: 0xBDB03D), // Оливково-золотой
        16: UIColor(hex: 0x5EB838), // Травяной
        17: UIColor(hex: 0xC72A1D), // Темно-красный
        18: UIColor(hex: 0xE88C31), // Оранжевый
        19: UIColor(hex: 0xEFFF46), // Лимонный
        20: UIColor(hex: 0x53B79F), // Изумрудная мята
        21: UIColor(hex: 0x313DBB), // Королевский синий
        22: UIColor(hex: 0x8E22B9), // Фиолетовый
        23: UIColor(hex: 0xAC2BB3), // Пурпурный
        24: UIColor(hex: 0x75147C), // Темно-сливовый
        25: UIColor(hex: 0xE34135), // Кораллово-красный
        26: UIColor(hex: 0x66E9F0), // Бирюзовый
        27: UIColor(hex: 0x4567EA), // Васильковый
        28: UIColor(hex: 0xBD3AE5), // Насыщенный сиреневый
        29: UIColor(hex: 0xE030E3)  // Фуксия
    ]

    // MARK: - RGB map (конвертация PNG -> numbers[])

    static let rgbMap: [RGBColor] = [
        .init(r: 0,   g: 0,   b: 0,   number: 1),
        .init(r: 69,  g: 255, b: 42,  number: 2),
        .init(r: 229, g: 29,  b: 46,  number: 3),
        .init(r: 232, g: 125, b: 139, number: 4),
        .init(r: 227, g: 27,  b: 35,  number: 5),
        .init(r: 241, g: 218, b: 241, number: 6),
        .init(r: 231, g: 181, b: 240, number: 7),
        .init(r: 228, g: 145, b: 233, number: 8),
        .init(r: 237, g: 199, b: 240, number: 9),
        .init(r: 242, g: 242, b: 242, number: 10),
        .init(r: 188, g: 241, b: 242, number: 11),
        .init(r: 87,  g: 185, b: 235, number: 12),
        .init(r: 227, g: 109, b: 222, number: 13),
        .init(r: 194, g: 82,  b: 39,  number: 14),
        .init(r: 189, g: 176, b: 61,  number: 15),
        .init(r: 94,  g: 184, b: 56,  number: 16),
        .init(r: 199, g: 42,  b: 29,  number: 17),
        .init(r: 232, g: 140, b: 49,  number: 18),
        .init(r: 239, g: 255, b: 70,  number: 19),
        .init(r: 83,  g: 183, b: 159, number: 20),
        .init(r: 49,  g: 61,  b: 187, number: 21),
        .init(r: 142, g: 34,  b: 185, number: 22),
        .init(r: 172, g: 43,  b: 179, number: 23),
        .init(r: 117, g: 20,  b: 124, number: 24),
        .init(r: 227, g: 65,  b: 53,  number: 25),
        .init(r: 102, g: 233, b: 240, number: 26),
        .init(r: 69,  g: 103, b: 234, number: 27),
        .init(r: 189, g: 58,  b: 229, number: 28),
        .init(r: 224, g: 48,  b: 227, number: 29)
    ]
}

// MARK: - HEX -> UIColor helper
private extension UIColor {
    convenience init(hex: UInt32, alpha: CGFloat = 1) {
        let r = CGFloat((hex >> 16) & 0xFF) / 255.0
        let g = CGFloat((hex >> 8) & 0xFF) / 255.0
        let b = CGFloat(hex & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b, alpha: alpha)
    }
}

