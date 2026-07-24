//
//  AppleIntelligenceStatus.swift
//  UpDish
//
//  Single source of truth for whether the on-device model can be used, and
//  whether it's worth telling the user about it.
//
//  There is no API to turn Apple Intelligence on, and no permission prompt to
//  request it — it is a device-wide Setting the user controls. All an app can
//  do is read the state and explain where the switch lives.
//

import SwiftUI

#if canImport(FoundationModels)
import FoundationModels
#endif

/// The availability states we actually treat differently in the UI.
///
/// `SystemLanguageModel` reports three unavailable reasons and they are NOT
/// interchangeable: only one of them is something the user can fix, so only
/// that one is worth prompting about.
enum AppleIntelligenceStatus: Equatable {
    /// The model is usable — no notice, no prompt.
    case ready

    /// Apple Intelligence is switched off. The only actionable state, and the
    /// only one we ever ask the user to do something about.
    case notEnabled

    /// Already switched on; the model is still downloading or is waiting on
    /// network/battery. Nothing to enable — telling them to turn it on here
    /// would be wrong, so we only say it's being prepared.
    case preparing

    /// The hardware doesn't support Apple Intelligence, or the OS is too old.
    /// The user cannot act on this, so we stay silent rather than nag forever.
    case unsupported

    /// Reads the live state. Cheap, so it can be called on demand.
    static var current: AppleIntelligenceStatus {
        #if DEBUG
        if let forced = debugOverride { return forced }
        #endif

        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            switch SystemLanguageModel.default.availability {
            case .available:
                return .ready
            case .unavailable(.appleIntelligenceNotEnabled):
                return .notEnabled
            case .unavailable(.modelNotReady):
                return .preparing
            case .unavailable(.deviceNotEligible):
                return .unsupported
            case .unavailable:
                // Any reason added in a future OS: treat as not actionable.
                return .unsupported
            }
        }
        #endif
        return .unsupported
    }

    #if DEBUG
    /// Forces a state so the notices can be exercised where the real one can't
    /// be reproduced — the Simulator inherits the Mac's Apple Intelligence and
    /// usually reports `.available`, which hides all of this UI.
    ///
    /// Set it with a launch argument in the scheme's Run › Arguments:
    ///     -UpDishForceAIStatus notEnabled
    ///
    /// Accepts: ready | notEnabled | preparing | unsupported.
    /// Compiled out of release builds entirely.
    private static var debugOverride: AppleIntelligenceStatus? {
        switch UserDefaults.standard.string(forKey: "UpDishForceAIStatus") {
        case "ready": return .ready
        case "notEnabled": return .notEnabled
        case "preparing": return .preparing
        case "unsupported": return .unsupported
        default: return nil
        }
    }
    #endif

    /// Whether to interrupt the user with an alert. Deliberately narrow — an
    /// alert is only justified when there is a switch they can go and flip.
    var deservesPrompt: Bool { self == .notEnabled }

    /// Whether to show the passive notice on the Home screen. Wider than
    /// `deservesPrompt`, because "sedang disiapkan" is useful context even
    /// though there's nothing to tap.
    var deservesHomeNotice: Bool { self == .notEnabled || self == .preparing }

    // MARK: - Copy

    var noticeText: String {
        switch self {
        case .notEnabled:
            "Aktifkan Apple Intelligence untuk masukan yang lebih personal."
        case .preparing:
            "Apple Intelligence sedang disiapkan. Masukan personal akan aktif sebentar lagi."
        case .ready, .unsupported:
            ""
        }
    }

    var noticeIcon: String {
        self == .preparing ? "arrow.down.circle" : "sparkles"
    }

    var alertTitle: String { "Aktifkan Apple Intelligence" }

    /// Spells out the route step by step, including backing out of UpDish's own
    /// page. `openSettings()` can only land the user there — it is NOT the
    /// Apple Intelligence pane and has no switch on it — so without these steps
    /// the user arrives somewhere that looks like the right place but isn't.
    var alertMessage: String {
        """
        UpDish memakai Apple Intelligence untuk menyusun masukan dan \
        rekomendasi yang lebih personal untukmu.

        Cara mengaktifkan:
        1. Ketuk "Buka Pengaturan"
        2. Ketuk ‹ Pengaturan di kiri atas
        3. Pilih Apple Intelligence & Siri
        4. Nyalakan Apple Intelligence

        Tanpa ini, evaluasi Isi Piringku tetap berjalan dengan masukan dasar.
        """
    }

    /// Opens Settings at UpDish's own page — the deepest link iOS allows.
    ///
    /// The SDK exposes exactly three settings URLs (app page, notifications,
    /// default apps) and none of them reach Apple Intelligence & Siri. The
    /// `App-Prefs:root=` scheme that would is undocumented private API: it
    /// risks App Review rejection, and the pane identifiers change between
    /// releases, so it fails silently on the OS versions it wasn't written for.
    /// Hence the spelled-out steps in `alertMessage` instead.
    @MainActor
    static func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString),
              UIApplication.shared.canOpenURL(url) else { return }
        UIApplication.shared.open(url)
    }
}

/// Keeps the status fresh. The user can leave the app, flip the switch, and
/// come back — so the value is re-read whenever the app becomes active again.
@Observable
final class AppleIntelligenceMonitor {
    private(set) var status: AppleIntelligenceStatus = .current

    func refresh() {
        status = .current
    }
}
