import Foundation

enum AppLanguage: String, CaseIterable {
    case system, english = "en", portuguese = "pt-BR"

    func resolved(preferences: [String] = Locale.preferredLanguages) -> String {
        if self != .system { return rawValue }
        return Bundle.preferredLocalizations(from: ["en", "pt-BR"], forPreferences: preferences).first ?? "en"
    }
}

struct Localizer {
    let languageCode: String
    private let selected: Bundle
    private let english: Bundle
    private let locale: Locale

    init(language: AppLanguage, bundle: Bundle = .main) {
        let code = language.resolved()
        languageCode = code
        english = bundle.path(forResource: "en", ofType: "lproj").flatMap(Bundle.init(path:)) ?? bundle
        selected = bundle.path(forResource: code, ofType: "lproj").flatMap(Bundle.init(path:)) ?? english
        locale = Locale(identifier: code)
    }

    func text(_ key: String, _ arguments: CVarArg...) -> String {
        format(key, arguments: arguments)
    }

    func format(_ key: String, arguments: [CVarArg]) -> String {
        let translated = selected.localizedString(forKey: key, value: nil, table: nil)
        let template = translated == key ? english.localizedString(forKey: key, value: key, table: nil) : translated
        return arguments.isEmpty ? template : String(format: template, locale: locale, arguments: arguments)
    }

    func displaySummary(count: Int, names: String) -> String {
        text(count == 1 ? "display.one" : "display.other", count, names)
    }
}

struct LocalizedMessage {
    let key: String
    let arguments: [CVarArg]

    init(_ key: String, _ arguments: CVarArg...) {
        self.key = key
        self.arguments = arguments
    }

    func localized(using localizer: Localizer) -> String {
        localizer.format(key, arguments: arguments)
    }
}
