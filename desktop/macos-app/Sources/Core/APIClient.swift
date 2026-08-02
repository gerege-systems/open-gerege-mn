// Gerege Template Platform V3.0
// Gerege Systems Development Team болон Claude AI хамтран бүтээв, 2026.

// BFF клиент.
//
// Апп нь Go backend-тэй ШУУД харьцахгүй — бүх хүсэлт платформын Next.js BFF-ээр
// явна (вэб, iOS-той яг ижил). Session нь httpOnly cookie (`dgov_access` /
// `dgov_refresh`): URLSession түүнийг `HTTPCookieStorage.shared`-д хадгалж
// дараагийн хүсэлтэд өөрөө хавсаргана. Токен клиент код руу ХЭЗЭЭ Ч гарахгүй.
//
// BFF-ийн өөрчлөх (mutating) route-ууд `x-dgov-csrf` header шаарддаг —
// native клиентэд Origin header байхгүй тул `checkOrigin` үүнийг л шалгана.

import Foundation

enum APIError: Error, LocalizedError {
    case http(Int, String)
    case decoding
    case network(String)

    var errorDescription: String? {
        switch self {
        case .http(let code, let msg):
            return msg.isEmpty ? "Алдаа (\(code))." : "Алдаа (\(code)): \(msg)"
        case .decoding:
            return "Серверийн хариуг задлахад алдаа гарлаа."
        case .network(let msg):
            return "Сүлжээний алдаа: \(msg)"
        }
    }
}

final class APIClient {
    static let shared = APIClient()

    /// Платформын BFF. Энэ репогийн жишиг deployment.
    /// `GEREGE_APP_URL` орчны хувьсагчаар дарж болно (локал `npm run dev` → :3000).
    static let baseURL: URL = {
        if let raw = ProcessInfo.processInfo.environment["GEREGE_APP_URL"],
           let url = URL(string: raw.trimmingCharacters(in: .whitespaces)),
           url.scheme == "http" || url.scheme == "https" {
            return url
        }
        return URL(string: "https://open.gerege.mn")!
    }()

    private let session: URLSession

    private init() {
        let cfg = URLSessionConfiguration.default
        cfg.httpCookieStorage = HTTPCookieStorage.shared
        cfg.httpCookieAcceptPolicy = .always
        cfg.httpShouldSetCookies = true
        // Профайлын хариу кэшлэгдвэл гарсны дараа хуучин өгөгдөл харагдана.
        cfg.requestCachePolicy = .reloadIgnoringLocalCacheData
        session = URLSession(configuration: cfg)
    }

    // MARK: - Хүсэлт

    private func request(_ path: String, method: String = "GET",
                         body: [String: Any]? = nil) async throws -> (Data, HTTPURLResponse) {
        var req = URLRequest(url: Self.baseURL.appendingPathComponent(path))
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        if method != "GET" {
            req.setValue("1", forHTTPHeaderField: "x-dgov-csrf")
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.httpBody = try JSONSerialization.data(withJSONObject: body ?? [:])
        }
        do {
            let (data, resp) = try await session.data(for: req)
            guard let http = resp as? HTTPURLResponse else {
                throw APIError.network("хариу байхгүй")
            }
            return (data, http)
        } catch let err as APIError {
            throw err
        } catch {
            throw APIError.network(error.localizedDescription)
        }
    }

    /// `{ data: T }` дугтуйг задалж `T` буцаана.
    private func decodeData<T: Decodable>(_ data: Data, _ http: HTTPURLResponse) throws -> T {
        if http.statusCode >= 400 {
            let msg = (try? JSONDecoder().decode(Envelope<EmptyPayload>.self, from: data))?.message ?? ""
            throw APIError.http(http.statusCode, msg)
        }
        guard let env = try? JSONDecoder().decode(Envelope<T>.self, from: data),
              let payload = env.data else {
            throw APIError.decoding
        }
        return payload
    }

    private struct EmptyPayload: Decodable {}

    // MARK: - Профайл ба session

    /// Backend `/users/me` нь `data`-г `{ "user": {…} }` гэж боодог.
    private struct MeWrapper: Decodable { let user: MeUser }

    func me() async throws -> MeUser {
        let (data, http) = try await request("/api/me")
        let wrapped: MeWrapper = try decodeData(data, http)
        return wrapped.user
    }

    /// eID нэгдсэн тоо. PKI_READ эрхгүй хэрэглэгчид 403 — энэ нь алдаа биш тул `nil`.
    func eidSummary() async throws -> EidSummary? {
        let (data, http) = try await request("/api/me/eid/summary")
        if http.statusCode == 403 { return nil }
        return try? decodeData(data, http)
    }

    /// Session идэвхтэй эсэх — аппыг нээхэд шалгана.
    func isSignedIn() async -> Bool {
        (try? await me()) != nil
    }

    func logout() async {
        _ = try? await request("/api/auth/logout", method: "POST", body: [:])
        // BFF-ийн домэйны cookie-г локалаас цэвэрлэнэ.
        guard let host = Self.baseURL.host,
              let cookies = HTTPCookieStorage.shared.cookies else { return }
        for c in cookies where host.hasSuffix(c.domain) || c.domain.hasSuffix(host) {
            HTTPCookieStorage.shared.deleteCookie(c)
        }
    }
}
