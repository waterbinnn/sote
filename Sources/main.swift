import AppKit

let app = NSApplication.shared

// 개발용: `Sote --icon out.png` 로 앱 아이콘 원본(1024px)을 만든다.
if let i = CommandLine.arguments.firstIndex(of: "--icon"), i + 1 < CommandLine.arguments.count {
    try! appIconPNG().write(to: URL(fileURLWithPath: CommandLine.arguments[i + 1]))
    exit(0)
}

// 개발용: `Sote --snapshot out.png` 로 모든 모양을 한 장의 이미지로 렌더링한다.
if let i = CommandLine.arguments.firstIndex(of: "--snapshot"), i + 1 < CommandLine.arguments.count {
    let samples = Style.allCases.map(\.sample) + ["To do today: groceries, drop off the dry cleaning, call mom. Gym tomorrow for sure!"]
    let canvas = FlippedView(frame: NSRect(x: 0, y: 0, width: 640, height: 760))
    var x: CGFloat = 10, y: CGFloat = 10, rowH: CGFloat = 0
    for (style, text) in zip(Style.allCases + [.cloud], samples) {
        let size = style.defaultSize
        if x + size.width > canvas.bounds.width { x = 10; y += rowH + 10; rowH = 0 }
        let v = NoteView(style: style, text: text)
        v.frame = NSRect(origin: NSPoint(x: x, y: y), size: size)
        canvas.addSubview(v)
        if text.count > 30 { v.color = NSColor(hex: 0xA08CF0); v.fontSize = 16; v.weight = .bold; v.align = .left }  // 색·크기·굵기·정렬 지정 확인용
        v.growToFitText()
        x += size.width + 10
        rowH = max(rowH, size.height)
    }
    let rep = canvas.bitmapImageRepForCachingDisplay(in: canvas.bounds)!
    canvas.cacheDisplay(in: canvas.bounds, to: rep)
    try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: CommandLine.arguments[i + 1]))
    let icon = statusIcon(), irep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: 44, pixelsHigh: 32, bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    irep.size = icon.size
    NSGraphicsContext.saveGraphicsState(); NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: irep)
    NSColor.white.setFill(); NSRect(origin: .zero, size: icon.size).fill(); icon.draw(in: NSRect(origin: .zero, size: icon.size))
    NSGraphicsContext.restoreGraphicsState()
    try! irep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: CommandLine.arguments[i + 1] + "-status.png"))
    // 팔레트 견본
    let sw = FlippedView(frame: NSRect(x: 0, y: 0, width: CGFloat(palette.count) * 70 + 10, height: 90))
    for (k, (name, hex)) in palette.enumerated() {
        let v = NoteView(style: .oval, text: name); v.color = NSColor(hex: hex)
        v.frame = NSRect(x: 10 + CGFloat(k) * 70, y: 10, width: 64, height: 70); sw.addSubview(v)
    }
    let srep = sw.bitmapImageRepForCachingDisplay(in: sw.bounds)!; sw.cacheDisplay(in: sw.bounds, to: srep)
    try! srep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: CommandLine.arguments[i + 1] + "-palette.png"))
    let picker = StylePicker { _ in }
    let prep = picker.bitmapImageRepForCachingDisplay(in: picker.bounds)!
    picker.cacheDisplay(in: picker.bounds, to: prep)
    try! prep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: CommandLine.arguments[i + 1] + "-picker.png"))
    exit(0)
}

final class FlippedView: NSView {
    override var isFlipped: Bool { true }
    override func draw(_ r: NSRect) { NSColor.white.setFill(); r.fill() }
}

app.setActivationPolicy(.regular)
app.delegate = App.shared
app.run()
