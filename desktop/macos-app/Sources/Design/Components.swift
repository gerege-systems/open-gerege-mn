// Gerege Template Platform V3.0
// Gerege Systems Development Team болон Claude AI хамтран бүтээв, 2026.

// Дахин ашиглагдах дүрслэлийн примитивүүд — вэбийн `.card`, `.btn`, `.chip`-ийн
// native эквивалент. Бүтэц нь eid-platform-mn-ийн `Design/Styles.swift`-ийн
// (AppCard + товчны style) дэг журмыг дагана.

import SwiftUI

// MARK: - Карт (`globals.css` → .card)

struct AppCard<Content: View>: View {
    var padding: CGFloat = Space.card
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(padding)
            .background(Token.surface)
            .clipShape(RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                    .stroke(Token.border, lineWidth: 1)
            )
    }
}

// MARK: - Товч (`globals.css` → .btn--primary / .btn--secondary)

/// Үндсэн үйлдлийн товч. Өндөр нь вэбийн `min-height: 44px`-тэй тэнцүү.
struct PrimaryButtonStyle: ButtonStyle {
    var fullWidth: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(Token.onBrand)
            .frame(maxWidth: fullWidth ? .infinity : nil, minHeight: 44)
            .padding(.horizontal, Space.lg)
            .background(configuration.isPressed ? Token.brandActive : Token.brand)
            .clipShape(RoundedRectangle(cornerRadius: Radius.input, style: .continuous))
            .contentShape(Rectangle())
    }
}

/// Хоёрдогч товч — гадаргуу + хүчтэй зураас.
struct SecondaryButtonStyle: ButtonStyle {
    var fullWidth: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(Token.fg)
            .frame(maxWidth: fullWidth ? .infinity : nil, minHeight: 44)
            .padding(.horizontal, Space.lg)
            .background(configuration.isPressed ? Token.surface2 : Token.surface)
            .clipShape(RoundedRectangle(cornerRadius: Radius.input, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Radius.input, style: .continuous)
                    .stroke(Token.borderStrong, lineWidth: 1)
            )
            .contentShape(Rectangle())
    }
}

// MARK: - Chip (`globals.css` → .chip)

struct Chip: View {
    let text: String
    var tone: Tone = .neutral

    enum Tone { case neutral, brand, success, gold }

    private var fg: Color {
        switch tone {
        case .neutral: return Token.muted
        case .brand:   return Token.brandText
        case .success: return Token.success
        case .gold:    return Token.gold
        }
    }

    private var bg: Color {
        switch tone {
        case .neutral: return Token.surface2
        case .brand:   return Token.brandSoft
        case .success: return Token.success.opacity(0.12)
        case .gold:    return Token.gold.opacity(0.14)
        }
    }

    var body: some View {
        Text(text)
            .font(.gLabel)
            .foregroundStyle(fg)
            .padding(.horizontal, Space.sm)
            .padding(.vertical, Space.xs)
            .background(bg)
            .clipShape(RoundedRectangle(cornerRadius: Radius.chip, style: .continuous))
    }
}

// MARK: - Бүлгийн толгой

struct SectionLabel: View {
    let text: String

    var body: some View {
        Text(text.uppercased())
            .font(.gEyebrow)
            .tracking(0.08 * 11)
            .foregroundStyle(Token.faint)
    }
}

// MARK: - Нэр → утга мөр (дашбоардын дэлгэрэнгүй)

struct DetailRow: View {
    let label: String
    let value: String
    var mono: Bool = false

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: Space.md) {
            Text(label)
                .font(.gLabel)
                .foregroundStyle(Token.muted)
                .frame(width: 132, alignment: .leading)
            Text(value)
                .font(mono ? .gMono : .gSmall)
                .foregroundStyle(Token.fg)
                .textSelection(.enabled)
            Spacer(minLength: 0)
        }
    }
}
