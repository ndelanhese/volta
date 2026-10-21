# Localization

Volta ships English (`en`) and Brazilian Portuguese (`pt-BR`). Its own language setting defaults to
**Follow macOS** and is persisted as `appLanguage` in the app's UserDefaults domain.

`Localization.swift` selects the native `.lproj` bundle and falls back to the English table when a key
or locale is unavailable. Status messages retain keys and format arguments so changing language also
translates messages already on screen. Both supported languages use singular for one display and
plural for all other integer counts; these variants live in the resource tables.

## Resource tables

- `Resources/<locale>.lproj/Localizable.strings`: interface, controls, menus, tooltips, accessibility,
  and status/error prefixes.
- `Resources/<locale>.lproj/InfoPlist.strings`: descriptions for system permission dialogs.

Native permission dialogs use macOS/per-app system language preferences. The in-app selector changes
Volta's own UI immediately; it does not change the OS language. Technical helper logs are English.
Error details returned by system APIs retain the language provided by macOS.

## Add a language

1. Copy both tables into a new `<locale>.lproj` directory and translate every value.
2. Preserve format arguments (`%@`, `%d`, `%ld`) in the same order and escape quotes correctly.
3. Add the locale to `AppLanguage`, provide its native display name in all UI tables, and add it to
   `CFBundleLocalizations` in `Info.plist`.
4. Include it in system-language negotiation and extend the localization tests. If its plural rules
   differ from English/Portuguese, extend plural selection before claiming support.
5. Run `./test.sh`, `./build.sh`, then check layouts and live switching in the built app.

Tests cover language negotiation, explicit choices, English fallback for a missing translation,
zero/one/many displays, existing-message retranslation, equal UI key sets, and matching placeholders.
