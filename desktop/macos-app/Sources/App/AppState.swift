// Gerege Template Platform V3.0
// Gerege Systems Development Team болон Claude AI хамтран бүтээв, 2026.

// Аппын төлөв — нэвтрэлтийн үе шат ба ачаалсан профайл. Бүх дэлгэц үүнийг
// `@EnvironmentObject`-оор уншина (eid-platform-mn-ийн `App/AppState.swift`
// дэг журам).

import SwiftUI

@MainActor
final class AppState: ObservableObject {
    /// Аппын үндсэн урсгал: шалгаж байна → нэвтрэх → самбар.
    enum Phase: Equatable {
        case checking
        case signedOut
        case signedIn
    }

    @Published private(set) var phase: Phase = .checking
    @Published private(set) var user: MeUser?
    @Published private(set) var eid: EidSummary?
    @Published private(set) var errorMessage: String?

    /// SSO цонх нээлттэй эсэх (нэвтрэх дэлгэц үүгээр sheet харуулна).
    @Published var isPresentingSSO = false

    private let api = APIClient.shared

    /// Апп нээгдэхэд хадгалагдсан cookie-гоор session амьд эсэхийг шалгана.
    func bootstrap() async {
        phase = .checking
        if await api.isSignedIn() {
            await loadProfile()
        } else {
            phase = .signedOut
        }
    }

    /// SSO амжилттай дууссаны дараа (WebView cookie-г хуулсны дараа) дуудагдана.
    func completeSignIn() async {
        await loadProfile()
    }

    func loadProfile() async {
        do {
            let me = try await api.me()
            user = me
            errorMessage = nil
            phase = .signedIn
            // eID тоо нь нэмэлт мэдээлэл — амжилтгүй болсон ч самбар нээгдэнэ.
            eid = try? await api.eidSummary()
        } catch {
            user = nil
            eid = nil
            errorMessage = error.localizedDescription
            phase = .signedOut
        }
    }

    func signOut() async {
        await api.logout()
        user = nil
        eid = nil
        errorMessage = nil
        phase = .signedOut
    }
}
