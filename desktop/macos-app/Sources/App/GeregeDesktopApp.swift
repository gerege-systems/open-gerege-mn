// Gerege Template Platform V3.0
// Gerege Systems Development Team болон Claude AI хамтран бүтээв, 2026.

// Аппын эхлэх цэг. Ганц цонх — нэвтрэлтийн төлвөөс хамаарч нэвтрэх дэлгэц
// эсвэл хяналтын самбар харагдана.

import SwiftUI
import AppKit

@main
struct GeregeDesktopApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .frame(minWidth: 520, minHeight: 600)
                .task {
                    #if DEBUG
                    // Дэлгэцийг PNG болгон гаргаад гарах (загварыг шалгахад).
                    //   GEREGE_SNAPSHOT=/зам/shell.png ./GeregeDesktop
                    if let path = ProcessInfo.processInfo.environment["GEREGE_SNAPSHOT"] {
                        await Self.writeSnapshot(to: path)
                        return
                    }
                    #endif
                    await appState.bootstrap()
                }
        }
        .defaultSize(width: 1080, height: 760)
        .windowToolbarStyle(.unified(showsTitle: false))
        .commands {
            // Шинэ цонх нэмэх нь энэ аппад утгагүй (ганц session).
            CommandGroup(replacing: .newItem) {}
        }
    }

    #if DEBUG
    /// Бүрхүүлийг жишиг өгөгдлөөр PNG болгон бичээд аппыг хаана.
    @MainActor
    private static func writeSnapshot(to path: String) async {
        let view = AppShellView()
            .environmentObject(AppState.previewSignedIn())
            .frame(width: 1200, height: 820)
        let renderer = ImageRenderer(content: view)
        renderer.scale = 2
        if let image = renderer.nsImage,
           let tiff = image.tiffRepresentation,
           let rep = NSBitmapImageRep(data: tiff),
           let png = rep.representation(using: .png, properties: [:]) {
            // App Sandbox идэвхтэй тул дурын зам руу бичиж чадахгүй — аппын
            // өөрийн түр хавтсанд бичээд бодит замыг хэвлэнэ.
            let name = (path as NSString).lastPathComponent
            let url = FileManager.default.temporaryDirectory.appendingPathComponent(name)
            do {
                try png.write(to: url)
                print("SNAPSHOT: \(url.path)")
            } catch {
                print("SNAPSHOT FAILED: \(error.localizedDescription)")
            }
        } else {
            print("SNAPSHOT FAILED: рендэр хийгдсэнгүй")
        }
        exit(0)
    }
    #endif
}

struct RootView: View {
    @EnvironmentObject private var appState: AppState

    #if DEBUG
    /// Дэлгэцийн загварыг нэвтрэхгүйгээр шалгах горим (зөвхөн DEBUG):
    ///   GEREGE_PREVIEW_DASHBOARD=1 open -a … GeregeDesktop.app
    @StateObject private var previewState = AppState.previewSignedIn()

    private var isPreviewingDashboard: Bool {
        ProcessInfo.processInfo.environment["GEREGE_PREVIEW_DASHBOARD"] == "1"
    }
    #endif

    var body: some View {
        #if DEBUG
        if isPreviewingDashboard {
            return AnyView(AppShellView().environmentObject(previewState))
        }
        #endif
        return AnyView(content)
    }

    private var content: some View {
        Group {
            switch appState.phase {
            case .checking:
                splash
            case .signedOut:
                LoginView()
            case .signedIn:
                AppShellView()
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
