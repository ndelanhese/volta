import Foundation

func runLocalizationChecks() throws {
    precondition(AppLanguage.system.resolved(preferences: ["pt-BR"]) == "pt-BR", "System Portuguese must select Portuguese")
    precondition(AppLanguage.system.resolved(preferences: ["en-GB"]) == "en")
    precondition(AppLanguage.system.resolved(preferences: ["pt-PT"]) == "pt-BR")
    precondition(AppLanguage.system.resolved(preferences: ["fr-FR"]) == "en")
    precondition(AppLanguage.system.resolved(preferences: ["fr", "pt-BR", "en"]) == "pt-BR")
    precondition(AppLanguage.english.resolved(preferences: ["pt-BR"]) == "en")
    precondition(AppLanguage.portuguese.resolved(preferences: ["en-US"]) == "pt-BR")

    let bundle = try requireBundle(CommandLine.arguments[1])
    let en = Localizer(language: .english, bundle: bundle)
    let pt = Localizer(language: .portuguese, bundle: bundle)
    precondition(en.text("action.remember") == "Remember now")
    precondition(pt.text("action.remember") == "Memorizar agora")
    precondition(en.text("status.helperExited", Int32(7)).contains("7"))
    precondition(pt.text("status.storageFailure", "EXAMPLE").contains("EXAMPLE"))
    let message = LocalizedMessage("status.helperExited", Int32(7))
    precondition(message.localized(using: en).hasPrefix("Engine stopped"))
    precondition(message.localized(using: pt).hasPrefix("Motor parou"), "Existing status messages must retranslate after switching languages")
    for (count, english, portuguese) in [(0, "0 displays: Test", "0 telas: Test"),
                                       (1, "1 display: Test", "1 tela: Test"),
                                       (2, "2 displays: Test", "2 telas: Test")] {
        precondition(en.displaySummary(count: count, names: "Test") == english)
        precondition(pt.displaySummary(count: count, names: "Test") == portuguese)
    }

    let english = try strings(in: bundle, language: "en")
    let portuguese = try strings(in: bundle, language: "pt-BR")
    precondition(Set(english.keys) == Set(portuguese.keys), "Every locale must translate every UI key")
    let formats = try NSRegularExpression(pattern: "%[0-9$]*[ld@]+")
    for key in english.keys {
        let a = english[key]!, b = portuguese[key]!
        func placeholders(_ value: String) -> [String] {
            formats.matches(in: value, range: NSRange(value.startIndex..., in: value)).map {
                (value as NSString).substring(with: $0.range)
            }
        }
        precondition(!a.isEmpty && !b.isEmpty && placeholders(a) == placeholders(b), "Translation placeholders differ: \(key)")
        precondition(en.text(key) != key && pt.text(key) != key, "Unresolved translation: \(key)")
    }

    let temp = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".bundle")
    defer { try? FileManager.default.removeItem(at: temp) }
    let dir = temp.appendingPathComponent("en.lproj")
    try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    try "\"fixture.fallback\" = \"English fallback\";".write(to: dir.appendingPathComponent("Localizable.strings"), atomically: true, encoding: .utf8)
    let ptDir = temp.appendingPathComponent("pt-BR.lproj")
    try FileManager.default.createDirectory(at: ptDir, withIntermediateDirectories: true)
    try "\"fixture.other\" = \"Outra tradução\";".write(to: ptDir.appendingPathComponent("Localizable.strings"), atomically: true, encoding: .utf8)
    let fallback = Localizer(language: .portuguese, bundle: try requireBundle(temp.path))
    precondition(fallback.text("fixture.fallback") == "English fallback", "A missing key in an existing locale must fall back to English")
    print("Localization checks passed: locale negotiation, explicit overrides, native resources, fallback, plurals, and \(english.count) translated keys")
}

private func requireBundle(_ path: String) throws -> Bundle {
    guard let bundle = Bundle(path: path) else { throw CocoaError(.fileReadCorruptFile) }
    return bundle
}

private func strings(in bundle: Bundle, language: String) throws -> [String: String] {
    let url = (bundle.resourceURL ?? bundle.bundleURL).appendingPathComponent("\(language).lproj/Localizable.strings")
    return try PropertyListSerialization.propertyList(from: Data(contentsOf: url), format: nil) as! [String: String]
}
