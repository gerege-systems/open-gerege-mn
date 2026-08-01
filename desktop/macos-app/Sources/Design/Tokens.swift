// Gerege Template Platform V3.0
// Gerege Systems Development Team болон Claude AI хамтран бүтээв, 2026.

// Дизайны токенууд.
//
// ЭХ СУРВАЛЖ: frontend/src/app/globals.css. Өнгө, радиус, зайн утга бүр
// тэндээс хуулбарлагдсан бөгөөд түүнтэй LOCKSTEP-д байна — энэ файлаас гадуур
// шинэ өнгө бүү нэмэгтүн. Шалтгаан: native апп нь вэбтэй нэг бүтээгдэхүүн тул
// хоёулаа нэг палитраас тэжээгдэх ёстой.
//
// Энэ бүтцийг (Colors · Typography · Space · Radius тусдаа токен, дараа нь
// component primitive) eid-platform-mn-ийн desktop клиентүүдээс авав.

import SwiftUI

// MARK: - Өнгө

extension Color {
    /// hex мөрөөс өнгө (#RRGGBB). Токенуудыг web-тэй нэг бичлэгээр барихад.
    init(hex: String) {
        let s = hex.hasPrefix("#") ? String(hex.dropFirst()) : hex
        var v: UInt64 = 0
        Scanner(string: s).scanHexInt64(&v)
        self.init(
            .sRGB,
            red: Double((v >> 16) & 0xFF) / 255,
            green: Double((v >> 8) & 0xFF) / 255,
            blue: Double(v & 0xFF) / 255,
            opacity: 1
        )
    }

    /// Гэрэл/харанхуйд өөр утга авах динамик өнгө.
    static func dynamic(light: String, dark: String) -> Color {
        Color(nsColor: NSColor(name: nil) { appearance in
            let isDark = appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
            return NSColor(Color(hex: isDark ? dark : light))
        })
    }
}

/// Брэнд ба гадаргуугийн токенууд (`globals.css` → `:root` / `[data-theme="dark"]`).
/// oklch утгуудыг sRGB hex болгож хөрвүүлсэн — SwiftUI oklch ойлгодоггүй.
enum Token {
    // Gerege брэнд — #0064E1 cobalt (hue 257)
    static let brand       = Color.dynamic(light: "0B5CD8", dark: "6D9BFF")
    static let brandHover  = Color.dynamic(light: "0A52C2", dark: "8DB2FF")
    static let brandActive = Color.dynamic(light: "0847A8", dark: "A8C4FF")
    static let brandSoft   = Color.dynamic(light: "E8F0FE", dark: "13294F")
    static let brandText   = Color.dynamic(light: "0A56CC", dark: "9CBCFF")
    static let onBrand     = Color(hex: "FCFCFD")

    // Гадаргуу
    static let bg       = Color.dynamic(light: "FAFAFB", dark: "12151B")
    static let surface  = Color.dynamic(light: "FFFFFF", dark: "1A1E26")
    static let surface2 = Color.dynamic(light: "F1F2F5", dark: "222732")

    // Текст
    static let fg    = Color.dynamic(light: "24262C", dark: "F2F3F6")
    static let muted = Color.dynamic(light: "6C707A", dark: "9AA0AC")
    static let faint = Color.dynamic(light: "A9ADB6", dark: "6A707C")

    // Зураас
    static let border       = Color.dynamic(light: "E4E6EA", dark: "313743")
    static let borderStrong = Color.dynamic(light: "C6CAD1", dark: "444B59")

    // Төлөв
    static let success = Color.dynamic(light: "1F9254", dark: "4ECB84")
    static let danger  = Color.dynamic(light: "C4321F", dark: "FF8A76")
    static let gold    = Color.dynamic(light: "C9922E", dark: "E6B458")

    // Landing панелийн гүн navy (`--lp-navy`) — нэвтрэх дэлгэцийн зүүн тал.
    static let navy     = Color(hex: "10358F")
    static let navyDeep = Color(hex: "081F5E")
}

// MARK: - Зай (eid-platform-mn → Spacing)

enum Space {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32
    static let xxxl: CGFloat = 48

    /// Картын дотоод зай — `globals.css` → `.card { padding: 24px }`.
    static let card: CGFloat = 24
}

// MARK: - Радиус (`globals.css` → --radius-*)

enum Radius {
    static let chip: CGFloat = 6
    static let input: CGFloat = 8
    static let card: CGFloat = 10
}

// MARK: - Типографи (`globals.css` → h1/h2/h3 + body)

extension Font {
    /// `h1` — 28pt / 600
    static let gHero = Font.system(size: 28, weight: .semibold)
    /// `h2` — 18pt / 600
    static let gTitle = Font.system(size: 18, weight: .semibold)
    /// `h3` — 15pt / 600
    static let gSection = Font.system(size: 15, weight: .semibold)
    /// body — 15pt
    static let gBody = Font.system(size: 15)
    /// хоёрдогч бичвэр — 14pt
    static let gSmall = Font.system(size: 14)
    /// шошго — 12pt
    static let gLabel = Font.system(size: 12)
    /// eyebrow / бүлгийн толгой — 11pt, өргөн зайтай
    static let gEyebrow = Font.system(size: 11, weight: .semibold)
    /// тоон утга (статистик)
    static let gStat = Font.system(size: 28, weight: .semibold)
    static let gMono = Font.system(size: 12, design: .monospaced)
}
