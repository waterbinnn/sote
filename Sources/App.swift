import AppKit

final class App: NSObject, NSApplicationDelegate {
    static let shared = App()
    private let key = "notes"
    private(set) var notes: [NoteWindow] = []
    private var statusItem: NSStatusItem?
    var lastOnTop: Bool {
        get { UserDefaults.standard.object(forKey: "lastOnTop") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "lastOnTop") }
    }

    func applicationDidFinishLaunching(_ n: Notification) {
        NSApp.mainMenu = mainMenu()
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        item.button?.image = statusIcon()
        item.menu = statusMenu()
        statusItem = item
        let saved = UserDefaults.standard.data(forKey: key).flatMap { try? JSONDecoder().decode([NoteData].self, from: $0) } ?? []
        saved.forEach { show(NoteWindow($0)) }
        if notes.isEmpty { newNote(nil) }
        NSApp.activate()
    }

    // 앱이 활성화되면(메모 클릭, Dock 클릭, ⌘Tab) 고정하지 않은 메모도 모두 앞으로 가져온다.
    func applicationDidBecomeActive(_ n: Notification) {
        let key = NSApp.keyWindow
        notes.forEach { $0.orderFront(nil) }
        key?.orderFront(nil)
    }

    func applicationShouldHandleReopen(_ app: NSApplication, hasVisibleWindows: Bool) -> Bool {
        if notes.isEmpty { newNote(nil) }
        return true
    }

    func applicationDockMenu(_ sender: NSApplication) -> NSMenu? {
        let menu = NSMenu()
        menu.addItem(stylesItem("New Note", action: #selector(newNoteWithStyle(_:)), target: self))
        return menu
    }

    func applicationWillTerminate(_ n: Notification) { save() }

    func save() {
        UserDefaults.standard.set(try? JSONEncoder().encode(notes.map(\.data)), forKey: key)
    }

    private func show(_ note: NoteWindow) {
        notes.append(note)
        note.makeKeyAndOrderFront(nil)
    }

    func remove(_ note: NoteWindow) {
        notes.removeAll { $0 === note }
        note.close()
        save()
    }

    private func add(_ style: Style) {
        let screen = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        let offset = CGFloat(notes.count % 8) * 28
        let size = style.defaultSize
        let frame = NSRect(x: screen.midX - size.width / 2 + offset, y: screen.midY - size.height / 2 - offset,
                           width: size.width, height: size.height)
        let note = NoteWindow(NoteData(style: style, frame: frame, onTop: lastOnTop))
        show(note)
        save()
        NSApp.activate()
        note.noteView.beginEditing()
    }

    @objc func newNote(_ sender: Any?) {
        // 새 메모마다 다음 모양을 돌아가며 쓴다.
        let last = notes.last?.data.style
        let all = Style.allCases
        add(last.map { all[(all.firstIndex(of: $0)! + 1) % all.count] } ?? .cloud)
    }

    @objc func newNoteWithStyle(_ sender: NSMenuItem) {
        add(Style(rawValue: sender.representedObject as? String ?? "") ?? .cloud)
    }

    @objc func bringAllToFront(_ sender: Any?) {
        NSApp.activate()
        notes.forEach { $0.orderFront(nil) }
    }

    // MARK: - Menus

    private func stylesItem(_ title: String, action: Selector, target: AnyObject?) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        let sub = NSMenu()
        for style in Style.allCases {
            let i = sub.addItem(withTitle: style.title, action: action, keyEquivalent: "")
            i.image = preview(style, fit: NSSize(width: 48, height: 30))
            i.representedObject = style.rawValue
            i.target = target
        }
        item.submenu = sub
        return item
    }

    /// 메뉴바 아이콘 메뉴: 미리보기를 보고 골라서 새 메모를 만든다.
    private func statusMenu() -> NSMenu {
        let menu = NSMenu()
        menu.addItem(.sectionHeader(title: "New Note"))
        let picker = NSMenuItem()
        picker.view = StylePicker { [unowned self] style in
            // 메뉴가 닫힌 뒤에 만들어야 새 메모가 바로 입력 상태가 된다.
            DispatchQueue.main.async { self.add(style) }
        }
        menu.addItem(picker)
        menu.addItem(.separator())
        menu.addItem(withTitle: "Bring All Notes to Front", action: #selector(bringAllToFront(_:)), keyEquivalent: "").target = self
        menu.addItem(.separator())
        menu.addItem(withTitle: "Check for Updates…", action: #selector(checkForUpdates(_:)), keyEquivalent: "").target = self
        menu.addItem(withTitle: "Quit Sote", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        return menu
    }

    /// 글자 크기·굵기·정렬 하위 메뉴.
    private func textItems(target: AnyObject?) -> [NSMenuItem] {
        let size = NSMenuItem(title: "Font Size", action: nil, keyEquivalent: "")
        size.submenu = NSMenu()
        for pt in fontSizes {
            let i = size.submenu!.addItem(withTitle: "\(Int(pt))pt", action: #selector(NoteWindow.changeFontSize(_:)), keyEquivalent: "")
            i.representedObject = pt
            i.target = target
        }
        let weight = NSMenuItem(title: "Font Weight", action: nil, keyEquivalent: "")
        weight.submenu = NSMenu()
        for w in Weight.allCases {
            let i = weight.submenu!.addItem(withTitle: w.title, action: #selector(NoteWindow.changeWeight(_:)), keyEquivalent: "")
            i.attributedTitle = NSAttributedString(string: w.title, attributes: [.font: w.font(size: 13)])
            i.representedObject = w.rawValue
            i.target = target
        }
        let align = NSMenuItem(title: "Alignment", action: nil, keyEquivalent: "")
        align.submenu = NSMenu()
        for a in Align.allCases {
            let i = align.submenu!.addItem(withTitle: a.title, action: #selector(NoteWindow.changeAlign(_:)), keyEquivalent: "")
            i.representedObject = a.rawValue
            i.target = target
        }
        return [size, weight, align]
    }

    private func colorsItem(target: AnyObject?) -> NSMenuItem {
        let item = NSMenuItem(title: "Color", action: nil, keyEquivalent: "")
        let sub = NSMenu()
        let reset = sub.addItem(withTitle: "Default Color", action: #selector(NoteWindow.changeColor(_:)), keyEquivalent: "")
        reset.target = target
        sub.addItem(.separator())
        for (name, hex) in palette {
            let i = sub.addItem(withTitle: name, action: #selector(NoteWindow.changeColor(_:)), keyEquivalent: "")
            i.representedObject = hex
            i.target = target
            i.image = NSImage(size: NSSize(width: 16, height: 16), flipped: false) { r in
                let dot = NSBezierPath(ovalIn: r.insetBy(dx: 1, dy: 1))
                NSColor(hex: hex).setFill()
                dot.fill()
                NSColor.black.withAlphaComponent(0.3).setStroke()
                dot.stroke()
                return true
            }
        }
        item.submenu = sub
        return item
    }

    func noteMenu(for window: NSWindow?) -> NSMenu {
        let menu = NSMenu()
        menu.addItem(stylesItem("Shape", action: #selector(NoteWindow.changeStyle(_:)), target: window))
        menu.addItem(colorsItem(target: window))
        textItems(target: window).forEach(menu.addItem)
        menu.addItem(withTitle: "Always on Top", action: #selector(NoteWindow.toggleOnTop(_:)), keyEquivalent: "").target = window
        menu.addItem(.separator())
        menu.addItem(stylesItem("New Note", action: #selector(newNoteWithStyle(_:)), target: self))
        menu.addItem(withTitle: "Delete Note", action: #selector(NoteWindow.deleteNote(_:)), keyEquivalent: "").target = window
        return menu
    }

    private func mainMenu() -> NSMenu {
        let main = NSMenu()
        func submenu(_ title: String, _ items: [NSMenuItem]) {
            let menu = NSMenu(title: title)
            items.forEach(menu.addItem)
            main.addItem(withTitle: title, action: nil, keyEquivalent: "").submenu = menu
        }
        func item(_ title: String, _ action: String, _ key: String, _ mods: NSEvent.ModifierFlags = .command) -> NSMenuItem {
            let i = NSMenuItem(title: title, action: Selector(action), keyEquivalent: key)
            i.keyEquivalentModifierMask = mods
            return i
        }

        let update = item("Check for Updates…", "checkForUpdates:", "")
        update.target = self
        submenu("Sote", [update, .separator(), item("Quit Sote", "terminate:", "q")])
        let new = item("New Note", "newNote:", "n")
        new.target = self
        submenu("Note", [
            new,
            stylesItem("New Note with Shape", action: #selector(newNoteWithStyle(_:)), target: self),
            .separator(),
            stylesItem("Change Shape", action: #selector(NoteWindow.changeStyle(_:)), target: nil),
            colorsItem(target: nil),
        ] + textItems(target: nil) + [
            item("Always on Top", "toggleOnTop:", "t"),
            .separator(),
            item("Delete Note", "deleteNote:", ""),
        ])
        submenu("Edit", [
            item("Undo", "undo:", "z"),
            item("Redo", "redo:", "z", [.command, .shift]),
            .separator(),
            item("Cut", "cut:", "x"),
            item("Copy", "copy:", "c"),
            item("Paste", "paste:", "v"),
            item("Select All", "selectAll:", "a"),
        ])
        return main
    }
}
