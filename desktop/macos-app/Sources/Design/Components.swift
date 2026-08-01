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

// MARK: - Төлөвийн тэмдэг (eid-platform-mn → StatusDot / StatusPill)

struct StatusDot: View {
    let color: Color
    var size: CGFloat = 8

    var body: some View {
        Circle().fill(color).frame(width: size, height: size)
    }
}

struct StatusPill: View {
    enum Variant { case ok, warn, bad, neutral, accent }

    let text: String
    let variant: Variant

    init(_ text: String, variant: Variant = .ok) {
        self.text = text
        self.variant = variant
    }

    var body: some View {
        Text(text)
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var background: Color {
        switch variant {
        case .ok:      return Token.success
        case .warn:    return Token.gold
        case .bad:     return Token.danger
        case .accent:  return Token.brand
        case .neutral: return Token.muted
        }
    }
}

// MARK: - Хэрэглэгчийн дүрс

/// Зурагтай бол зураг, эс бөгөөс эхний үсэг. Хэлбэр нь eid-platform-mn-ийхтэй
/// ижил — дугуй биш, зөөлөн булантай квадрат (радиус = хэмжээний 0.28).
///
/// Тэдний хувилбар base64 зураг задалдаг (DAN-аас ирдэг); энэ платформ дээр
/// хэрэглэгчийн зураг нь Google профайлын URL тул `AsyncImage`-аар ачаална.
struct UserAvatar: View {
    let photoURL: String?
    let initials: String
    var size: CGFloat = 64

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
                .fill(Token.brand.opacity(0.10))
                .frame(width: size, height: size)

            if let raw = photoURL, let url = URL(string: raw), !raw.isEmpty {
                AsyncImage(url: url) { phase in
                    if case .success(let image) = phase {
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: size, height: size)
                            .clipShape(RoundedRectangle(cornerRadius: size * 0.28, style: .continuous))
                    } else {
                        initialsText
                    }
                }
            } else {
                initialsText
            }
        }
        .frame(width: size, height: size)
    }

    private var initialsText: some View {
        Text(initials.isEmpty ? "?" : initials)
            .font(.system(size: size * 0.36, weight: .bold))
            .foregroundStyle(Token.brandText)
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
