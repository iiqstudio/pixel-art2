
import UIKit
import CoreGraphics

struct PixelArtResult {
    let w: Int
    let h: Int
    let numbers: [UInt8]
}

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
        RGBColor(r: 0, g: 0, b: 0, number: 9)
    ]

    static func convert(imageName: String) -> PixelArtResult? {
        guard let uiImage = UIImage(named: imageName),
              let cgImage = uiImage.cgImage else { return nil }

        let width = cgImage.width
        let height = cgImage.height
        let bytesPerPixel = 4
        let bitsPerComponent = 8
        let bytesPerRow = bytesPerPixel * width

        var raw = [UInt8](repeating: 0, count: height * bytesPerRow)

        guard let ctx = CGContext(
            data: &raw,
            width: width,
            height: height,
            bitsPerComponent: bitsPerComponent,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }

        ctx.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        let bgMask = buildBackgroundMask(width: width, height: height, rgba: raw, bytesPerRow: bytesPerRow)

        var out = [UInt8](repeating: 0, count: width * height)

        for y in 0..<height {
            for x in 0..<width {
                let idx1d = y * width + x
                if bgMask[idx1d] {
                    out[idx1d] = 0
                    continue
                }

                let off = y * bytesPerRow + x * 4
                let r = raw[off]
                let g = raw[off + 1]
                let b = raw[off + 2]
                let a = raw[off + 3]

                if a < 10 {
                    out[idx1d] = 0
                    continue
                }

                out[idx1d] = findClosestNumber(r: r, g: g, b: b)
            }
        } 

        return PixelArtResult(w: width, h: height, numbers: out)
    }

    private static func findClosestNumber(r: UInt8, g: UInt8, b: UInt8) -> UInt8 {
        var best: UInt8 = 1
        var minDist = Double.greatestFiniteMagnitude

        let p1r = Double(r)
        let p1g = Double(g)
        let p1b = Double(b)

        for c in colorMap {
            let dr = p1r - Double(c.r)
            let dg = p1g - Double(c.g)
            let db = p1b - Double(c.b)
            let d = dr * dr + dg * dg + db * db
            if d < minDist {
                minDist = d
                best = c.number
            }
        }
        return best
    }

    private static func buildBackgroundMask(width: Int, height: Int, rgba: [UInt8], bytesPerRow: Int) -> [Bool] {
        func isWhiteLike(_ r: UInt8, _ g: UInt8, _ b: UInt8, _ a: UInt8) -> Bool {
            if a < 10 { return true }
            return r > 245 && g > 245 && b > 245
        }

        var bg = [Bool](repeating: false, count: width * height)
        var qx: [Int] = []
        var qy: [Int] = []
        qx.reserveCapacity(width * 2 + height * 2)
        qy.reserveCapacity(width * 2 + height * 2)

        func push(_ x: Int, _ y: Int) {
            let idx = y * width + x
            if bg[idx] { return }

            let off = y * bytesPerRow + x * 4
            let r = rgba[off]
            let g = rgba[off + 1]
            let b = rgba[off + 2]
            let a = rgba[off + 3]

            guard isWhiteLike(r, g, b, a) else { return }
            bg[idx] = true
            qx.append(x)
            qy.append(y)
        }

        for x in 0..<width {
            push(x, 0)
            push(x, height - 1)
        }
        for y in 0..<height {
            push(0, y)
            push(width - 1, y)
        }

        var head = 0
        while head < qx.count {
            let x = qx[head]
            let y = qy[head]
            head += 1

            if x > 0 { push(x - 1, y) }
            if x + 1 < width { push(x + 1, y) }
            if y > 0 { push(x, y - 1) }
            if y + 1 < height { push(x, y + 1) }
        }

        return bg
    }
}

