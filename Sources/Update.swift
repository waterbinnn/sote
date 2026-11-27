import AppKit

/// GitHub 최신 릴리스를 확인하고, 새 버전이 있으면 내려받아 지금 앱과 바꿔 끼운 뒤 다시 연다.
extension App {
    private static let repo = "waterbinnn/sote"
    private static let installCommand = "curl -fsSL https://raw.githubusercontent.com/waterbinnn/sote/main/install.sh | sh"
    private static var checking = false

    private struct UpdateError: LocalizedError {
        let errorDescription: String?
        init(_ message: String) { errorDescription = message }
    }

    @objc func checkForUpdates(_ sender: Any?) {
        guard !Self.checking else { return }
        Self.checking = true
        Task { @MainActor in
            defer { Self.checking = false }
            do {
                try await update()
            } catch {
                alert("Couldn't update Sote.", "\(error.localizedDescription)\n\nYou can also update by running this command in Terminal:\n\(Self.installCommand)")
            }
        }
    }

    @MainActor private func update() async throws {
        let current = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0"
        // releases/latest 는 .../releases/tag/v1.2.0 으로 리다이렉트된다.
        // GitHub API 는 IP당 시간당 60회 제한이 있어서(회사망에서 금방 막힌다) 웹 주소를 쓴다.
        var request = URLRequest(url: URL(string: "https://github.com/\(Self.repo)/releases/latest")!)
        request.httpMethod = "HEAD"
        let (_, response) = try await URLSession.shared.data(for: request)
        guard let final = response.url, final.deletingLastPathComponent().lastPathComponent == "tag" else {
            throw UpdateError("Couldn't read the latest version info.")
        }
        let tag = final.lastPathComponent
        let latest = tag.hasPrefix("v") ? String(tag.dropFirst()) : tag
        guard latest.compare(current, options: .numeric) == .orderedDescending else {
            alert("You're up to date.", "Current version: \(current)")
            return
        }
        guard alert("Sote \(latest) is available.",
                    "You have \(current). Sote will quit and reopen during the update. Your notes will be kept.",
                    buttons: ["Update", "Later"]) else { return }

        // 개발 빌드나, 다운로드 폴더에서 바로 연 앱(App Translocation)은 바꿔 끼울 수 없다.
        let app = Bundle.main.bundleURL
        guard app.pathExtension == "app", FileManager.default.isWritableFile(atPath: app.deletingLastPathComponent().path) else {
            throw UpdateError("Can't replace the app at \(app.path). Move Sote to the Applications folder and try again.")
        }

        // 개발용: SOTE_UPDATE_ZIP 으로 내려받을 zip 을 바꿔서 업데이트 과정을 시험한다.
        let zip = ProcessInfo.processInfo.environment["SOTE_UPDATE_ZIP"].flatMap(URL.init(string:))
            ?? URL(string: "https://github.com/\(Self.repo)/releases/download/\(tag)/Sote.zip")!
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("SoteUpdate-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let file = dir.appendingPathComponent("Sote.zip")
        try await fetch(zip).write(to: file)
        try run("/usr/bin/ditto", "-x", "-k", file.path, dir.path)
        let new = dir.appendingPathComponent("Sote.app")
        guard FileManager.default.fileExists(atPath: new.path) else { throw UpdateError("The download doesn't contain Sote.app.") }

        // 앱이 완전히 종료된 뒤에 바꿔 끼우고 다시 연다. 복사가 끝나기 전에는 기존 앱을 지우지 않는다.
        let script = """
        while kill -0 "$1" 2>/dev/null; do sleep 0.2; done
        rm -rf "$3.new" && ditto "$2" "$3.new" && rm -rf "$3" && mv "$3.new" "$3"
        open "$3"
        rm -rf "$4"
        """
        let helper = Process()
        helper.executableURL = URL(fileURLWithPath: "/bin/sh")
        helper.arguments = ["-c", script, "sh", "\(getpid())", new.path, app.path, dir.path]
        try helper.run()
        NSApp.terminate(nil)
    }

    private func fetch(_ url: URL) async throws -> Data {
        let (data, response) = try await URLSession.shared.data(from: url)
        if let http = response as? HTTPURLResponse, http.statusCode != 200 {
            throw UpdateError("Server error (\(http.statusCode)). Please try again later.")
        }
        return data
    }

    private func run(_ path: String, _ args: String...) throws {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: path)
        p.arguments = args
        try p.run()
        p.waitUntilExit()
        guard p.terminationStatus == 0 else { throw UpdateError("Couldn't unzip the download.") }
    }

    @MainActor @discardableResult
    private func alert(_ title: String, _ text: String, buttons: [String] = ["OK"]) -> Bool {
        NSApp.activate()
        let a = NSAlert()
        a.messageText = title
        a.informativeText = text
        buttons.forEach { a.addButton(withTitle: $0) }
        return a.runModal() == .alertFirstButtonReturn
    }
}
