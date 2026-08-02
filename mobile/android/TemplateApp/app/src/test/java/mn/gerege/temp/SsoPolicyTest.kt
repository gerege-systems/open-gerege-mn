// Gerege Template Platform V3.0
// Gerege Systems Development Team болон Claude AI хамтран бүтээв, 2026.

package mn.gerege.temp

import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

// SSO урсгалын шийдвэрийг WebView-гүйгээр шалгана. Хамгийн чухал нь ХОСТЫГ
// тулгах — өөр домэйны `/me` зам нэвтрэлт дууссан гэж андуурагдвал апп
// баталгаажаагүй байхад дотогш оруулна.
class SsoPolicyTest {

    private val base = "https://open.gerege.mn"

    @Test
    fun `нэвтэрсэн хойдох зам таарна`() {
        assertTrue(SsoPolicy.isSignedInUrl(base, "$base/me"))
        assertTrue(SsoPolicy.isSignedInUrl(base, "$base/me/dashboard"))
        assertTrue(SsoPolicy.isSignedInUrl(base, "$base/me/dashboard?tab=eid"))
    }

    @Test
    fun `өөр хостын me зам таарахгүй`() {
        assertFalse(SsoPolicy.isSignedInUrl(base, "https://sso.gerege.mn/me/dashboard"))
        assertFalse(SsoPolicy.isSignedInUrl(base, "https://evil.example.com/me"))
    }

    @Test
    fun `SSO ба callback замууд нэвтрэлт дууссан гэж тооцогдохгүй`() {
        assertFalse(SsoPolicy.isSignedInUrl(base, "$base/api/auth/sso/start"))
        assertFalse(SsoPolicy.isSignedInUrl(base, "$base/sso/callback?code=abc"))
        assertFalse(SsoPolicy.isSignedInUrl(base, "https://sso.gerege.mn/oauth2/auth?client_id=x"))
    }

    @Test
    fun `me угтвартай өөр зам таарахгүй`() {
        assertFalse(SsoPolicy.isSignedInUrl(base, "$base/members"))
        assertFalse(SsoPolicy.isSignedInUrl(base, "$base/mename"))
    }

    @Test
    fun `гаж хаяг унагаахгүй`() {
        assertFalse(SsoPolicy.isSignedInUrl(base, "about:blank"))
        assertFalse(SsoPolicy.isSignedInUrl(base, "цэвэр утга биш"))
        assertFalse(SsoPolicy.isSignedInUrl("", "$base/me"))
    }
}
