// Gerege Template Platform V3.0
// Gerege Systems Development Team болон Claude AI хамтран бүтээв, 2026.

// Аппын бүрхүүл — зүүн цэс + толгой + агуулга.
//
// eid-platform-mn-ийн `Features/Main/DashboardView.swift`-ийн ПОРТ:
//   • 264px гүн navy sidebar (нарийн цонхонд 68px icon rail болж хураагдана)
//   • дээд талд лого + брэнд, доод талд Тохиргоо / Гарах
//   • 60px header — хураах товч + хуудасны нэр зүүн талд, профайл баруун талд
//   • агуулгын талбар
//
// Ялгаа: тэдэнд 5 бүрэн хуудас (home · dashboard · organizations · tokens ·
// verify) байдаг бол энэ ЗАГВАР дээр зөвхөн хяналтын самбар хэрэгжсэн. Бусад
// мөрүүд нь ӨРГӨТГӨХ ЦЭГ болж харагдана — идэвхгүй, бүдэг, дарагдахгүй.
// Хуурамч дэлгэц үзүүлэхгүйн тулд зориуд ингэв (README-г хар).

import SwiftUI

/// Зүүн цэсний мөрүүд.
enum NavItem: String, CaseIterable, Identifiable {
    case dashboard
    case services
    case documents
    case organizations
    case assistant

    var id: String { rawValue }

    var label: String {
        switch self {
        case .dashboard:     return "Хяналтын самбар"
        case .services:      return "Үйлчилгээ"
        case .documents:     return "Баримт бичиг"
        case .organizations: return "Байгууллага"
        case .assistant:     return "AI туслах"
        }
    }

    var icon: String {
        switch self {
        case .dashboard:     return "square.grid.2x2"
        case .services:      return "list.bullet.rectangle"
        case .documents:     return "doc.text"
        case .organizations: return "building.2"
        case .assistant:     return "sparkles"
        }
    }

    /// Энэ загварт хэрэгжсэн эсэх. Хэрэгжээгүй мөр нь өргөтгөх цэг —
    /// идэвхгүй харагдана, дарагдахгүй.
    var isImplemented: Bool { self == .dashboard }
}

struct AppShellView: View {
    @EnvironmentObject private var appState: AppState

    @State private var selected: NavItem = .dashboard
    /// nil = цонхны өргөнийг дага; утгатай бол хэрэглэгч гараар тогтоосон.
    @State private var collapsedOverride: Bool?

    /// Энэ өргөнөөс нарийсвал sidebar өөрөө icon rail болно.
    private let collapseBreakpoint: CGFloat = 820

    var body: some View {
        GeometryReader { proxy in
            let collapsed = collapsedOverride ?? (proxy.size.width < collapseBreakpoint)
            HStack(spacing: 0) {
                sidebar(collapsed: collapsed)
                    .frame(width: collapsed ? 68 : 264)

                VStack(spacing: 0) {
                    header(collapsed: collapsed)
                        .frame(height: 60)
                    DashboardView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .animation(.easeInOut(duration: 0.2), value: collapsed)
        }
        .background(Token.bg)
    }

    // MARK: - Зүүн цэс

    private func sidebar(collapsed: Bool) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            sidebarHeader(collapsed: collapsed)

            // eid-platform дээр цэс нь ScrollView дотор байдаг (тэдэнд илүү олон
            // мөр бий). Энд таван мөр тул гүйлгэх шаардлагагүй — ScrollView нь
            // доорх Spacer-тэй зай булаалдаж, мөрүүдийг шахах эрсдэлтэй.
            VStack(alignment: .leading, spacing: 2) {
                ForEach(NavItem.allCases) { item in
                    sidebarItem(item, collapsed: collapsed)
                }
            }
            .padding(.horizontal, collapsed ? 8 : 10)

            Spacer(minLength: 8)

            sidebarFooter(collapsed: collapsed)
        }
        .frame(maxHeight: .infinity)
        .background(Token.sidebarBg)
    }

    private func sidebarHeader(collapsed: Bool) -> some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Token.brand)
                .frame(width: 34, height: 34)
                .overlay(
                    Image(systemName: "shield.lefthalf.filled")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                )

            if !collapsed {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Gerege Template")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                        .fixedSize()
                    Text("Цахим үйлчилгээний суурь")
                        .font(.system(size: 10))
                        .foregroundStyle(Token.sidebarMuted)
                        .fixedSize()
                }
                Spacer(minLength: 0)
            }
        }
        .frame(maxWidth: .infinity, alignment: collapsed ? .center : .leading)
        .padding(.horizontal, collapsed ? 0 : 16)
        .padding(.top, 20)
        .padding(.bottom, 24)
    }

    @ViewBuilder
    private func sidebarItem(_ item: NavItem, collapsed: Bool) -> some View {
        let isSelected = selected == item
        let enabled = item.isImplemented

        Button {
            guard enabled else { return }
            selected = item
        } label: {
            HStack(spacing: 12) {
                Image(systemName: item.icon)
                    .font(.system(size: 15))
                    .frame(width: 20)
                if !collapsed {
                    Text(item.label)
                        .font(.system(size: 15, weight: isSelected ? .semibold : .medium))
                    Spacer(minLength: 0)
                    if !enabled {
                        // Өргөтгөх цэг гэдгийг илэрхийлнэ — хуурамч биш.
                        Text("удахгүй")
                            .font(.system(size: 10))
                            .foregroundStyle(Token.sidebarMuted.opacity(0.7))
                    }
                }
            }
            .foregroundStyle(isSelected ? .white : Token.sidebarMuted.opacity(enabled ? 1 : 0.45))
            .padding(.horizontal, collapsed ? 0 : 12)
            .padding(.vertical, 9)
            .frame(maxWidth: .infinity, alignment: collapsed ? .center : .leading)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(isSelected ? Token.brand : Color.clear)
            )
            // Мөр бүхэлдээ дарагдана — зөвхөн текст/дүрс биш.
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .help(enabled ? item.label : "\(item.label) — энэ загварт хэрэгжээгүй")
        .accessibilityLabel(item.label)
    }

    private func sidebarFooter(collapsed: Bool) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Divider().background(Token.sidebarMuted.opacity(0.2))

            footerButton(icon: "gearshape", label: "Тохиргоо", collapsed: collapsed, enabled: false) {}
            footerButton(icon: "rectangle.portrait.and.arrow.right",
                         label: "Гарах", collapsed: collapsed, enabled: true) {
                Task { await appState.signOut() }
            }
        }
        .padding(.horizontal, collapsed ? 8 : 14)
        .padding(.bottom, 14)
    }

    private func footerButton(icon: String, label: String, collapsed: Bool,
                              enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 13))
                    .frame(width: 20)
                if !collapsed {
                    Text(label).font(.system(size: 13))
                    Spacer()
                }
            }
            .foregroundStyle(Token.sidebarMuted.opacity(enabled ? 1 : 0.45))
            .padding(.horizontal, collapsed ? 0 : 12)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: collapsed ? .center : .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .accessibilityLabel(label)
    }

    // MARK: - Толгой

    private func header(collapsed: Bool) -> some View {
        HStack(spacing: 12) {
            Button {
                collapsedOverride = !collapsed
            } label: {
                Image(systemName: "sidebar.left")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Token.muted)
                    .frame(width: 28, height: 28)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help(collapsed ? "Цэсийг дэлгэх" : "Цэсийг хураах")

            Text(selected.label)
                .font(.gSection)
                .foregroundStyle(Token.fg)

            Spacer()

            if let user = appState.user {
                HStack(spacing: Space.sm) {
                    Text(user.displayName)
                        .font(.gSmall)
                        .foregroundStyle(Token.fg)
                    UserAvatar(photoURL: user.google?.picture,
                               initials: user.initials, size: 30)
                }
            }
        }
        .padding(.horizontal, Space.lg)
        .frame(maxWidth: .infinity)
        .background(Token.surface)
        .overlay(alignment: .bottom) {
            Rectangle().fill(Token.border).frame(height: 1)
        }
    }
}
