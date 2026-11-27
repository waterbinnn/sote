import AppKit

/// 스티커 모양. 좌표는 0~1로 정규화된 값, y는 아래로 증가(flipped)한다.
/// rawValue 는 저장 데이터에 쓰이므로 이름이 바뀌어도 그대로 둔다.
enum Style: String, Codable, CaseIterable {
    case cloud, thought, bubble, lime, oval, heart, burst, rays, potato, shout, box

    // 없어진 모양(티셔츠, 라벨, 배너, 테이프 메모, UFO 등)이 저장돼 있어도 나머지 메모를 잃지 않도록 구름으로 대체한다.
    init(from decoder: Decoder) throws {
        self = Style(rawValue: try decoder.singleValueContainer().decode(String.self)) ?? .cloud
    }

    /// 반짝만 외곽선 없이 가장자리가 흐려지는 빛으로 그린다.
    var glows: Bool { self == .rays }

    var title: String {
        switch self {
        case .cloud: "Cloud"
        case .thought: "Thought Cloud"
        case .bubble: "Speech Bubble"
        case .lime: "Flat Cloud"
        case .oval: "Oval"
        case .heart: "Heart"
        case .burst: "Spiky"
        case .rays: "Sparkle"
        case .potato: "Potato"
        case .shout: "Shout"
        case .box: "Square"
        }
    }

    /// 미리보기에 쓰는 짧은 문구.
    var sample: String {
        switch self {
        case .cloud: "That's it~!\n♡♡♡"
        case .thought: "Quietly rebelling"
        case .bubble: "What's for\nlunch?"
        case .lime: "Lucky day♧♪"
        case .oval: "What a day♡"
        case .heart: "As if"
        case .burst: "How would I know"
        case .rays: "Sure ^_^.."
        case .potato: "I'm just\na talking\npotato"
        case .shout: "Busy doing\nnothing."
        case .box: "Nope,\nnot this"
        }
    }

    var defaultSize: NSSize {
        switch self {
        case .cloud: NSSize(width: 150, height: 118)
        case .thought: NSSize(width: 200, height: 84)
        case .bubble: NSSize(width: 150, height: 112)
        case .lime: NSSize(width: 170, height: 70)
        case .oval: NSSize(width: 170, height: 64)
        case .heart: NSSize(width: 120, height: 110)
        case .burst: NSSize(width: 200, height: 110)
        case .rays: NSSize(width: 150, height: 90)
        case .potato: NSSize(width: 110, height: 130)
        case .shout: NSSize(width: 180, height: 76)
        case .box: NSSize(width: 120, height: 105)
        }
    }

    /// 추천 색. 메모마다 팔레트에서 다른 색을 고를 수 있다.
    var fill: NSColor {
        let hex = switch self {
        case .cloud, .bubble, .shout, .box: 0xFFFFFF
        case .thought: 0xCFE4FF   // 베이비블루
        case .lime: 0xDDEDC2      // 피스타치오
        case .oval: 0xFFD6E0      // 딸기우유
        case .heart: 0xFFAEC6     // 체리핑크
        case .burst: 0xFFD3B8     // 살구우유
        case .rays: 0xFFE99E      // 버터
        case .potato: 0xE2D4FF    // 라일락
        }
        return NSColor(hex: hex)
    }

    var strokeWidth: CGFloat { self == .box ? 2 : 1.3 }
    var lineJoin: NSBezierPath.LineJoinStyle { [.shout, .box, .burst].contains(self) ? .miter : .round }
    var italic: Bool { self == .lime || self == .oval }

    /// 글자가 들어갈 영역(정규화 좌표).
    var textArea: NSRect {
        switch self {
        case .cloud: NSRect(x: 0.18, y: 0.2, width: 0.64, height: 0.6)
        case .thought: NSRect(x: 0.1, y: 0.14, width: 0.8, height: 0.52)
        case .bubble: NSRect(x: 0.16, y: 0.14, width: 0.68, height: 0.56)
        case .lime: NSRect(x: 0.1, y: 0.2, width: 0.8, height: 0.6)
        case .oval: NSRect(x: 0.12, y: 0.15, width: 0.76, height: 0.7)
        case .heart: NSRect(x: 0.2, y: 0.22, width: 0.6, height: 0.42)
        case .burst: NSRect(x: 0.2, y: 0.3, width: 0.6, height: 0.4)
        case .rays: NSRect(x: 0.22, y: 0.3, width: 0.56, height: 0.4)
        case .potato: NSRect(x: 0.14, y: 0.12, width: 0.72, height: 0.76)
        case .shout: NSRect(x: 0.17, y: 0.12, width: 0.77, height: 0.72)
        default: NSRect(x: 0.06, y: 0.08, width: 0.88, height: 0.84)
        }
    }

    /// 겹치는 부분은 하나의 외곽선으로 보이도록 그린다.
    func parts(in r: NSRect) -> [NSBezierPath] {
        func p(_ x: CGFloat, _ y: CGFloat) -> NSPoint { NSPoint(x: r.minX + x * r.width, y: r.minY + y * r.height) }
        func poly(_ pts: [(CGFloat, CGFloat)]) -> NSBezierPath {
            let path = NSBezierPath()
            path.move(to: p(pts[0].0, pts[0].1))
            pts.dropFirst().forEach { path.line(to: p($0.0, $0.1)) }
            path.close()
            return path
        }
        func sub(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) -> NSRect {
            NSRect(x: r.minX + x * r.width, y: r.minY + y * r.height, width: w * r.width, height: h * r.height)
        }

        switch self {
        case .cloud:
            return [scallop(r, count: 9, bump: min(r.width, r.height) * 0.1)]
        case .thought:
            let body = sub(0, 0, 1, 0.8)
            return [scallop(body, count: 14, bump: body.height * 0.12),
                    NSBezierPath(ovalIn: sub(0.66, 0.8, 0.07, 0.11)),
                    NSBezierPath(ovalIn: sub(0.74, 0.92, 0.04, 0.07))]
        case .lime:
            return [scallop(r, count: 16, bump: r.height * 0.11)]
        case .oval:
            return [NSBezierPath(ovalIn: r)]
        case .bubble:
            return [NSBezierPath(ovalIn: sub(0, 0, 1, 0.84)), poly([(0.62, 0.7), (0.8, 0.74), (0.97, 1.0)])]
        case .heart:
            let path = NSBezierPath()
            path.move(to: p(0.5, 1.0))
            path.curve(to: p(0.0, 0.33), controlPoint1: p(0.22, 0.78), controlPoint2: p(0.0, 0.58))
            path.curve(to: p(0.5, 0.17), controlPoint1: p(0.0, 0.03), controlPoint2: p(0.4, -0.04))
            path.curve(to: p(1.0, 0.33), controlPoint1: p(0.6, -0.04), controlPoint2: p(1.0, 0.03))
            path.curve(to: p(0.5, 1.0), controlPoint1: p(1.0, 0.58), controlPoint2: p(0.78, 0.78))
            path.close()
            return [path]
        case .burst:
            // 바깥/안쪽 반지름을 번갈아 찍되, 살짝 들쭉날쭉하게 해서 손으로 그린 느낌을 낸다.
            let n = 22
            let pts = (0..<n * 2).map { i -> (CGFloat, CGFloat) in
                let a = CGFloat(i) / CGFloat(n * 2) * 2 * .pi
                let k = i % 2 == 0 ? 0.5 - 0.035 * (1 + sin(CGFloat(i) * 1.7)) : 0.36
                return (0.5 + k * cos(a), 0.5 + k * sin(a))
            }
            return [poly(pts)]
        case .rays:
            return [NSBezierPath(ovalIn: sub(0.12, 0.14, 0.76, 0.72))]
        case .potato:
            return [blob(r, radii: [1.0, 0.94, 0.97, 0.99, 0.93, 0.96, 1.0, 0.95, 0.92, 0.98, 0.96, 0.93])]
        case .box:
            return [NSBezierPath(rect: r.insetBy(dx: 1, dy: 1))]
        case .shout:
            return [poly([
                (0.1, 0.04), (0.98, 0.0), (1.0, 0.86), (0.3, 0.9), (0.06, 1.0), (0.16, 0.8),
                (0.0, 0.66), (0.1, 0.56), (0.02, 0.42), (0.12, 0.3), (0.04, 0.16),
            ])]
        }
    }

    /// 외곽선과 따로 그리는 선 장식(반짝이 빛줄기).
    func decoration(in r: NSRect) -> NSBezierPath? {
        guard self == .rays else { return nil }
        let path = NSBezierPath()
        let c = NSPoint(x: r.midX, y: r.midY), n = 14
        for i in 0..<n {
            let a = CGFloat(i) / CGFloat(n) * 2 * .pi + 0.2
            let inner: CGFloat = i % 2 == 0 ? 0.8 : 0.84, outer: CGFloat = i % 2 == 0 ? 0.98 : 0.94
            path.move(to: NSPoint(x: c.x + cos(a) * r.width / 2 * inner, y: c.y + sin(a) * r.height / 2 * inner))
            path.line(to: NSPoint(x: c.x + cos(a) * r.width / 2 * outer, y: c.y + sin(a) * r.height / 2 * outer))
        }
        path.lineCapStyle = .round
        return path
    }

    /// 타원 둘레에 볼록한 혹을 붙여 구름 모양을 만든다.
    private func scallop(_ r: NSRect, count n: Int, bump: CGFloat) -> NSBezierPath {
        let c = NSPoint(x: r.midX, y: r.midY)
        let rx = r.width / 2 - bump, ry = r.height / 2 - bump
        let k = bump / 0.75 * 1.15
        let pts = (0..<n).map { i -> (NSPoint, NSPoint) in
            let a = CGFloat(i) / CGFloat(n) * 2 * .pi + 0.3
            let pt = NSPoint(x: c.x + rx * cos(a), y: c.y + ry * sin(a))
            let nx = cos(a) / rx, ny = sin(a) / ry, len = hypot(nx, ny)
            return (pt, NSPoint(x: nx / len, y: ny / len))
        }
        let path = NSBezierPath()
        path.move(to: pts[0].0)
        for i in 0..<n {
            let (a, na) = pts[i], (b, nb) = pts[(i + 1) % n]
            path.curve(to: b,
                       controlPoint1: NSPoint(x: a.x + na.x * k, y: a.y + na.y * k),
                       controlPoint2: NSPoint(x: b.x + nb.x * k, y: b.y + nb.y * k))
        }
        path.close()
        return path
    }

    /// 반지름이 조금씩 다른 점들을 부드럽게 이어 울퉁불퉁한 덩어리를 만든다(Catmull-Rom).
    private func blob(_ r: NSRect, radii: [CGFloat]) -> NSBezierPath {
        let c = NSPoint(x: r.midX, y: r.midY), n = radii.count
        let pts = radii.enumerated().map { i, k -> NSPoint in
            let a = CGFloat(i) / CGFloat(n) * 2 * .pi
            return NSPoint(x: c.x + cos(a) * r.width / 2 * k, y: c.y + sin(a) * r.height / 2 * k)
        }
        let path = NSBezierPath()
        path.move(to: pts[0])
        for i in 0..<n {
            let p0 = pts[(i + n - 1) % n], p1 = pts[i], p2 = pts[(i + 1) % n], p3 = pts[(i + 2) % n]
            path.curve(to: p2,
                       controlPoint1: NSPoint(x: p1.x + (p2.x - p0.x) / 6, y: p1.y + (p2.y - p0.y) / 6),
                       controlPoint2: NSPoint(x: p2.x - (p3.x - p1.x) / 6, y: p2.y - (p3.y - p1.y) / 6))
        }
        path.close()
        return path
    }
}

enum Weight: String, Codable, CaseIterable {
    case light, regular, bold, heavy

    var title: String {
        switch self {
        case .light: "Light"
        case .regular: "Regular"
        case .bold: "Bold"
        case .heavy: "Heavy"
        }
    }

    func font(size: CGFloat) -> NSFont {
        let names: [String] = switch self {
        case .light: ["AppleSDGothicNeo-Light"]
        case .regular: ["NanumGothic", "AppleSDGothicNeo-Regular"]
        case .bold: ["NanumGothicBold", "AppleSDGothicNeo-Bold"]
        case .heavy: ["NanumGothicExtraBold", "AppleSDGothicNeo-ExtraBold"]
        }
        let fallback: NSFont.Weight = switch self {
        case .light: .light
        case .regular: .regular
        case .bold: .bold
        case .heavy: .heavy
        }
        return names.lazy.compactMap { NSFont(name: $0, size: size) }.first ?? .systemFont(ofSize: size, weight: fallback)
    }
}

enum Align: String, Codable, CaseIterable {
    case left, center, right

    var title: String {
        switch self {
        case .left: "Left"
        case .center: "Center"
        case .right: "Right"
        }
    }

    var ns: NSTextAlignment {
        switch self {
        case .left: .left
        case .center: .center
        case .right: .right
        }
    }
}

let fontSizes: [CGFloat] = [10, 11, 12, 13, 14, 16, 18, 20, 24, 28, 32]

/// 메모 색상 팔레트: 요즘 다꾸 스티커에서 많이 쓰는 우유 섞인 파스텔(버터·말차·딸기우유 톤).
let palette: [(name: String, hex: Int)] = [
    ("White", 0xFFFFFF), ("Cream", 0xFFF4DE), ("Butter", 0xFFE99E), ("Strawberry Milk", 0xFFD6E0), ("Cherry Pink", 0xFFAEC6),
    ("Peach", 0xFFE3D3), ("Apricot Milk", 0xFFD3B8), ("Pistachio", 0xDDEDC2), ("Matcha Latte", 0xCBE5B8), ("Mint", 0xCDEFE3),
    ("Baby Blue", 0xCFE4FF), ("Periwinkle", 0xB4C8FF), ("Lilac", 0xE2D4FF), ("Lavender", 0xC6B4F7), ("Black", 0x1A1A1A),
]

extension NSColor {
    convenience init(hex: Int) {
        self.init(srgbRed: CGFloat(hex >> 16 & 0xFF) / 255, green: CGFloat(hex >> 8 & 0xFF) / 255,
                  blue: CGFloat(hex & 0xFF) / 255, alpha: 1)
    }

    /// 배경이 진하면 흰 글자, 밝으면 검은 글자.
    var readableText: NSColor {
        guard let c = usingColorSpace(.sRGB) else { return .black }
        func lin(_ v: CGFloat) -> CGFloat { v <= 0.04045 ? v / 12.92 : pow((v + 0.055) / 1.055, 2.4) }
        let l = 0.2126 * lin(c.redComponent) + 0.7152 * lin(c.greenComponent) + 0.0722 * lin(c.blueComponent)
        return l < 0.45 ? .white : NSColor(hex: 0x1A1A1A)
    }
}
