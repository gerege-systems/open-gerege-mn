// Gerege Template Platform V3.0
// Gerege Systems Development Team болон Claude AI хамтран бүтээв, 2026.

package mn.gerege.temp

import android.webkit.CookieManager
import android.webkit.WebStorage
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URL

// BFF клиент.
//
// Апп нь Go backend-тэй ШУУД харьцахгүй — бүх хүсэлт платформын Next.js BFF-ээр
// явна (вэб, iOS, desktop-той яг ижил). Session нь httpOnly cookie (`dgov_access` /
// `dgov_refresh`) — токен клиент код руу ХЭЗЭЭ Ч гарахгүй.
//
// Cookie store: WebView-ийн `android.webkit.CookieManager`-ийг ГАНЦ эх сурвалж
// болгож ашиглана. Шалтгаан: SSO нэвтрэлт WebView дотор явдаг тул тэнд суусан
// cookie-г java.net.CookieManager руу гүүрлэх шаардлагагүй болно — HTTP хүсэлт
// бүрт `Cookie` толгойг тэндээс шууд уншиж, хариуны `Set-Cookie`-г буцааж
// хадгална. Нэмэлт давуу тал: WebView-ийн store диск дээр хадгалагддаг тул апп
// хаагдаад нээгдэхэд session хэвээр үлдэнэ.
sealed class ApiError(message: String) : Exception(message) {
    class Http(val code: Int, val serverMessage: String) :
        ApiError(if (serverMessage.isEmpty()) "Алдаа ($code)." else "Алдаа ($code): $serverMessage")

    class Decoding : ApiError("Серверийн хариуг задлахад алдаа гарлаа.")

    class Network(cause: String) : ApiError("Сүлжээний алдаа: $cause")
}

object ApiClient {

    /**
     * Платформын BFF. Анхдагч нь энэ репогийн жишиг deployment; build үед
     * `-PgeregeAppUrl=…`-ээр дарна (app/build.gradle.kts-ийг хар).
     */
    val baseUrl: String = BuildConfig.GEREGE_APP_URL.trimEnd('/')

    /** SSO нэвтрэлт эхлэх хаяг — WebView үүнийг ачаална. */
    val ssoStartUrl: String get() = "$baseUrl/api/auth/sso/start"

    private const val CONNECT_TIMEOUT_MS = 15_000
    private const val READ_TIMEOUT_MS = 20_000

    private data class RawResponse(val code: Int, val body: String)

    // MARK: - Профайл ба session

    /** Backend `/users/me` нь `data`-г `{ "user": {…} }` гэж боодог. */
    suspend fun me(): MeUser {
        val data = payload(request("/api/me"))
        val user = data.optJSONObject("user") ?: throw ApiError.Decoding()
        return MeUser.fromJson(user)
    }

    /** eID нэгдсэн тоо. PKI_READ эрхгүй хэрэглэгчид 403 — энэ нь алдаа биш тул `null`. */
    suspend fun eidSummary(): EidSummary? {
        val res = request("/api/me/eid/summary")
        if (res.code == 403) return null
        return runCatching { EidSummary.fromJson(payload(res)) }.getOrNull()
    }

    /** Session идэвхтэй эсэх — аппыг нээхэд шалгана. */
    suspend fun isSignedIn(): Boolean = runCatching { me() }.isSuccess

    suspend fun logout() {
        runCatching { request("/api/auth/logout", method = "POST", body = "{}") }
        clearSession()
    }

    /**
     * Локал session-ыг бүрэн цэвэрлэнэ. WebView-ийн cookie/storage-ыг УСТГАХ нь
     * чухал — эс бөгөөс sso.gerege.mn-ий Hydra session үлдэж, дараагийн SSO
     * нэвтрэлт дахин баталгаажуулалгүй шууд ордог.
     *
     * ЗААВАЛ үндсэн (UI) урсгалаас дуудна — WebStorage үүнийг шаардана.
     */
    fun clearSession() {
        val cookies = CookieManager.getInstance()
        cookies.removeAllCookies(null)
        cookies.removeSessionCookies(null)
        cookies.flush()
        WebStorage.getInstance().deleteAllData()
    }

    // MARK: - Хүсэлт

    private suspend fun request(
        path: String,
        method: String = "GET",
        body: String? = null,
    ): RawResponse = withContext(Dispatchers.IO) {
        val conn = try {
            URL(baseUrl + path).openConnection() as HttpURLConnection
        } catch (e: Exception) {
            throw ApiError.Network(e.message ?: "хүсэлт үүсгэж чадсангүй")
        }
        try {
            conn.requestMethod = method
            conn.connectTimeout = CONNECT_TIMEOUT_MS
            conn.readTimeout = READ_TIMEOUT_MS
            conn.useCaches = false // профайлын хуучин хариу гарсны дараа харагдахгүйн тулд
            conn.setRequestProperty("Accept", "application/json")
            cookieHeader()?.let { conn.setRequestProperty("Cookie", it) }

            if (method != "GET") {
                // BFF-ийн өөрчлөх (mutating) route-ууд `x-dgov-csrf` шаарддаг — native
                // клиентэд Origin толгой байхгүй тул `checkOrigin` үүнийг л шалгана.
                conn.setRequestProperty("x-dgov-csrf", "1")
                conn.setRequestProperty("Content-Type", "application/json")
                conn.doOutput = true
                conn.outputStream.use { it.write((body ?: "{}").toByteArray(Charsets.UTF_8)) }
            }

            val code = conn.responseCode
            val stream = if (code >= 400) conn.errorStream else conn.inputStream
            val text = stream?.bufferedReader(Charsets.UTF_8)?.use { it.readText() }.orEmpty()
            storeCookies(conn)
            RawResponse(code, text)
        } catch (e: ApiError) {
            throw e
        } catch (e: Exception) {
            throw ApiError.Network(e.message ?: "тодорхойгүй алдаа")
        } finally {
            conn.disconnect()
        }
    }

    /** `{ data: … }` дугтуйг задалж дотоод объектыг буцаана. */
    private fun payload(res: RawResponse): JSONObject {
        val json = runCatching { JSONObject(res.body) }.getOrNull()
        if (res.code >= 400) {
            throw ApiError.Http(res.code, json?.optString("message").orEmpty())
        }
        val data = json?.optJSONObject("data") ?: throw ApiError.Decoding()
        return data
    }

    // MARK: - Cookie (WebView-ийн store)

    private fun cookieHeader(): String? =
        CookieManager.getInstance().getCookie(baseUrl)?.takeIf { it.isNotBlank() }

    private fun storeCookies(conn: HttpURLConnection) {
        val cookies = CookieManager.getInstance()
        var changed = false
        for ((name, values) in conn.headerFields) {
            if (name == null || !name.equals("Set-Cookie", ignoreCase = true)) continue
            for (value in values) {
                cookies.setCookie(baseUrl, value)
                changed = true
            }
        }
        if (changed) cookies.flush()
    }
}
