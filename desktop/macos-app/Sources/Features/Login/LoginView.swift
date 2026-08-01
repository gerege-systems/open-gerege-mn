// Gerege Template Platform V3.0
// Gerege Systems Development Team болон Claude AI хамтран бүтээв, 2026.

// Нэвтрэх дэлгэц.
//
// Layout нь eid-platform-mn-ийн desktop клиентээс: өргөн цонхонд split —
// зүүн талд гүн navy брэнд самбар, баруун талд нэвтрэх карт; нарийсахад зөвхөн
// карт үлдэнэ.
//
// Урсгал нь энэ платформынх: ганц товч → Gerege SSO (BFF-ээр) → cookie →
// native дашбоард. Нууц үг, OTP, өөр нэвтрэх арга БАЙХГҮЙ.

import SwiftUI

struct LoginView: View {
    @EnvironmentObject private var appState: AppState

    /// Split layout-д шилжих доод өргөн (eid-platform-тай ижил босго).
    private let splitBreakpoint: CGFloat = 820

    var body: some View {
        GeometryReader { proxy in
            let wide = proxy.size.width >= splitBreakpoint
            HStack(spacing: 0) {
                if wide {
                    brandPanel
                        .frame(width: proxy.size.width * 5 / 11)
                }
                loginPanel
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .animation(.easeInOut(duration: 0.2), value: wide)
        }
        .background(Token.bg)
        .sheet(isPresented: $appState.isPresentingSSO) {
            SSOSheet()
                .environmentObject(appState)
        }
    }

    // MARK: - Зүүн тал: брэнд самбар

    private var brandPanel: some View {
        ZStack {
            LinearGradient(
                colors: [Token.navyDeep, Token.navy],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Зөөлөн гэрлийн толбо — гүнийг мэдрүүлнэ.
            Circle()
                .fill(RadialGradient(
                    colors: [Color.white.opacity(0.14), .clear],
                    center: .center, startRadius: 0, endRadius: 260
                ))
                .frame(width: 520, height: 520)
                .offset(x: 180, y: -200)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)

            VStack(alignment: .leading, spacing: Space.xl) {
                Spacer()

                VStack(alignment: .leading, spacing: Space.md) {
                    Text("GEREGE TEMPLATE PLATFORM V3.0")
                        .font(.gEyebrow)
                        .tracking(1.2)
                        .foregroundStyle(Color.white.opacity(0.72))

                    Text("Цахим үйлчилгээг\nбүтээх суурь")
                        .font(.system(size: 34, weight: .semibold))
                        .foregroundStyle(.white)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("eID-д суурилсан, AI-аар хүчирхэгжсэн — төр, хувийн хэвшлийн аливаа цахим үйлчилгээг дээр нь босгох бэлэн суурь.")
                        .font(.gSmall)
                        .foregroundStyle(Color.white.opacity(0.78))
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: 380, alignment: .leading)
                }

                Spacer()

                HStack(spacing: Space.xxl) {
                    brandStat("Clean Arch", "Цэгцтэй, өргөтгөхөд бэлэн")
                    brandStat("eID · OIDC", "Цахим үнэмлэх + стандарт")
                }
            }
            .padding(Space.xxxl)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        }
    }

    private func brandStat(_ title: String, _ subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: Space.xs) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)
            Text(subtitle)
                .font(.gLabel)
                .foregroundStyle(Color.white.opacity(0.62))
        }
    }

    // MARK: - Баруун тал: нэвтрэх карт

    private var loginPanel: some View {
        VStack {
            Spacer()
            AppCard(padding: Space.xxl) {
                VStack(alignment: .leading, spacing: Space.lg) {
                    VStack(alignment: .leading, spacing: Space.sm) {
                        Text("Нэвтрэх")
                            .font(.gHero)
                            .foregroundStyle(Token.fg)
                        Text("Gerege SSO-оор нэвтэрч, хяналтын самбартаа орно уу.")
                            .font(.gSmall)
                            .foregroundStyle(Token.muted)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Button {
                        appState.isPresentingSSO = true
                    } label: {
                        HStack(spacing: Space.sm) {
                            Image(systemName: "lock.shield")
                            Text("Gerege SSO-оор нэвтрэх")
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle(fullWidth: true))

                    if let error = appState.errorMessage {
                        Text(error)
                            .font(.gLabel)
                            .foregroundStyle(Token.danger)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Divider().overlay(Token.border)

                    VStack(alignment: .leading, spacing: Space.sm) {
                        SectionLabel(text: "Нэвтрэлтийн тухай")
                        Text("Нэвтрэлт нь платформын BFF-ээр явж, session нь httpOnly cookie-д хадгалагдана. Аппад токен хадгалагдахгүй.")
                            .font(.gLabel)
                            .foregroundStyle(Token.muted)
                            .fixedSize(horizontal: false, vertical: true)
                        Text(APIClient.baseURL.host ?? "")
                            .font(.gMono)
                            .foregroundStyle(Token.faint)
                    }
                }
                .frame(width: 360, alignment: .leading)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(Space.xl)
    }
}

// MARK: - SSO цонх

/// Нэвтрэлтийн WebView-г багтаасан sheet — толгойд нь болих товч.
private struct SSOSheet: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Gerege SSO")
                    .font(.gSection)
                    .foregroundStyle(Token.fg)
                Spacer()
                Button("Болих") { appState.isPresentingSSO = false }
                    .buttonStyle(.plain)
                    .foregroundStyle(Token.brandText)
            }
            .padding(.horizontal, Space.lg)
            .padding(.vertical, Space.md)
            .background(Token.surface)

            Divider().overlay(Token.border)

            SSOWebView(
                onDone: {
                    appState.isPresentingSSO = false
                    Task { await appState.completeSignIn() }
                },
                onCancel: {
                    appState.isPresentingSSO = false
                }
            )
        }
        .frame(width: 520, height: 640)
    }
}
