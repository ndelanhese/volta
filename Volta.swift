import AppKit
import SwiftUI
import Combine
@preconcurrency import ApplicationServices
import ServiceManagement

@MainActor
final class VoltaModel: ObservableObject {
    @Published var enabled = UserDefaults.standard.object(forKey: "enabled") as? Bool ?? true
    @Published var accessibility = false
    @Published var recording = false
    @Published var running = false
    @Published var busy = false
    @Published private(set) var language = AppLanguage(rawValue: UserDefaults.standard.string(forKey: "appLanguage") ?? "system") ?? .system
    @Published private var statusMessage = LocalizedMessage("status.permissionRequired")
    @Published var displayNames: [String] = []
    @Published var loginEnabled = SMAppService.mainApp.status == .enabled
    private var engine: Process?
    private var timer: Timer?
    private var logHandle: FileHandle?
    private var lastStatus: Data?
    var localizer: Localizer { Localizer(language: language) }
    var message: String { statusMessage.localized(using: localizer) }

    func text(_ key: String, _ arguments: CVarArg...) -> String {
        localizer.format(key, arguments: arguments)
    }

    func setLanguage(_ language: AppLanguage) {
        UserDefaults.standard.set(language.rawValue, forKey: "appLanguage")
        self.language = language
    }
    let dataURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        .appendingPathComponent("Volta", isDirectory: true)

    var helperURL: URL {
        Bundle.main.bundleURL.appendingPathComponent("Contents/Helpers/spacekeeper")
    }

    init() {
        do {
            try FileManager.default.createDirectory(at: dataURL, withIntermediateDirectories: true,
                                                   attributes: [.posixPermissions: 0o700])
        } catch { statusMessage = LocalizedMessage("status.storageFailure", error.localizedDescription) }
        refresh()
        timer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.refresh() }
        }
    }

    func refresh() {
        accessibility = AXIsProcessTrusted()
        recording = CGPreflightScreenCaptureAccess()
        displayNames = NSScreen.screens.map(\.localizedName)
        loginEnabled = SMAppService.mainApp.status == .enabled
        switch engineAction(enabled: enabled, permitted: accessibility, running: engine?.isRunning == true) {
        case .start: start()
        case .stop: stop()
        case .none: break
        }
        let status: [String: Any] = ["accessibility": accessibility, "screenRecording": recording,
                                    "running": running, "enabled": enabled,
                                    "pid": ProcessInfo.processInfo.processIdentifier,
                                    "helperPid": engine?.processIdentifier ?? 0,
                                    "displays": displayNames.count, "language": localizer.languageCode]
        if let data = try? JSONSerialization.data(withJSONObject: status, options: [.sortedKeys]), data != lastStatus {
            try? data.write(to: dataURL.appendingPathComponent("status.json"), options: .atomic)
            lastStatus = data
        }
    }

    func setEnabled(_ value: Bool) {
        enabled = value
        UserDefaults.standard.set(value, forKey: "enabled")
        refresh()
        if !value { statusMessage = LocalizedMessage("status.paused") }
    }

    private func process(_ args: [String]) -> Process {
        let p = Process()
        p.executableURL = helperURL
        p.arguments = args
        var environment = ProcessInfo.processInfo.environment
        environment["SPACEKEEPER_DATA_DIR"] = dataURL.path
        environment["SPACEKEEPER_PARENT_PID"] = String(ProcessInfo.processInfo.processIdentifier)
        p.environment = environment
        return p
    }

    private func start() {
        let url = dataURL.appendingPathComponent("watch.log")
        do {
            // Keep an older log for diagnosis, bound disk use across launches.
            if let size = try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize, size > 5_000_000 {
                let previous = dataURL.appendingPathComponent("watch-previous.log")
                try? FileManager.default.removeItem(at: previous)
                try FileManager.default.moveItem(at: url, to: previous)
            }
            if !FileManager.default.fileExists(atPath: url.path) {
                FileManager.default.createFile(atPath: url.path, contents: nil,
                                              attributes: [.posixPermissions: 0o600])
            }
            let handle = try FileHandle(forWritingTo: url)
            try handle.seekToEnd()
            let p = process(["watch", "-frames", "-interval", "5s"])
            p.standardOutput = handle
            p.standardError = handle
            p.terminationHandler = { [weak self] child in
                Task { @MainActor in
                    guard let self, self.engine === child else { return }
                    self.engine = nil
                    self.running = false
                    self.enabled = false
                    UserDefaults.standard.set(false, forKey: "enabled")
                    try? self.logHandle?.close()
                    self.logHandle = nil
                    self.statusMessage = LocalizedMessage("status.helperExited", child.terminationStatus)
                }
            }
            try p.run()
            engine = p
            logHandle = handle
            running = true
            statusMessage = LocalizedMessage("status.running")
        } catch {
            enabled = false
            running = false
            statusMessage = LocalizedMessage("status.startFailure", error.localizedDescription)
        }
    }

    func stop() {
        engine?.terminationHandler = nil
        if engine?.isRunning == true { engine?.terminate() }
        engine = nil
        running = false
        try? logHandle?.close()
        logHandle = nil
    }

    func requestAccessibility() {
        let key = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        _ = AXIsProcessTrustedWithOptions([key: true] as CFDictionary)
        openSettings("Privacy_Accessibility")
    }

    func requestRecording() {
        _ = CGRequestScreenCaptureAccess()
        openSettings("Privacy_ScreenCapture")
    }

    func openSettings(_ section: String) {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?\(section)") {
            NSWorkspace.shared.open(url)
        }
    }

    func toggleLogin(_ value: Bool) {
        do {
            if value { try SMAppService.mainApp.register() }
            else { try SMAppService.mainApp.unregister() }
            loginEnabled = SMAppService.mainApp.status == .enabled
            if SMAppService.mainApp.status == .requiresApproval {
                SMAppService.openSystemSettingsLoginItems()
                statusMessage = LocalizedMessage("status.loginApproval")
            }
        } catch { statusMessage = LocalizedMessage("status.loginFailure", error.localizedDescription) }
    }

    @discardableResult
    func command(_ args: [String], successKey: String) async -> Bool {
        guard accessibility, !busy else { return false }
        busy = true
        defer { busy = false }
        let url = dataURL.appendingPathComponent("last-command.log")
        do {
            FileManager.default.createFile(atPath: url.path, contents: Data(),
                                          attributes: [.posixPermissions: 0o600])
            let handle = try FileHandle(forWritingTo: url)
            defer { try? handle.close() }
            let p = process(args)
            p.standardOutput = handle
            p.standardError = handle
            let code: Int32 = try await withCheckedThrowingContinuation { continuation in
                p.terminationHandler = { child in continuation.resume(returning: child.terminationStatus) }
                do { try p.run() } catch { continuation.resume(throwing: error) }
            }
            if code == 0 { statusMessage = LocalizedMessage(successKey); return true }
            statusMessage = LocalizedMessage("status.operationFailure", code)
        } catch { statusMessage = LocalizedMessage("status.error", error.localizedDescription) }
        return false
    }

    func openData() { NSWorkspace.shared.open(dataURL) }
    func openLog() { NSWorkspace.shared.open(dataURL.appendingPathComponent("watch.log")) }
    func openResult() { NSWorkspace.shared.open(dataURL.appendingPathComponent("last-command.log")) }
}

struct ControlView: View {
    @ObservedObject var model: VoltaModel

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 12) {
                Image(systemName: "rectangle.3.group").font(.system(size: 32)).foregroundStyle(.tint)
                VStack(alignment: .leading, spacing: 3) {
                    Text("Volta").font(.largeTitle.bold())
                    Text(model.text("app.tagline")).foregroundStyle(.secondary)
                }
                Spacer()
                Label(model.text(model.running ? "app.active" : "app.paused"), systemImage: model.running ? "checkmark.circle.fill" : "pause.circle")
                    .foregroundStyle(model.running ? Color.green : Color.secondary)
            }

            GroupBox {
                VStack(alignment: .leading, spacing: 12) {
                    permission(model.text("permission.accessibility"), detail: model.text("permission.accessibilityDetail"), granted: model.accessibility,
                               required: true, action: model.requestAccessibility)
                    Divider()
                    permission(model.text("permission.screenRecording"), detail: model.text("permission.screenRecordingDetail"),
                               granted: model.recording, required: false, action: model.requestRecording)
                }.padding(8)
            }

            GroupBox {
                VStack(alignment: .leading, spacing: 12) {
                    Toggle(model.text("automation.toggle"), isOn: Binding(get: { model.enabled }, set: model.setEnabled))
                        .disabled(!model.accessibility || model.busy)
                    Text(model.text("automation.instructions"))
                        .font(.callout).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                    Divider()
                    Label(model.localizer.displaySummary(count: model.displayNames.count, names: model.displayNames.joined(separator: ", ")), systemImage: "display.2")
                        .font(.callout).fixedSize(horizontal: false, vertical: true)
                    HStack {
                        Button(model.text("action.remember")) {
                            Task { await model.command(["remember"], successKey: "status.remembered") }
                        }
                        Button(model.text("action.restore")) {
                            Task { await model.command(["owe"], successKey: "status.restoreRequested") }
                        }.buttonStyle(.borderedProminent).disabled(!model.running)
                        if model.busy { ProgressView().controlSize(.small) }
                    }.disabled(!model.accessibility || model.busy)
                }.padding(8)
            }

            Text(model.message).font(.callout).foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading).fixedSize(horizontal: false, vertical: true)

            HStack {
                Button(model.text("action.data"), action: model.openData)
                Button(model.text("action.history"), action: model.openLog)
                Menu {
                    Button(model.text("action.lastResult"), action: model.openResult)
                    Toggle(model.text("action.launchAtLogin"), isOn: Binding(get: { model.loginEnabled }, set: model.toggleLogin))
                    Divider()
                    Button(model.text("action.quit")) { NSApp.terminate(nil) }
                } label: { Image(systemName: "ellipsis.circle") }
                .menuStyle(.borderlessButton).fixedSize()
                .accessibilityLabel(model.text("menu.more"))
            }
            Picker(model.text("language.label"), selection: Binding(get: { model.language }, set: model.setLanguage)) {
                ForEach(AppLanguage.allCases, id: \.self) { language in
                    Text(model.text("language.\(language.rawValue)")).tag(language)
                }
            }
            Text(model.text("app.footer")).font(.caption).foregroundStyle(.tertiary)
        }
        .padding(24).frame(width: 540)
    }

    func permission(_ title: String, detail: String, granted: Bool, required: Bool, action: @escaping () -> Void) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: granted ? "checkmark.circle.fill" : (required ? "lock.circle" : "info.circle"))
                .foregroundStyle(granted ? Color.green : Color.secondary).font(.title3)
            VStack(alignment: .leading, spacing: 3) {
                Text(title).fontWeight(.medium)
                Text(detail).font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
            Button(model.text(granted ? "action.settings" : "action.authorize"), action: action)
        }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var model: VoltaModel!
    private var statusItem: NSStatusItem!
    private var window: NSWindow!
    private var languageObserver: AnyCancellable?

    func applicationDidFinishLaunching(_ notification: Notification) {
        if NSRunningApplication.runningApplications(withBundleIdentifier: "local.volta.app").count > 1 {
            NSApp.terminate(nil)
            return
        }
        NSApp.setActivationPolicy(.accessory)
        model = VoltaModel()
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem.button?.target = self
        statusItem.button?.action = #selector(showControls)
        window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 540, height: 640), styleMask: [.titled, .closable, .miniaturizable], backing: .buffered, defer: false)
        window.title = "Volta"
        window.isReleasedWhenClosed = false
        let content = NSHostingView(rootView: ControlView(model: model))
        window.contentView = content
        window.setContentSize(content.fittingSize)
        window.center()
        languageObserver = model.$language.sink { [weak self] language in
            guard let self else { return }
            let strings = Localizer(language: language)
            self.statusItem.button?.image = NSImage(systemSymbolName: "rectangle.3.group", accessibilityDescription: strings.text("app.menuAccessibility"))
            self.statusItem.button?.image?.isTemplate = true
            self.statusItem.button?.toolTip = strings.text("app.tooltip")
            Task { @MainActor [weak self] in
                guard let self, let content = self.window.contentView else { return }
                content.layoutSubtreeIfNeeded()
                self.window.setContentSize(content.fittingSize)
            }
        }
        if !model.accessibility || !UserDefaults.standard.bool(forKey: "hasLaunched") { showControls() }
        UserDefaults.standard.set(true, forKey: "hasLaunched")
    }

    @objc func showControls() {
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        showControls()
        return true
    }

    func applicationWillTerminate(_ notification: Notification) { model?.stop() }
}

@main
struct VoltaApp {
    @MainActor static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        withExtendedLifetime(delegate) { app.run() }
    }
}
