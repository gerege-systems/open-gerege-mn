// Gerege Template Platform V3.0
// Gerege Systems Development Team болон Claude AI хамтран бүтээв, 2026.

package mn.gerege.temp

import java.net.URI

// SSO урсгалын шийдвэрүүд — WebView-ээс ТУСДАА, цэвэр функцээр (unit тесттэй).
//
// Урсгал: /api/auth/sso/start → sso.gerege.mn (нэвтрэлт) → /sso/callback
// (cookie суулгана) → /me/dashboard. Тэр сүүлчийн шилжилтийг барьж авах агшинд
// нэвтрэлт дууссан гэж үзээд WebView-г хаана — вэб дашбоардыг апп дотор
// рендэрлэхгүй, native дэлгэц рүү шилжинэ.
object SsoPolicy {

    /**
     * [url] нь BFF-ийн нэвтэрсэн хойдох хуудас (`/me…`) мөн эсэх.
     * Хостыг заавал тулгана — SSO эсвэл гуравдагч домэйны `/me` зам таарахгүй.
     */
    fun isSignedInUrl(baseUrl: String, url: String): Boolean {
        val base = hostOf(baseUrl) ?: return false
        val target = runCatching { URI(url) }.getOrNull() ?: return false
        val host = target.host?.lowercase() ?: return false
        if (host != base) return false
        val path = target.path ?: return false
        return path == "/me" || path.startsWith("/me/")
    }

    private fun hostOf(url: String): String? =
        runCatching { URI(url) }.getOrNull()?.host?.lowercase()
}
