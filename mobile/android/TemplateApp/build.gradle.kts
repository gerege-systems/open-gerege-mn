// Gerege Template Platform V3.0
// Gerege Systems Development Team болон Claude AI хамтран бүтээв, 2026.

// Үндсэн build script — plugin-үүдийн хувилбарыг эндээс төвлөрүүлж зарлана
// (модуль бүр `apply false`-гүйгээр нэрээр нь ашиглана).
plugins {
    id("com.android.application") version "8.7.2" apply false
    id("org.jetbrains.kotlin.android") version "2.0.21" apply false
    // Kotlin 2.0-оос Compose compiler нь Kotlin-ий бүрэлдэхүүн — тусдаа
    // compiler extension хувилбар барих шаардлагагүй болсон.
    id("org.jetbrains.kotlin.plugin.compose") version "2.0.21" apply false
}
