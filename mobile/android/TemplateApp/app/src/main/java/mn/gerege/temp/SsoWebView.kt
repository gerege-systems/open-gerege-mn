// Gerege Template Platform V3.0
// Gerege Systems Development Team болон Claude AI хамтран бүтээв, 2026.

package mn.gerege.temp

import android.annotation.SuppressLint
import android.graphics.Bitmap
import android.webkit.CookieManager
import android.webkit.WebResourceRequest
import android.webkit.WebView
import android.webkit.WebViewClient
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.viewinterop.AndroidView

// Gerege SSO нэвтрэлт — вэбтэй ЯГ ИЖИЛ урсгал, бүхэлдээ template BFF-ээр:
//   /api/auth/sso/start → Gerege SSO (нэвтрэлт) → /sso/callback (cookie суулгана)
//   → /me/dashboard.
// Апп нь SSO дээр өөрийн OIDC client БҮРТГҮҮЛЭХГҮЙ (native/PKCE урсгал байхгүй) —
// template-ийн вэб client-ийн логикийг тэр чигт нь ашиглана. Дашбоард руу шилжих
// агшинд навигацыг зогсоож, cookie-г диск рүү flush хийгээд native дэлгэц рүү
// шилжинэ (вэб дашбоардыг апп дотор рендэрлэхгүй).
@SuppressLint("SetJavaScriptEnabled") // SSO хуудас JS шаарддаг; зөвхөн өөрсдийн BFF/SSO домэйн ачаална
@Composable
fun SsoWebView(modifier: Modifier = Modifier, onDone: () -> Unit) {
    AndroidView(
        modifier = modifier,
        factory = { ctx ->
            val web = WebView(ctx)
            web.settings.javaScriptEnabled = true
            web.settings.domStorageEnabled = true
            // JS гүүр (addJavascriptInterface) ОГТ нэмэхгүй — вэб хуудас native
            // код руу хүрэх гарц байх ёсгүй.
            CookieManager.getInstance().setAcceptCookie(true)
            CookieManager.getInstance().setAcceptThirdPartyCookies(web, true)
            web.webViewClient = SsoClient(onDone)
            web.loadUrl(ApiClient.ssoStartUrl)
            web
        },
    )
}

private class SsoClient(private val onDone: () -> Unit) : WebViewClient() {
    private var finished = false

    override fun shouldOverrideUrlLoading(view: WebView, request: WebResourceRequest): Boolean =
        complete(request.url.toString())

    // Сервер талын redirect зарим тохиолдолд shouldOverrideUrlLoading-д ирэхгүй
    // байж болзошгүй тул хуудас эхлэх агшинд ч шалгана (хамгаалалтын тор).
    override fun onPageStarted(view: WebView, url: String, favicon: Bitmap?) {
        if (complete(url)) view.stopLoading() else super.onPageStarted(view, url, favicon)
    }

    /** Нэвтрэлт дуусах хаяг мөн бол cookie-г flush хийж WebView-г хаана. */
    private fun complete(url: String): Boolean {
        if (finished || !SsoPolicy.isSignedInUrl(ApiClient.baseUrl, url)) return false
        finished = true
        CookieManager.getInstance().flush()
        onDone()
        return true
    }
}
