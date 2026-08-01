// Gerege Template Platform V3.0
// Gerege Systems Development Team болон Claude AI хамтран бүтээв, 2026.

// Аппын эхлэх цэг. Ганц цонх — нэвтрэлтийн төлвөөс хамаарч нэвтрэх дэлгэц
// эсвэл хяналтын самбар харагдана.

import SwiftUI

@main
struct GeregeDesktopApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .frame(minWidth: 520, minHeight: 600)
                .task { await appState.bootstrap() }
        }
        .defaultSize(width: 1080, height: 760)
        .windowToolbarStyle(.unified(showsTitle: false))
        .commands {
            // Шинэ цонх нэмэх нь энэ аппад утгагүй (ганц session).
            CommandGroup(replacing: .newItem) {}
        }
    }
}

struct RootView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        Group {
            switch appState.phase {
            case .checking:
                splash
            case .signedOut:
                LoginView()
            case .signedIn:
                DashboardView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Token.bg)
    }

    /// Хадгалсан session-ыг шалгах хугацаанд — хоосон цагаан дэлгэц харуулахгүй.
    private var splash: some View {
        VStack(spacing: Space.md) {
            ProgressView()
            Text("Session шалгаж байна…")
                .font(.gSmall)
                .foregroundStyle(Token.muted)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Token.bg)
    }
}
