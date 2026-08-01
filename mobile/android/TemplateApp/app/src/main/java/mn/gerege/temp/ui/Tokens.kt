// Gerege Template Platform V3.0
// Gerege Systems Development Team болон Claude AI хамтран бүтээв, 2026.

// Дизайны токенууд.
//
// ЭХ СУРВАЛЖ: frontend/src/app/globals.css. Өнгө, радиус, зайн утга бүр тэндээс
// хуулбарлагдсан бөгөөд түүнтэй LOCKSTEP-д байна — энэ файлаас гадуур шинэ өнгө
// БҮҮ нэмэгтүн. Шалтгаан: native апп нь вэбтэй нэг бүтээгдэхүүн тул хоёулаа нэг
// палитраас тэжээгдэх ёстой. desktop/macos-app/Sources/Design/Tokens.swift-ийн
// Android хувилбар (утга бүр адилхан).

package mn.gerege.temp.ui

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.ReadOnlyComposable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp

/** hex мөрөөс өнгө (#RRGGBB) — токенуудыг web-тэй нэг бичлэгээр барихад. */
fun colorOf(hex: String): Color = Color(("FF" + hex.removePrefix("#")).toLong(16))

@Composable
@ReadOnlyComposable
private fun dynamic(light: String, dark: String): Color =
    colorOf(if (isSystemInDarkTheme()) dark else light)

/**
 * Брэнд ба гадаргуугийн токенууд (`globals.css` → `:root` / `[data-theme="dark"]`).
 * oklch утгуудыг sRGB hex болгож хөрвүүлсэн — Compose oklch ойлгодоггүй.
 */
object Token {
    // Gerege брэнд — #0064E1 cobalt (hue 257)
    val brand: Color @Composable @ReadOnlyComposable get() = dynamic("0B5CD8", "6D9BFF")
    val brandHover: Color @Composable @ReadOnlyComposable get() = dynamic("0A52C2", "8DB2FF")
    val brandSoft: Color @Composable @ReadOnlyComposable get() = dynamic("E8F0FE", "13294F")
    val brandText: Color @Composable @ReadOnlyComposable get() = dynamic("0A56CC", "9CBCFF")
    val onBrand: Color get() = colorOf("FCFCFD")

    // Гадаргуу
    val bg: Color @Composable @ReadOnlyComposable get() = dynamic("FAFAFB", "12151B")
    val surface: Color @Composable @ReadOnlyComposable get() = dynamic("FFFFFF", "1A1E26")
    val surface2: Color @Composable @ReadOnlyComposable get() = dynamic("F1F2F5", "222732")

    // Текст
    val fg: Color @Composable @ReadOnlyComposable get() = dynamic("24262C", "F2F3F6")
    val muted: Color @Composable @ReadOnlyComposable get() = dynamic("6C707A", "9AA0AC")
    val faint: Color @Composable @ReadOnlyComposable get() = dynamic("A9ADB6", "6A707C")

    // Зураас
    val border: Color @Composable @ReadOnlyComposable get() = dynamic("E4E6EA", "313743")
    val borderStrong: Color @Composable @ReadOnlyComposable get() = dynamic("C6CAD1", "444B59")

    // Төлөв
    val success: Color @Composable @ReadOnlyComposable get() = dynamic("1F9254", "4ECB84")
    val danger: Color @Composable @ReadOnlyComposable get() = dynamic("C4321F", "FF8A76")
    val gold: Color @Composable @ReadOnlyComposable get() = dynamic("C9922E", "E6B458")

    // Landing панелийн гүн navy (`--lp-navy`) — нэвтрэх дэлгэцийн дэвсгэр.
    val navy: Color get() = colorOf("10358F")
    val navyDeep: Color get() = colorOf("081F5E")
}

/** Зай (eid-platform-mn → Spacing). */
object Space {
    val xs = 4.dp
    val sm = 8.dp
    val md = 12.dp
    val lg = 16.dp
    val xl = 24.dp
    val xxl = 32.dp
    val xxxl = 48.dp

    /** Картын дотоод зай — `globals.css` → `.card { padding: 24px }`. */
    val card = 24.dp
}

/** Радиус (`globals.css` → --radius-*). */
object Radius {
    val chip = 6.dp
    val input = 8.dp
    val card = 10.dp
}
