// Gerege Template Platform V3.0
// Gerege Systems Development Team болон Claude AI хамтран бүтээв, 2026.

package mn.gerege.temp

import org.json.JSONObject

// Backend-ийн бүх хариу дугтуй (envelope)-д ирнэ — BFF proxyResult
// { ok, status, data, message }. Reflection-д тулгуурласан JSON сан ашиглахгүй
// тул модель бүр өөрийн `fromJson`-той (iOS талын Codable-ийн дүйцэл).

/** `null` эсвэл JSON `null` бол Kotlin `null` болгож буцаана. */
private fun JSONObject.str(key: String): String? =
    if (isNull(key)) null else optString(key, "").ifEmpty { null }

private fun JSONObject.obj(key: String): JSONObject? =
    if (isNull(key)) null else optJSONObject(key)

/** GET /api/me → хэрэглэгчийн профайл. */
data class MeUser(
    val id: String,
    val username: String,
    val firstName: String?,
    val lastName: String?,
    val fullName: String?,
    val fullNameEn: String?,
    val email: String?,
    val roleId: Int,
    val createdAt: String?,
    val eid: EidBlock?,
    val google: GoogleBlock?,
) {
    val displayName: String
        get() = fullName?.trim()?.takeIf { it.isNotEmpty() } ?: username

    val roleLabel: String
        get() = when (roleId) {
            1 -> "Супер админ"
            2 -> "Админ"
            3 -> "Менежер"
            else -> "Хэрэглэгч"
        }

    companion object {
        fun fromJson(json: JSONObject) = MeUser(
            id = json.str("id") ?: "",
            username = json.str("username") ?: "",
            firstName = json.str("first_name"),
            lastName = json.str("last_name"),
            fullName = json.str("full_name"),
            fullNameEn = json.str("full_name_en"),
            email = json.str("email"),
            roleId = json.optInt("role_id", 0),
            createdAt = json.str("created_at"),
            eid = json.obj("eid")?.let(EidBlock::fromJson),
            google = json.obj("google")?.let(GoogleBlock::fromJson),
        )
    }
}

data class EidBlock(
    val civilId: String?,
    val nationalId: String?,
    val kycLevel: String?,
    val documentNumber: String?,
) {
    /** Хоосон eID блокийг дэлгэцэнд огт харуулахгүй (iOS-той ижил дүрэм). */
    val hasIdentity: Boolean get() = civilId != null || nationalId != null

    companion object {
        fun fromJson(json: JSONObject) = EidBlock(
            civilId = json.str("civil_id"),
            nationalId = json.str("national_id"),
            kycLevel = json.str("kyc_level"),
            documentNumber = json.str("document_number"),
        )
    }
}

data class GoogleBlock(
    val email: String?,
    val name: String?,
    val picture: String?,
    val emailVerified: Boolean?,
) {
    companion object {
        fun fromJson(json: JSONObject) = GoogleBlock(
            email = json.str("email"),
            name = json.str("name"),
            picture = json.str("picture"),
            emailVerified = if (json.isNull("email_verified")) null else json.optBoolean("email_verified"),
        )
    }
}

/** GET /api/me/eid/summary → eID PKI нэгдсэн тоо. */
data class EidSummary(
    val certificatesValid: Int,
    val certificatesTotal: Int,
    val authenticationCount: Int,
    val signatureCount: Int,
    val devicesActive: Int,
    val devicesTotal: Int,
    val representationCount: Int,
) {
    companion object {
        fun fromJson(json: JSONObject): EidSummary {
            val certs = json.optJSONObject("certificates")
            val activity = json.optJSONObject("activity")
            return EidSummary(
                certificatesValid = certs?.optInt("valid", 0) ?: 0,
                certificatesTotal = certs?.optInt("total", 0) ?: 0,
                authenticationCount = activity?.optInt("authentication", 0) ?: 0,
                signatureCount = activity?.optInt("signature", 0) ?: 0,
                devicesActive = json.optInt("devices_active", 0),
                devicesTotal = json.optInt("devices_total", 0),
                representationCount = json.optInt("representation_count", 0),
            )
        }
    }
}
