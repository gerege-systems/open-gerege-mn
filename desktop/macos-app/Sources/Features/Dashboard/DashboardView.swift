// Gerege Template Platform V3.0
// Gerege Systems Development Team болон Claude AI хамтран бүтээв, 2026.

// Хяналтын самбар.
//
// Бүтэц нь eid-platform-mn-ийн `DashboardPageView`-ийн ПОРТ:
//
//   hero карт (дүрс + мэндчилгээ + төлөвийн тэмдэг + сэргээх товч)
//   → 4 багана статистикийн grid (сүүлийнх нь accent өнгөтэй)
//   → жагсаалтат карт (мөр бүр нь дүрсний хайрцаг + текст + StatusPill)
//   → жагсаалтат карт (мөр хооронд Divider)
//
// Зай, радиус, фонтын шатлал, мөрийн бүтэц бүгд тэднийхтэй ижил. Ялгаа нь
// ЗӨВХӨН өгөгдлийн эх сурвалж: тэд өөрийн `/dashboard` endpoint-оос төхөөрөмж,
// session-ий жагсаалт авдаг; энэ платформ дээр тийм endpoint байхгүй тул
// `/api/me` (профайл, eID, Google) ба `/api/me/eid/summary` (тоо) хоёрыг
// ижил бүтэцтэйгээр байрлуулав.

import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var appState: AppState

    @State private var isRefreshing = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                heroCard
                statsGrid
                identityCard
                profileCard
            }
            .padding(.horizontal, Space.pageHoriz)
            .padding(.top, Space.pageTop)
            .padding(.bottom, Space.pageBottom)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .background(Token.bg)
    }

    // MARK: - Hero (дүрс + мэндчилгээ + төлөвийн тэмдэг + сэргээх)

    private var heroCard: some View {
        AppCard {
            HStack(alignment: .top, spacing: 16) {
                UserAvatar(
                    photoURL: appState.user?.google?.picture,
                    initials: appState.user?.initials ?? "?",
                    size: 64
                )

                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("GEREGE TEMPLATE")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(Token.brand)
                                .kerning(0.8)
                            Text("Цахим үйлчилгээний суурь")
                                .font(.system(size: 10))
                                .foregroundStyle(Token.muted)
                        }

                        statusBadge
                    }

                    Text("Сайн байна уу, \(appState.user?.displayName ?? "Хэрэглэгч")!")
                        .font(.gTitle)
                        .foregroundStyle(Token.fg)

                    Text("Таны бүртгэл, иргэний танилтын мэдээлэл.")
                        .font(.gSmall)
                        .foregroundStyle(Token.muted)
                }

                Spacer(minLength: 0)

                // Гарах нь зүүн цэсний доод талд (eid-platform-той ижил) —
                // энд зөвхөн сэргээх.
                Button {
                    refresh()
                } label: {
                    HStack(spacing: 6) {
                        if isRefreshing {
                            ProgressView().controlSize(.small)
                        } else {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 12))
                        }
                        Text("Сэргээх")
                    }
                }
                .buttonStyle(SecondaryButtonStyle())
            }
        }
    }

    /// Баталгаажсан эсэхийн тэмдэг — цэг + бичвэр, зөөлөн accent дэвсгэртэй.
    private var statusBadge: some View {
        let verified = appState.user?.eid != nil
        return HStack(spacing: 6) {
            StatusDot(color: verified ? Token.success : Token.muted, size: 8)
            Text(verified ? "eID баталгаажсан" : "Баталгаажаагүй")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Token.brand)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(Token.brandSoft)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Token.brand.opacity(0.35), lineWidth: 1)
        )
    }

    // MARK: - 4 статистикийн карт

    private var statsGrid: some View {
        let cols = [
            GridItem(.flexible(), spacing: 16),
            GridItem(.flexible(), spacing: 16),
            GridItem(.flexible(), spacing: 16),
            GridItem(.flexible(), spacing: 16),
        ]
        let eid = appState.eid
        return LazyVGrid(columns: cols, spacing: 16) {
            statCard(title: "Гэрчилгээ",
                     value: eid.map { "\($0.certificates.valid)" } ?? "—",
                     accent: false)
            statCard(title: "Баталгаажуулалт",
                     value: eid.map { "\($0.activity.authentication)" } ?? "—",
                     accent: false)
            statCard(title: "Гарын үсэг",
                     value: eid.map { "\($0.activity.signature)" } ?? "—",
                     accent: false)
            statCard(title: "Идэвхтэй төхөөрөмж",
                     value: eid.map { "\($0.devicesActive)" } ?? "—",
                     accent: true)
        }
    }

    private func statCard(title: String, value: String, accent: Bool) -> some View {
        AppCard(padding: 18) {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Token.muted)
                    .textCase(.uppercase)
                    .kerning(0.6)
                Text(value)
                    .font(.gStat)
                    .foregroundStyle(accent ? Token.brand : Token.fg)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Иргэний танилт (тэдний devicesCard-ийн бүтэц)

    private var identityCard: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Иргэний танилт")
                    .font(.gSection)
                    .foregroundStyle(Token.fg)

                if let eid = appState.user?.eid {
                    identityRow(icon: "person.text.rectangle",
                                title: "Регистрийн дугаар",
                                subtitle: eid.civilId ?? "—",
                                pill: "eID", variant: .accent)
                    identityRow(icon: "number",
                                title: "Үндэсний дугаар",
                                subtitle: eid.nationalId ?? "—",
                                pill: nil, variant: .neutral)
                    identityRow(icon: "doc.text",
                                title: "Баримтын дугаар",
                                subtitle: eid.documentNumber ?? "—",
                                pill: nil, variant: .neutral)
                    identityRow(icon: "checkmark.seal",
                                title: "KYC түвшин",
                                subtitle: eid.kycLevel ?? "—",
                                pill: eid.kycLevel == nil ? nil : "Баталгаажсан",
                                variant: .ok)
                } else {
                    Text("eID-ээр баталгаажаагүй байна.")
                        .font(.gLabel)
                        .foregroundStyle(Token.muted)
                }
            }
        }
    }

    private func identityRow(icon: String, title: String, subtitle: String,
                             pill: String?, variant: StatusPill.Variant) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Token.brand.opacity(0.12))
                    .frame(width: 38, height: 38)
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundStyle(Token.brand)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.gSmall)
                    .foregroundStyle(Token.fg)
                Text(subtitle)
                    .font(.gMono)
                    .foregroundStyle(Token.muted)
                    .textSelection(.enabled)
            }

            Spacer()

            if let pill {
                StatusPill(pill, variant: variant)
            }
        }
        .padding(12)
        .background(Token.surface)
        .clipShape(RoundedRectangle(cornerRadius: Radius.input, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Radius.input, style: .continuous)
                .strokeBorder(Token.border, lineWidth: 1)
        )
    }

    // MARK: - Профайл (тэдний activityCard-ийн бүтэц)

    private var profileCard: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Профайл")
                    .font(.gSection)
                    .foregroundStyle(Token.fg)

                let rows = profileRows
                ForEach(Array(rows.enumerated()), id: \.offset) { index, row in
                    profileRow(row)
                    if index < rows.count - 1 {
                        Divider().background(Token.border)
                    }
                }
            }
        }
    }

    private struct ProfileEntry {
        let title: String
        let detail: String
        let pill: String?
        let variant: StatusPill.Variant
    }

    private var profileRows: [ProfileEntry] {
        guard let user = appState.user else { return [] }
        var rows: [ProfileEntry] = [
            ProfileEntry(title: user.displayName, detail: "Нэр", pill: user.roleLabel, variant: .accent),
            ProfileEntry(title: user.username, detail: "Хэрэглэгчийн нэр", pill: nil, variant: .neutral),
            ProfileEntry(title: user.email ?? "—", detail: "И-мэйл", pill: nil, variant: .neutral),
        ]
        if let en = user.fullNameEn, !en.isEmpty {
            rows.insert(ProfileEntry(title: en, detail: "Латинаар", pill: nil, variant: .neutral), at: 1)
        }
        if let google = user.google, let email = google.email {
            rows.append(ProfileEntry(
                title: email,
                detail: "Google",
                pill: google.emailVerified == true ? "Баталгаажсан" : nil,
                variant: .ok
            ))
        }
        return rows
    }

    private func profileRow(_ entry: ProfileEntry) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.title)
                    .font(.gSmall)
                    .fontWeight(.semibold)
                    .foregroundStyle(Token.fg)
                    .textSelection(.enabled)
                Text(entry.detail)
                    .font(.gLabel)
                    .foregroundStyle(Token.muted)
            }
            Spacer()
            if let pill = entry.pill {
                StatusPill(pill, variant: entry.variant)
            }
        }
        .padding(.vertical, 8)
    }

    // MARK: - Туслах

    private func refresh() {
        guard !isRefreshing else { return }
        isRefreshing = true
        Task {
            await appState.loadProfile()
            isRefreshing = false
        }
    }
}
