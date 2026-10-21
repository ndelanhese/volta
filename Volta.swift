import AppKit
import SwiftUI
@preconcurrency import ApplicationServices
import ServiceManagement

@MainActor
final class VoltaModel: ObservableObject {
    @Published var enabled = UserDefaults.standard.object(forKey: "enabled") as? Bool ?? true
    @Published var accessibility = false
    @Published var recording = false
    @Published var running = false
    @Published var busy = false
    @Published var message = "Autorize Acessibilidade para começar."
    @Published var displayNames: [String] = []
    @Published var loginEnabled = SMAppService.mainApp.status == .enabled
    private var engine: Process?
    private var timer: Timer?
    private var logHandle: FileHandle?
    private var lastStatus: Data?
    let dataURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        .appendingPathComponent("Volta", isDirectory: true)

    var helperURL: URL {
        Bundle.main.bundleURL.appendingPathComponent("Contents/Helpers/spacekeeper")
    }

    init() {
        do {
            try FileManager.default.createDirectory(at: dataURL, withIntermediateDirectories: true,
                                                   attributes: [.posixPermissions: 0o700])
        } catch { message = "Não foi possível criar dados locais: \(error.localizedDescription)" }
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
                                    "displays": displayNames.count]
        if let data = try? JSONSerialization.data(withJSONObject: status, options: [.sortedKeys]), data != lastStatus {
            try? data.write(to: dataURL.appendingPathComponent("status.json"), options: .atomic)
            lastStatus = data
        }
    }

    func setEnabled(_ value: Bool) {
        enabled = value
        UserDefaults.standard.set(value, forKey: "enabled")
        refresh()
        if !value { message = "Pausado. Janelas ficam como você deixar." }
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
                    self.message = "Motor parou (código \(child.terminationStatus)). Consulte histórico e reative."
                }
            }
            try p.run()
            engine = p
            logHandle = handle
            running = true
            message = "Ativo. Organização aprendida a cada 5 segundos."
        } catch {
            enabled = false
            running = false
            message = "Falha ao iniciar: \(error.localizedDescription)"
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
                message = "Autorize Volta nos Itens de Início."
            }
        } catch { message = "Início de sessão: \(error.localizedDescription)" }
    }

    @discardableResult
    func command(_ args: [String], success: String) async -> Bool {
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
            if code == 0 { message = success; return true }
            message = "Operação falhou (\(code)). Abra último resultado para detalhes."
        } catch { message = error.localizedDescription }
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
                    Text("Cada tela. Cada janela. No seu lugar.").foregroundStyle(.secondary)
                }
                Spacer()
                Label(model.running ? "Ativo" : "Pausado", systemImage: model.running ? "checkmark.circle.fill" : "pause.circle")
                    .foregroundStyle(model.running ? Color.green : Color.secondary)
            }

            GroupBox {
                VStack(alignment: .leading, spacing: 12) {
                    permission("Acessibilidade", detail: "Mover e redimensionar janelas.", granted: model.accessibility,
                               required: true, action: model.requestAccessibility)
                    Divider()
                    permission("Gravação da tela", detail: "Opcional: identificar títulos nas outras mesas. Nenhuma imagem é gravada.",
                               granted: model.recording, required: false, action: model.requestRecording)
                }.padding(8)
            }

            GroupBox {
                VStack(alignment: .leading, spacing: 12) {
                    Toggle("Restaurar ao conectar ou desconectar telas", isOn: Binding(get: { model.enabled }, set: model.setEnabled))
                        .disabled(!model.accessibility || model.busy)
                    Text("Organize uma vez em cada configuração. Aguarde 5 segundos antes de desconectar. Após mudar telas, Volta espera 10 segundos de estabilidade para restaurar.")
                        .font(.callout).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                    Divider()
                    Label("\(model.displayNames.count) tela(s): \(model.displayNames.joined(separator: ", "))", systemImage: "display.2")
                        .font(.callout).fixedSize(horizontal: false, vertical: true)
                    HStack {
                        Button("Memorizar agora") {
                            Task { await model.command(["remember"], success: "Organização memorizada e recuperação salva neste Mac.") }
                        }
                        Button("Restaurar organização") {
                            Task { await model.command(["owe"], success: "Restauração solicitada. Aguarde até 5 segundos.") }
                        }.buttonStyle(.borderedProminent).disabled(!model.running)
                        if model.busy { ProgressView().controlSize(.small) }
                    }.disabled(!model.accessibility || model.busy)
                }.padding(8)
            }

            Text(model.message).font(.callout).foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading).fixedSize(horizontal: false, vertical: true)

            HStack {
                Button("Dados locais", action: model.openData)
                Button("Histórico", action: model.openLog)
                Menu {
                    Button("Último resultado", action: model.openResult)
                    Toggle("Abrir ao iniciar sessão", isOn: Binding(get: { model.loginEnabled }, set: model.toggleLogin))
                    Divider()
                    Button("Sair do Volta") { NSApp.terminate(nil) }
                } label: { Image(systemName: "ellipsis.circle") }
                .menuStyle(.borderlessButton).fixedSize()
            }
            Text("Gratuito · Local · Sem conta ou assinatura").font(.caption).foregroundStyle(.tertiary)
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
            Button(granted ? "Ajustes" : "Autorizar", action: action)
        }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var model: VoltaModel!
    private var statusItem: NSStatusItem!
    private var window: NSWindow!

    func applicationDidFinishLaunching(_ notification: Notification) {
        if NSRunningApplication.runningApplications(withBundleIdentifier: "local.volta.app").count > 1 {
            NSApp.terminate(nil)
            return
        }
        NSApp.setActivationPolicy(.accessory)
        model = VoltaModel()
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem.button?.image = NSImage(systemSymbolName: "rectangle.3.group", accessibilityDescription: "Volta — organização de janelas")
        statusItem.button?.image?.isTemplate = true
        statusItem.button?.target = self
        statusItem.button?.action = #selector(showControls)
        statusItem.button?.toolTip = "Volta — restaurar janelas e Spaces"
        window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 540, height: 640), styleMask: [.titled, .closable, .miniaturizable], backing: .buffered, defer: false)
        window.title = "Volta"
        window.isReleasedWhenClosed = false
        let content = NSHostingView(rootView: ControlView(model: model))
        window.contentView = content
        window.setContentSize(content.fittingSize)
        window.center()
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
