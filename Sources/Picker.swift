import AppKit

/// 실제 메모 뷰를 그대로 렌더링해서 축소한 미리보기 이미지.
func preview(_ style: Style, fit: NSSize) -> NSImage {
    let key = "\(style.rawValue)-\(fit.width)x\(fit.height)"
    if let cached = previewCache[key] { return cached }
    let v = NoteView(style: style, text: style.sample)
    v.growToFitText()
    let rep = v.bitmapImageRepForCachingDisplay(in: v.bounds)!
    v.cacheDisplay(in: v.bounds, to: rep)
    let src = NSImage(size: v.bounds.size)
    src.addRepresentation(rep)
    let k = min(fit.width / src.size.width, fit.height / src.size.height)
    let img = NSImage(size: NSSize(width: src.size.width * k, height: src.size.height * k), flipped: false) {
        src.draw(in: $0)
        return true
    }
    previewCache[key] = img
    return img
}

private var previewCache: [String: NSImage] = [:]

/// 메뉴 안에 들어가는 모양 선택판(4열 그리드).
final class StylePicker: NSView {
    private let cell = NSSize(width: 112, height: 96)
    private let gap: CGFloat = 6, inset: CGFloat = 12
    private let onPick: (Style) -> Void

    init(onPick: @escaping (Style) -> Void) {
        self.onPick = onPick
        let cols = 4, rows = (Style.allCases.count + cols - 1) / cols
        super.init(frame: NSRect(x: 0, y: 0,
                                 width: inset * 2 + CGFloat(cols) * cell.width + CGFloat(cols - 1) * gap,
                                 height: inset + CGFloat(rows) * cell.height + CGFloat(rows - 1) * gap + 4))
        for (i, style) in Style.allCases.enumerated() {
            let c = PickerCell(style: style, size: cell) { [unowned self] in
                self.enclosingMenuItem?.menu?.cancelTracking()
                self.onPick(style)
            }
            c.frame.origin = NSPoint(x: inset + CGFloat(i % cols) * (cell.width + gap),
                                     y: 4 + CGFloat(i / cols) * (cell.height + gap))
            addSubview(c)
        }
    }

    required init?(coder: NSCoder) { fatalError() }
    override var isFlipped: Bool { true }
}

private final class PickerCell: NSView {
    private let style: Style
    private let action: () -> Void
    private let image: NSImage
    private var hovering = false { didSet { needsDisplay = true } }

    init(style: Style, size: NSSize, action: @escaping () -> Void) {
        self.style = style
        self.action = action
        image = preview(style, fit: NSSize(width: size.width - 12, height: size.height - 28))
        super.init(frame: NSRect(origin: .zero, size: size))
        toolTip = style.title
        addTrackingArea(NSTrackingArea(rect: .zero, options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect], owner: self))
    }

    required init?(coder: NSCoder) { fatalError() }
    override var isFlipped: Bool { true }

    override func draw(_ dirtyRect: NSRect) {
        if hovering {
            NSColor.controlAccentColor.withAlphaComponent(0.18).setFill()
            NSBezierPath(roundedRect: bounds, xRadius: 10, yRadius: 10).fill()
        }
        let area = NSRect(x: 0, y: 4, width: bounds.width, height: bounds.height - 26)
        image.draw(in: NSRect(x: area.midX - image.size.width / 2, y: area.midY - image.size.height / 2,
                              width: image.size.width, height: image.size.height),
                   from: .zero, operation: .sourceOver, fraction: 1, respectFlipped: true, hints: nil)
        let title = NSAttributedString(string: style.title, attributes: [
            .font: NSFont.systemFont(ofSize: 11, weight: .medium), .foregroundColor: NSColor.labelColor,
        ])
        let s = title.size()
        title.draw(at: NSPoint(x: bounds.midX - s.width / 2, y: bounds.maxY - s.height - 4))
    }

    override func mouseEntered(with event: NSEvent) { hovering = true }
    override func mouseExited(with event: NSEvent) { hovering = false }
    override func mouseUp(with event: NSEvent) { action() }
}

/// 메뉴바 아이콘: 반짝 메모 스티커(가로로 긴 타원 + 안쪽 글줄 + 빛줄기). 템플릿 이미지라 다크 모드에 맞춰 색이 바뀐다.
func statusIcon() -> NSImage {
    let img = NSImage(size: NSSize(width: 22, height: 16), flipped: true) { r in
        NSColor.black.set()
        let body = NSRect(x: 4, y: 3.5, width: 14, height: 9)
        let oval = NSBezierPath(ovalIn: body)
        oval.lineWidth = 1.3
        oval.stroke()
        let lines = NSBezierPath()
        lines.move(to: NSPoint(x: 8, y: 7)); lines.line(to: NSPoint(x: 14, y: 7))
        lines.move(to: NSPoint(x: 8.8, y: 9.4)); lines.line(to: NSPoint(x: 12.4, y: 9.4))
        lines.lineWidth = 1.1
        lines.lineCapStyle = .round
        lines.stroke()
        Style.rays.decoration(in: NSRect(x: 0.5, y: 0.5, width: 21, height: 15)).map { $0.lineWidth = 1.1; $0.stroke() }
        return true
    }
    img.isTemplate = true
    return img
}

/// 앱 아이콘(1024px): 흰 배경 위에 "반짝" 메모 스티커.
func appIconPNG() -> Data {
    let size = NSSize(width: 1024, height: 1024)
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: 1024, pixelsHigh: 1024, bitsPerSample: 8,
                               samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB,
                               bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    let ctx = NSGraphicsContext.current!.cgContext
    ctx.translateBy(x: 0, y: size.height)
    ctx.scaleBy(x: 1, y: -1)  // 메모와 같은 y-아래 좌표계
    NSGraphicsContext.current = NSGraphicsContext(cgContext: ctx, flipped: true)  // 글자도 뒤집히지 않게

    // macOS 아이콘 그리드: 824px 둥근 사각형 + 은은한 그림자
    let tile = NSBezierPath(roundedRect: NSRect(x: 100, y: 100, width: 824, height: 824), xRadius: 185, yRadius: 185)
    NSGraphicsContext.saveGraphicsState()
    let soft = NSShadow()
    soft.shadowColor = NSColor.black.withAlphaComponent(0.25)
    soft.shadowBlurRadius = 24
    soft.shadowOffset = NSSize(width: 0, height: -10)
    soft.set()
    NSColor.white.setFill()
    tile.fill()
    NSGraphicsContext.restoreGraphicsState()

    // 메모의 "반짝" 스티커를 그대로 크게 그린다: 가로로 긴 빛 타원 + 얇은 빛줄기 + 글자.
    let r = NSRect(x: 150, y: 290, width: 724, height: 444)
    let fill = Style.rays.fill
    let glow = NSGradient(colors: [fill, fill, fill.withAlphaComponent(0)], atLocations: [0, 0.55, 1], colorSpace: .sRGB)
    Style.rays.parts(in: r).forEach { glow?.draw(in: $0, relativeCenterPosition: .zero) }
    NSColor(hex: 0x1A1A1A).setStroke()
    Style.rays.decoration(in: r).map { $0.lineWidth = 16; $0.stroke() }

    let text = NSAttributedString(string: "sote", attributes: [
        .font: Weight.heavy.font(size: 150), .foregroundColor: NSColor(hex: 0x1A1A1A),
    ])
    let ts = text.size()
    text.draw(at: NSPoint(x: r.midX - ts.width / 2, y: r.midY - ts.height / 2 + 4))
    NSGraphicsContext.restoreGraphicsState()
    return rep.representation(using: .png, properties: [:])!
}
