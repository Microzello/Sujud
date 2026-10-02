//
//  SettingsView.swift
//  Sujud
//
//  macOS has no Settings app for third-party apps, so the calculation
//  settings live in the standard Settings window (Sujud ▸ Settings…).
//

#if os(macOS)
import SwiftUI

struct SettingsView: View {
    @AppStorage(Preferences.methodKey, store: Preferences.store)
    private var method = CalculationMethod.default.rawValue

    @AppStorage(Preferences.asrKey, store: Preferences.store)
    private var asr = AsrMethod.default.rawValue

    var body: some View {
        Form {
            Section {
                Picker("Calculation Method", selection: $method) {
                    ForEach(CalculationMethod.allCases) { method in
                        Text(method.localizedName).tag(method.rawValue)
                    }
                }
                Picker("Asr Method", selection: $asr) {
                    ForEach(AsrMethod.allCases) { asr in
                        Text(asr.localizedName).tag(asr.rawValue)
                    }
                }
                .pickerStyle(.radioGroup)
            }
        }
        .formStyle(.grouped)
        .frame(width: 460)
        .fixedSize(horizontal: false, vertical: true)
    }
}
#endif
