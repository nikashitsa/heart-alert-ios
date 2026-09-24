import Foundation
import ObjectiveC

/// Languages the UI is translated into, mirroring the Android app's `AppLanguage`. Each needs a
/// matching `<tag>.lproj` in the bundle, which `Localizable.xcstrings` and `Sounds/` provide.
/// `tag` is the lproj name that gets saved, `code` the two letters on the language button, and
/// `displayName` the language's own name for itself, so it is recognizable whatever the UI is in.
enum AppLanguage: String, CaseIterable, Identifiable {
    case cs, de, en, es, fi, fr, hi, hu, id, it, ja, ko, nb, nl, pl
    case ptBR = "pt-BR"
    case ptPT = "pt-PT"
    case ru, sl, sv, th, tr, uk
    case zhHans = "zh-Hans"

    static let defaultLanguage = AppLanguage.en

    var id: String { rawValue }
    var tag: String { rawValue }

    var code: String {
        switch self {
        // Both are "PT"; the country code is what tells them apart on the button.
        case .ptBR: return "BR"
        case .ptPT: return "PT"
        case .nb: return "NO"
        case .zhHans: return "ZH"
        default: return rawValue.uppercased()
        }
    }

    var displayName: String {
        switch self {
        case .cs: return "Čeština"
        case .de: return "Deutsch"
        case .en: return "English"
        case .es: return "Español"
        case .fi: return "Suomi"
        case .fr: return "Français"
        case .hi: return "हिन्दी"
        case .hu: return "Magyar"
        case .id: return "Bahasa Indonesia"
        case .it: return "Italiano"
        case .ja: return "日本語"
        case .ko: return "한국어"
        case .nb: return "Norsk bokmål"
        case .nl: return "Nederlands"
        case .pl: return "Polski"
        case .ptBR: return "Português (Brasil)"
        case .ptPT: return "Português (Portugal)"
        case .ru: return "Русский"
        case .sl: return "Slovenščina"
        case .sv: return "Svenska"
        case .th: return "ไทย"
        case .tr: return "Türkçe"
        case .uk: return "Українська"
        case .zhHans: return "简体中文"
        }
    }

    var locale: Locale { Locale(identifier: tag) }

    /// Sorted by name, the order the language menu lists them in. Locale-aware rather than
    /// plain string order, so "Čeština" sorts under C instead of after every Latin name.
    static let sorted: [AppLanguage] = allCases.sorted {
        $0.displayName.compare($1.displayName, locale: Locale(identifier: "en")) == .orderedAscending
    }

    static func fromTag(_ tag: String?) -> AppLanguage? {
        guard let tag else { return nil }
        return AppLanguage(rawValue: tag)
    }

    /// The language the UI is in: the user's pick, else the localization iOS chose from the
    /// device languages (which already honors the system per-app language setting), else
    /// English. So the button always names the language actually shown.
    static func resolve(saved: String?) -> AppLanguage {
        fromTag(saved) ?? fromTag(Bundle.main.preferredLocalizations.first) ?? defaultLanguage
    }

    /// UserDefaults key of the user's pick. Absent until the user picks one, so a device
    /// language change still applies.
    static let defaultsKey = "language"

    /// The saved pick, read without constructing `Settings`, for `MainApp.init()`.
    static var saved: String? { UserDefaults.standard.string(forKey: defaultsKey) }
}

extension Bundle {
    /// Sends every localized string lookup on the main bundle — SwiftUI `Text`,
    /// `String(localized:)`, `NSLocalizedString` — to `language`'s lproj. Nil restores the
    /// lookup iOS does by default.
    static func setLanguage(_ language: AppLanguage?) {
        if !(Bundle.main is LanguageBundle) {
            object_setClass(Bundle.main, LanguageBundle.self)
        }
        LanguageBundle.override = language
            .flatMap { Bundle.main.path(forResource: $0.tag, ofType: "lproj") }
            .flatMap(Bundle.init(path:))
    }

    /// The lproj bundle of the language in effect, for resources other than strings.
    static func localized(_ language: AppLanguage) -> Bundle? {
        Bundle.main.path(forResource: language.tag, ofType: "lproj").flatMap(Bundle.init(path:))
    }
}

private final class LanguageBundle: Bundle, @unchecked Sendable {
    static var override: Bundle?

    override func localizedString(forKey key: String, value: String?, table tableName: String?) -> String {
        if let override = LanguageBundle.override {
            return override.localizedString(forKey: key, value: value, table: tableName)
        }
        return super.localizedString(forKey: key, value: value, table: tableName)
    }
}
