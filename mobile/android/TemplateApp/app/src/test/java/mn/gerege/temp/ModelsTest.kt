// Gerege Template Platform V3.0
// Gerege Systems Development Team болон Claude AI хамтран бүтээв, 2026.

package mn.gerege.temp

import org.json.JSONObject
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

// Backend snake_case → модель. JSON `null` нь Kotlin `null` болох, дутуу талбар
// апп-ыг унагаахгүй байхыг тулгана (BFF нь эрхээс хамаарч талбар хасдаг).
class ModelsTest {

    @Test
    fun `хэрэглэгчийн бүрэн хариу задарна`() {
        val json = JSONObject(
            """
            {
              "id": "u-1", "username": "batbold", "first_name": "Батболд",
              "last_name": "Дорж", "full_name": "Дорж Батболд",
              "full_name_en": "Dorj Batbold", "email": "b@example.mn",
              "role_id": 2, "created_at": "2026-01-05T10:00:00Z",
              "eid": { "civil_id": "УБ12345678", "national_id": "аа99887766",
                       "kyc_level": "high", "document_number": "0123456789ABCDEF0123" },
              "google": { "email": "b@gmail.com", "name": "Batbold", "email_verified": true }
            }
            """.trimIndent(),
        )

        val user = MeUser.fromJson(json)

        assertEquals("Дорж Батболд", user.displayName)
        assertEquals("Админ", user.roleLabel)
        assertEquals("b@example.mn", user.email)
        assertEquals("УБ12345678", user.eid?.civilId)
        assertTrue(user.eid?.hasIdentity == true)
        assertEquals(true, user.google?.emailVerified)
    }

    @Test
    fun `дутуу ба null талбарууд алдаа өгөхгүй`() {
        val json = JSONObject("""{ "id": "u-2", "username": "guest", "full_name": null, "role_id": 4 }""")

        val user = MeUser.fromJson(json)

        assertEquals("guest", user.displayName) // full_name байхгүй → username
        assertEquals("Хэрэглэгч", user.roleLabel)
        assertNull(user.email)
        assertNull(user.eid)
        assertNull(user.google)
    }

    @Test
    fun `хоосон eID блокийг identity гэж тооцохгүй`() {
        val eid = EidBlock.fromJson(JSONObject("""{ "civil_id": null, "national_id": "" }"""))
        assertFalse(eid.hasIdentity)
    }

    @Test
    fun `eID PKI нэгдсэн тоо задарна`() {
        val json = JSONObject(
            """
            {
              "certificates": { "valid": 2, "total": 3 },
              "activity": { "authentication": 12, "signature": 4 },
              "devices_active": 1, "devices_total": 2, "representation_count": 5
            }
            """.trimIndent(),
        )

        val summary = EidSummary.fromJson(json)

        assertEquals(2, summary.certificatesValid)
        assertEquals(3, summary.certificatesTotal)
        assertEquals(12, summary.authenticationCount)
        assertEquals(4, summary.signatureCount)
        assertEquals(1, summary.devicesActive)
        assertEquals(5, summary.representationCount)
    }

    @Test
    fun `дэд объект дутуу бол тэг утгаар бөглөнө`() {
        val summary = EidSummary.fromJson(JSONObject("{}"))
        assertEquals(0, summary.certificatesTotal)
        assertEquals(0, summary.representationCount)
    }
}
