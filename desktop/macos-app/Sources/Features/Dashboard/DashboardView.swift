// Gerege Template Platform V3.0
// Gerege Systems Development Team болон Claude AI хамтран бүтээв, 2026.

// Хяналтын самбар.
//
// Бүтэц нь eid-platform-mn-ийн `DashboardPageView`-ээс: дээд эгнээ (гарчиг +
// хэрэглэгч), статистикийн хайрцгууд, дараа нь дэлгэрэнгүй картууд.
// Өгөгдөл нь платформын BFF-ээс — `/api/me` ба `/api/me/eid/summary`.

import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Space.xl) {
                header

                if let eid = appState.eid {
                    statRow(eid)
                }

                HStack(alignment: .top, spacing: Space.lg) {
                    profileCard
                    identityCard
                }
            }
            .padding(Space.xxl)
            .frame(maxWidth: 980, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .background(Token.bg)
    }

    // MARK: - Толгой

    private var header: some View {
        HStack(alignment: .center, spacing: Space.lg) {
            VStack(alignment: .leading, spacing: Space.xs) {
                Text("Хяналтын самбар")
                    .font(.gHero)
                    .foregroundStyle(Token.fg)
                Text("Gerege Template Platform V3.0")
                    .font(.gSmall)
                    .foregroundStyle(Token.muted)
            }

            Spacer()

            if let user = appState.user {
                HStack(spacing: Space.md) {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(user.displayName)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Token.fg)
                        Chip(text: user.roleLabel, tone: .brand)
                    }
                    avatar(user)
                }
            }

            Button("Гарах") {
                Task { await appState.signOut() }
            }
            .buttonStyle(SecondaryButtonStyle())
        }
    }

    private func avatar(_ user: MeUser) -> some View {
        Circle()
            .fill(Token.brandSoft)
            .frame(width: 44, height: 44)
            .overlay(
                Text(user.initials)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Token.brandText)
            )
    }

    // MARK: - Статистик

    private func statRow(_ eid: EidSummary) -> some View {
        HStack(spacing: Space.lg) {
            stat("Гэрчилгээ", "\(eid.certificates.valid)", "нийт \(eid.certificates.total)")
            stat("Баталгаажуулалт", "\(eid.activity.authentication)", "гүйлгээ")
            stat("Гарын үсэг", "\(eid.activity.signature)", "гүйлгээ")
            stat("Төхөөрөмж", "\(eid.devicesActive)", "нийт \(eid.devicesTotal)")
        }
    }

    private func stat(_ label: String, _ value: String, _ note: String) -> some View {
        AppCard(padding: Space.lg) {
            VStack(alignment: .leading, spacing: Space.xs) {
                SectionLabel(text: label)
                Text(value)
                    .font(.gStat)
                    .foregroundStyle(Token.fg)
                Text(note)
                    .font(.gLabel)
                    .foregroundStyle(Token.muted)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Картууд

    private var profileCard: some View {
        AppCard {
            VStack(alignment: .leading, spacing: Space.md) {
                Text("Профайл")
                    .font(.gTitle)
                    .foregroundStyle(Token.fg)

                if let user = appState.user {
                    DetailRow(label: "Нэр", value: user.displayName)
                    if let en = user.fullNameEn, !en.isEmpty {
                        DetailRow(label: "Латинаар", value: en)
                    }
                    DetailRow(label: "Хэрэглэгчийн нэр", value: user.username, mono: true)
                    DetailRow(label: "И-мэйл", value: user.email ?? "—")
                    DetailRow(label: "Эрх", value: user.roleLabel)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var identityCard: some View {
        AppCard {
            VStack(alignment: .leading, spacing: Space.md) {
                HStack(spacing: Space.sm) {
                    Text("Иргэний танилт")
                        .font(.gTitle)
                        .foregroundStyle(Token.fg)
                    if appState.user?.eid != nil {
                        Chip(text: "eID", tone: .gold)
                    }
                }

                if let eid = appState.user?.eid {
                    DetailRow(label: "Регистр", value: eid.civilId ?? "—", mono: true)
                    DetailRow(label: "Үндэсний дугаар", value: eid.nationalId ?? "—", mono: true)
                    DetailRow(label: "Баримтын дугаар", value: eid.documentNumber ?? "—", mono: true)
                    DetailRow(label: "KYC түвшин", value: eid.kycLevel ?? "—")
                } else {
                    Text("eID-ээр баталгаажаагүй байна.")
                        .font(.gSmall)
                        .foregroundStyle(Token.muted)
                }

                if let google = appState.user?.google, let email = google.email {
                    Divider().overlay(Token.border).padding(.vertical, Space.xs)
                    HStack(spacing: Space.sm) {
                        Text("Google")
                            .font(.gSection)
                            .foregroundStyle(Token.fg)
                        if google.emailVerified == true {
                            Chip(text: "Баталгаажсан", tone: .success)
                        }
                    }
                    DetailRow(label: "И-мэйл", value: email)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
