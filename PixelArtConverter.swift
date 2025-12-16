import UIKit
import CoreGraphics

struct RGBColor {
    let r: UInt8
    let g: UInt8
    let b: UInt8
    let number: UInt8
}

enum PixelArtConverter {

    private static let colorMap: [RGBColor] = [
        RGBColor(r: 128, g: 128, b: 128, number: 1),
        RGBColor(r: 0, g: 0, b: 255, number: 2),
        RGBColor(r: 255, g: 165, b: 0, number: 3),
        RGBColor(r: 254, g: 0, b: 0, number: 4),
        RGBColor(r: 255, g: 255, b: 255, number: 5),
        RGBColor(r: 0, g: 0, b: 0, number: 9),
    ]

    static func convert(imageName: String) -> (w: Int, h: Int, numbers: [UInt8])? {
        guard let uiImage = UIImage(named: imageName),
              let cgImage = uiImage.cgImage else {
            print("❌ Не удалось загрузить \(imageName)")
            return nil
        }

        let width = cgImage.width
        let height = cgImage.height

        let bytesPerPixel = 4
        let bitsPerComponent = 8
        let bytesPerRow = bytesPerPixel * width

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        var rawData = [UInt8](repeating: 0, count: height * bytesPerRow)

        guard let context = CGContext(
            data: &rawData,
            width: width,
            height: height,
            bitsPerComponent: bitsPerComponent,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        var out = [UInt8](repeating: 0, count: width * height)

        for y in 0..<height {
            for x in 0..<width {
                let pixelOffset = (y * bytesPerRow) + x * bytesPerPixel
                let r = rawData[pixelOffset]
                let g = rawData[pixelOffset + 1]
                let b = rawData[pixelOffset + 2]
                let a = rawData[pixelOffset + 3]

                if a < 10 {
                    out[y * width + x] = 0
                } else {
                    out[y * width + x] = findClosestNumber(r: r, g: g, b: b)
                }
            }
        }

        print("✅ Grid готов: \(width)x\(height)")
        return (width, height, out)
    }

    private static func findClosestNumber(r: UInt8, g: UInt8, b: UInt8) -> UInt8 {
        var minDist = Double.greatestFiniteMagnitude
        var best: UInt8 = 1

        let p1r = Double(r), p1g = Double(g), p1b = Double(b)

        for c in colorMap {
            let dr = p1r - Double(c.r)
            let dg = p1g - Double(c.g)
            let db = p1b - Double(c.b)
            let d = dr*dr + dg*dg + db*db
            if d < minDist {
                minDist = d
                best = c.number
            }
        }
        return best
    }
}

