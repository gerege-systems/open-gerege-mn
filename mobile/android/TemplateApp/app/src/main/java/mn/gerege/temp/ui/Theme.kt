// Gerege Template Platform V3.0
// Gerege Systems Development Team болон Claude AI хамтран бүтээв, 2026.

package mn.gerege.temp.ui

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Typography
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.sp

// Material 3 схемийг брэндийн токеноор бөглөнө. Dynamic color (Material You)-г
// ЗОРИУДААР ашиглахгүй — төхөөрөмжийн ханын цаасны өнгө биш, платформын брэнд
// ноёрхох ёстой (вэб, macOS, Windows клиенттэй ижил дүр төрх).
private val LightScheme
    @Composable get() = lightColorScheme(
        primary = Token.brand,
        onPrimary = Token.onBrand,
        primaryContainer = Token.brandSoft,
        onPrimaryContainer = Token.brandText,
        secondary = Token.brandHover,
        onSecondary = Token.onBrand,
        background = Token.bg,
        onBackground = Token.fg,
        surface = Token.surface,
        onSurface = Token.fg,
        surfaceVariant = Token.surface2,
        onSurfaceVariant = Token.muted,
        outline = Token.border,
        outlineVariant = Token.borderStrong,
        error = Token.danger,
        onError = Token.onBrand,
    )

private val DarkScheme
    @Composable get() = darkColorScheme(
        primary = Token.brand,
        onPrimary = colorOf("0A1834"),
        primaryContainer = Token.brandSoft,
        onPrimaryContainer = Token.brandText,
        secondary = Token.brandHover,
        onSecondary = colorOf("0A1834"),
        background = Token.bg,
        onBackground = Token.fg,
        surface = Token.surface,
        onSurface = Token.fg,
        surfaceVariant = Token.surface2,
        onSurfaceVariant = Token.muted,
        outline = Token.border,
        outlineVariant = Token.borderStrong,
        error = Token.danger,
        onError = colorOf("2A0B06"),
    )

// Типографи (`globals.css` → h1/h2/h3 + body). Тусгай фонт багцлахгүй —
// системийн фонт нь монгол кирилл болон латинд хоёуланд нь бэлэн байдаг.
private val GeregeTypography = Typography(
    headlineMedium = TextStyle(fontSize = 28.sp, fontWeight = FontWeight.SemiBold), // h1
    titleLarge = TextStyle(fontSize = 18.sp, fontWeight = FontWeight.SemiBold),     // h2
    titleMedium = TextStyle(fontSize = 15.sp, fontWeight = FontWeight.SemiBold),    // h3
    bodyLarge = TextStyle(fontSize = 15.sp),
    bodyMedium = TextStyle(fontSize = 14.sp),
    labelLarge = TextStyle(fontSize = 14.sp, fontWeight = FontWeight.Medium),
    labelMedium = TextStyle(fontSize = 12.sp),
    labelSmall = TextStyle(fontSize = 11.sp, fontWeight = FontWeight.SemiBold),     // eyebrow
)

@Composable
fun GeregeTheme(content: @Composable () -> Unit) {
    MaterialTheme(
        colorScheme = if (isSystemInDarkTheme()) DarkScheme else LightScheme,
        typography = GeregeTypography,
        content = content,
    )
}
