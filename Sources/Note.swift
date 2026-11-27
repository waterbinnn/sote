import AppKit

struct NoteData: Codable {
    var id = UUID()
    var style: Style
    var text = ""
    var frame: CGRect
    var onTop: Bool
    // 아래 값들은 예전에 저장된 메모에 없을 수 있어서 optional 로 둔다.
    var color: Int?          // nil 이면 모양의 추천 색
    var fontSize: CGFloat?   // nil 이면 12
    var weight: Weight?      // nil 이면 보통
    var align: Align?        // nil 이면 가운데
}

/// 메모 한 장 = 테두리 없는 투명 창 하나.
final class NoteWindow: NSWindow, NSWindowDelegate {
    var data: NoteData { didSet { App.shared.save() } }
    let noteView: NoteView

    init(_ data: NoteData) {
        self.data = data
        noteView = NoteView(style: data.style, text: data.text)
        noteView.fontSize = data.fontSize ?? 12
        noteView.weight = data.weight ?? .regular
        noteView.align = data.align ?? .center
        noteView.color = data.color.map { NSColor(hex: $0) }
        super.init(contentRect: data.frame, styleMask: [.borderless], backing: .buffered, defer: false)
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        isReleasedWhenClosed = false
        delegate = self
        contentView = noteView
        noteView.onTextChange = { [unowned self] in self.data.text = $0 }
        applyOnTop()
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }

    private func applyOnTop() {
        // .floating 레벨은 앱이 비활성 상태여도 일반 창(브라우저 등)보다 위에 유지된다.
        level = data.onTop ? .floating : .normal
        collectionBehavior = data.onTop ? [.canJoinAllSpaces, .fullScreenAuxiliary] : []
    }

    @objc func toggleOnTop(_ sender: Any?) {
        data.onTop.toggle()
        App.shared.lastOnTop = data.onTop
        applyOnTop()
    }

    @objc func changeStyle(_ sender: NSMenuItem) {
        guard let style = Style(rawValue: sender.representedObject as? String ?? "") else { return }
        data.style = style
        noteView.style = style
        let size = style.defaultSize
        setFrame(NSRect(x: frame.minX, y: frame.maxY - size.height, width: size.width, height: size.height), display: true)
        noteView.growToFitText()
    }

    @objc func changeFontSize(_ sender: NSMenuItem) {
        guard let size = sender.representedObject as? CGFloat else { return }
        data.fontSize = size
        noteView.fontSize = size
        noteView.growToFitText()
    }

    @objc func changeWeight(_ sender: NSMenuItem) {
        guard let weight = Weight(rawValue: sender.representedObject as? String ?? "") else { return }
        data.weight = weight
        noteView.weight = weight
        noteView.growToFitText()
    }

    @objc func changeAlign(_ sender: NSMenuItem) {
        guard let align = Align(rawValue: sender.representedObject as? String ?? "") else { return }
        data.align = align
        noteView.align = align
    }

    /// representedObject 가 nil 이면 모양의 기본색으로 되돌린다.
    @objc func changeColor(_ sender: NSMenuItem) {
        data.color = sender.representedObject as? Int
        noteView.color = data.color.map { NSColor(hex: $0) }
    }

    /// 모양 크기만 키우거나 줄인다(글자 크기는 그대로). 가운데를 기준으로 변한다.
    func zoom(by factor: CGFloat) {
        let f = frame, w = max(60, f.width * factor), h = max(40, f.height * factor)
        setFrame(NSRect(x: f.midX - w / 2, y: f.midY - h / 2, width: w, height: h), display: true)
        noteView.growToFitText()
    }


    @objc func deleteNote(_ sender: Any?) {
        if !data.text.isEmpty {
            let alert = NSAlert()
            alert.messageText = "Delete this note?"
            alert.addButton(withTitle: "Delete")
            alert.addButton(withTitle: "Cancel")
            guard alert.runModal() == .alertFirstButtonReturn else { return }
        }
        App.shared.remove(self)
    }

    override func validateMenuItem(_ item: NSMenuItem) -> Bool {
        switch item.action {
        case #selector(toggleOnTop(_:)): item.state = data.onTop ? .on : .off
        case #selector(changeStyle(_:)): item.state = item.representedObject as? String == data.style.rawValue ? .on : .off
        case #selector(changeColor(_:)): item.state = item.representedObject as? Int == data.color ? .on : .off
        case #selector(changeFontSize(_:)): item.state = item.representedObject as? CGFloat == (data.fontSize ?? 12) ? .on : .off
        case #selector(changeWeight(_:)): item.state = item.representedObject as? String == (data.weight ?? .regular).rawValue ? .on : .off
        case #selector(changeAlign(_:)): item.state = item.representedObject as? String == (data.align ?? .center).rawValue ? .on : .off
        default: return super.validateMenuItem(item)
        }
        return true
    }

    func windowDidMove(_ n: Notification) { data.frame = frame }
    func windowDidResize(_ n: Notification) { data.frame = frame }
    func windowDidResignKey(_ n: Notification) { noteView.endEditing() }
}

final class NoteView: NSView, NSTextViewDelegate {
    var style: Style { didSet { applyStyle() } }
    var fontSize: CGFloat = 12 { didSet { applyStyle() } }
    var weight: Weight = .regular { didSet { applyStyle() } }
    var align: Align = .center { didSet { applyStyle() } }
    var color: NSColor? { didSet { applyStyle() } }
    private var fill: NSColor { color ?? style.fill }
    var onTextChange: ((String) -> Void)?
    private let textView = NSTextView()
    private var hovering = false { didSet { needsDisplay = true } }
    private let pad: CGFloat = 8  // 그림자가 들어갈 여백
    private var gripRect: NSRect { NSRect(x: bounds.maxX - 24, y: bounds.maxY - 24, width: 22, height: 22) }

    init(style: Style, text: String) {
        self.style = style
        super.init(frame: NSRect(origin: .zero, size: style.defaultSize))
        autoresizingMask = [.width, .height]
        textView.string = text
        textView.drawsBackground = false
        textView.isRichText = false
        textView.allowsUndo = true
        textView.isEditable = false
        textView.isSelectable = false
        textView.textContainerInset = .zero
        textView.textContainer?.lineFragmentPadding = 0
        textView.textContainer?.widthTracksTextView = false
        textView.isVerticallyResizable = false
        textView.isHorizontallyResizable = false
        textView.delegate = self
        addSubview(textView)
        addTrackingArea(NSTrackingArea(rect: .zero, options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect], owner: self))
        applyStyle()
    }

    required init?(coder: NSCoder) { fatalError() }

    override var isFlipped: Bool { true }
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    private var shapeRect: NSRect { bounds.insetBy(dx: pad, dy: pad) }

    private var attributes: [NSAttributedString.Key: Any] {
        let para = NSMutableParagraphStyle()
        para.alignment = align.ns
        para.lineHeightMultiple = 1.12
        para.lineBreakStrategy = .hangulWordPriority
        var a: [NSAttributedString.Key: Any] = [.font: weight.font(size: fontSize), .foregroundColor: fill.readableText, .paragraphStyle: para]
        if style.italic { a[.obliqueness] = 0.18 }
        return a
    }

    private func applyStyle() {
        let a = attributes
        textView.typingAttributes = a
        textView.textStorage?.setAttributes(a, range: NSRange(location: 0, length: textView.string.utf16.count))
        textView.insertionPointColor = fill.readableText
        layoutText()
        needsDisplay = true
    }

    /// 글자 높이만큼만 텍스트뷰를 잡고 모양 안에서 세로 가운데 정렬한다.
    private func layoutText() {
        let r = shapeRect, t = style.textArea
        let area = NSRect(x: r.minX + t.minX * r.width, y: r.minY + t.minY * r.height,
                          width: t.width * r.width, height: t.height * r.height)
        guard let container = textView.textContainer, let lm = textView.layoutManager else { return }
        container.containerSize = NSSize(width: area.width, height: .greatestFiniteMagnitude)
        lm.ensureLayout(for: container)
        let font = weight.font(size: fontSize)
        let h = max(lm.usedRect(for: container).height, font.ascender - font.descender + font.leading)
        textView.frame = NSRect(x: area.minX, y: area.midY - h / 2, width: area.width, height: h)
    }

    override func setFrameSize(_ newSize: NSSize) {
        super.setFrameSize(newSize)
        layoutText()
    }

    override func draw(_ dirtyRect: NSRect) {
        let r = shapeRect, parts = style.parts(in: r), ink = NSColor(hex: 0x1A1A1A)
        if style.glows {
            // 반짝: 가장자리로 갈수록 흐려지는 빛
            let glow = NSGradient(colors: [fill, fill, fill.withAlphaComponent(0)], atLocations: [0, 0.55, 1], colorSpace: .sRGB)
            parts.forEach { glow?.draw(in: $0, relativeCenterPosition: .zero) }
        } else {
            // 검은 외곽선 스티커 + 오른쪽 아래로 떨어지는 단단한 그림자
            NSGraphicsContext.saveGraphicsState()
            let shadow = NSShadow()
            shadow.shadowColor = ink
            shadow.shadowBlurRadius = 0
            shadow.shadowOffset = NSSize(width: 1.5, height: -2)
            shadow.set()
            fill.setFill()
            parts.forEach { $0.fill() }
            NSGraphicsContext.restoreGraphicsState()

            // 두 배 굵기로 그린 뒤 안쪽을 다시 칠하면, 겹친 조각도 바깥 외곽선만 남는다.
            ink.setStroke()
            for part in parts {
                part.lineWidth = style.strokeWidth * 2
                part.lineJoinStyle = style.lineJoin
                part.stroke()
            }
            fill.setFill()
            parts.forEach { $0.fill() }
        }
        // 반짝의 빛줄기
        if let rays = style.decoration(in: r) {
            ink.setStroke()
            rays.lineWidth = 1.3
            rays.lineCapStyle = .round
            rays.stroke()
        }

        if textView.string.isEmpty && !textView.isEditable {
            let hint = NSAttributedString(string: "Double-click to type", attributes: [
                .font: NSFont.systemFont(ofSize: 11), .foregroundColor: fill.readableText.withAlphaComponent(0.4),
            ])
            let s = hint.size()
            hint.draw(at: NSPoint(x: textView.frame.midX - s.width / 2, y: textView.frame.midY - s.height / 2))
        }

        // 투명한 픽셀은 클릭이 통과하므로, 손잡이는 불투명한 원으로 그린다.
        if hovering {
            let dot = NSBezierPath(ovalIn: gripRect.insetBy(dx: 1, dy: 1))
            NSColor(hex: 0x1A1A1A).setFill()
            dot.fill()
            NSColor.white.setStroke()
            let r = gripRect.insetBy(dx: 7, dy: 7), g = NSBezierPath()
            g.move(to: NSPoint(x: r.minX, y: r.minY)); g.line(to: NSPoint(x: r.maxX, y: r.maxY))
            g.move(to: NSPoint(x: r.minX, y: r.minY + 4)); g.line(to: r.origin); g.line(to: NSPoint(x: r.minX + 4, y: r.minY))
            g.move(to: NSPoint(x: r.maxX, y: r.maxY - 4)); g.line(to: NSPoint(x: r.maxX, y: r.maxY)); g.line(to: NSPoint(x: r.maxX - 4, y: r.maxY))
            g.lineWidth = 1.6
            g.lineCapStyle = .round
            g.stroke()
        }
    }

    // 편집 중이 아닐 때는 글자 위를 눌러도 창 이동으로 처리한다.
    override func hitTest(_ point: NSPoint) -> NSView? {
        let v = super.hitTest(point)
        return v === textView && !textView.isEditable ? self : v
    }

    override func mouseDown(with event: NSEvent) {
        guard let window else { return }
        NSApp.activate()
        window.makeKeyAndOrderFront(nil)
        if event.clickCount == 2 { return beginEditing() }
        let p = convert(event.locationInWindow, from: nil)
        if gripRect.insetBy(dx: -4, dy: -4).contains(p) { return resize(window) }
        window.performDrag(with: event)
    }

    private func resize(_ window: NSWindow) {
        let start = NSEvent.mouseLocation, f = window.frame
        while let e = window.nextEvent(matching: [.leftMouseDragged, .leftMouseUp]), e.type == .leftMouseDragged {
            let m = NSEvent.mouseLocation
            let w = max(120, f.width + m.x - start.x), h = max(60, f.height - (m.y - start.y))
            window.setFrame(NSRect(x: f.minX, y: f.maxY - h, width: w, height: h), display: true)
        }
    }

    func beginEditing() {
        textView.isEditable = true
        textView.isSelectable = true
        window?.makeFirstResponder(textView)
        textView.setSelectedRange(NSRange(location: textView.string.utf16.count, length: 0))
        needsDisplay = true
    }

    func endEditing() {
        guard textView.isEditable else { return }
        // 먼저 플래그를 내려서 makeFirstResponder → textDidEndEditing 재진입을 막는다.
        textView.isEditable = false
        textView.isSelectable = false
        if window?.firstResponder === textView { window?.makeFirstResponder(nil) }
        needsDisplay = true
    }

    func textDidChange(_ n: Notification) {
        layoutText()
        growToFitText()
        onTextChange?(textView.string)
    }

    /// 글자가 모양 밖으로 넘치면 왼쪽 위 모서리를 고정한 채 비율을 유지하며 창을 키운다.
    func growToFitText() {
        var steps = 0
        while textView.frame.height > style.textArea.height * (bounds.height - pad * 2), steps < 30 {
            steps += 1
            let f = frame.size, w = f.width * 1.06, h = f.height * 1.06
            if let window {
                let wf = window.frame
                window.setFrame(NSRect(x: wf.minX, y: wf.maxY - h, width: w, height: h), display: true)
            } else {
                setFrameSize(NSSize(width: w, height: h))
            }
        }
    }

    func textDidEndEditing(_ n: Notification) { endEditing() }

    func textView(_ tv: NSTextView, doCommandBy sel: Selector) -> Bool {
        guard sel == #selector(cancelOperation(_:)) else { return false }
        endEditing()
        return true
    }

    // 트랙패드 핀치로 확대/축소
    override func magnify(with event: NSEvent) { (window as? NoteWindow)?.zoom(by: 1 + event.magnification) }

    override func mouseEntered(with event: NSEvent) { hovering = true }
    override func mouseExited(with event: NSEvent) { hovering = false }

    override func menu(for event: NSEvent) -> NSMenu? { App.shared.noteMenu(for: window) }
}
