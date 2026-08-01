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

#if DEBUG
extension AppState {
    /// Жишиг өгөгдөлтэй төлөв — дэлгэцийн загварыг НЭВТРЭХГҮЙГЭЭР шалгахад.
    ///
    /// `GEREGE_PREVIEW_DASHBOARD=1` орчны хувьсагчтай ажиллуулбал апп шууд
    /// хяналтын самбарыг энэ өгөгдлөөр харуулна (`RootView`-г хар).
    /// `#if DEBUG` дотор тул Release багцад ОГТ ОРОХГҮЙ.
    static func previewSignedIn() -> AppState {
        let state = AppState()
        state.user = MeUser.preview
        state.eid = EidSummary.preview
        state.phase = .signedIn
        return state
    }
}

extension MeUser {
    static let preview = MeUser(
        id: "6f1c0f2e-0000-4a00-9000-000000000001",
        username: "citizen",
        firstName: "Дорж",
        lastName: "Бат",
        fullName: "Бат Дорж",
        fullNameEn: "Bat Dorj",
        email: "bat.dorj@example.mn",
        roleId: 4,
        createdAt: "2026-01-14T09:12:00Z",
        eid: EidBlock(civilId: "УБ98042512", nationalId: "1234567890",
                      kycLevel: "HIGH", documentNumber: "AA1234567"),
        google: GoogleBlock(email: "bat.dorj@gmail.com", name: "Bat Dorj",
                            picture: nil, emailVerified: true)
    )
}

extension EidSummary {
    static let preview = EidSummary(
        certificates: CertCounts(valid: 3, total: 4),
        activity: ActivityCounts(authentication: 128, signature: 27),
        devicesActive: 2,
        devicesTotal: 3,
        representationCount: 1
    )
}
#endif
