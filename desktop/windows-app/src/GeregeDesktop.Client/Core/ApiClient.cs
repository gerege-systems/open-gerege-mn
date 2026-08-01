// Gerege Template Platform V3.0
// Gerege Systems Development Team болон Claude AI хамтран бүтээв, 2026.

// BFF клиент.
//
// Апп нь Go backend-тэй ШУУД харьцахгүй — бүх хүсэлт платформын Next.js BFF-ээр
// явна (вэб, iOS, macOS-той яг ижил). Session нь httpOnly cookie
// (`dgov_access` / `dgov_refresh`): CookieContainer түүнийг хадгалж дараагийн
// хүсэлтэд өөрөө хавсаргана. Токен клиент код руу ХЭЗЭЭ Ч гарахгүй.
//
// BFF-ийн өөрчлөх route-ууд `x-dgov-csrf` header шаарддаг — native клиентэд
// Origin header байхгүй тул `checkOrigin` үүнийг л шалгана.

using System.Net;
using System.Text;
using System.Text.Json;
using GeregeDesktop.Client.Domain;

namespace GeregeDesktop.Client.Core;

internal sealed class ApiClient
{
    public static ApiClient Shared { get; } = new();

    /// <summary>
    /// Платформын BFF. `GEREGE_APP_URL` орчны хувьсагчаар дарж болно
    /// (локал `npm run dev` → http://localhost:3000).
    /// </summary>
    public static Uri BaseUrl { get; } = ResolveBaseUrl();

    private static Uri ResolveBaseUrl()
    {
        var raw = Environment.GetEnvironmentVariable("GEREGE_APP_URL");
        if (!string.IsNullOrWhiteSpace(raw)
            && Uri.TryCreate(raw.Trim(), UriKind.Absolute, out var parsed)
            && (parsed.Scheme == Uri.UriSchemeHttp || parsed.Scheme == Uri.UriSchemeHttps))
        {
            return parsed;
        }
        return new Uri("https://public.template.gerege.mn");
    }

    private readonly HttpClient _http;

    /// <summary>WebView2-оос хуулсан cookie энд хадгалагдана.</summary>
    public CookieContainer Cookies { get; } = new();

    private ApiClient()
    {
        var handler = new HttpClientHandler
        {
            CookieContainer = Cookies,
            UseCookies = true,
            AllowAutoRedirect = true,
        };
        _http = new HttpClient(handler) { BaseAddress = BaseUrl };
        _http.DefaultRequestHeaders.Add("Accept", "application/json");
    }

    private static readonly JsonSerializerOptions JsonOptions = new()
    {
        PropertyNameCaseInsensitive = true,
    };

    private async Task<(string Body, HttpStatusCode Status)> RequestAsync(
        string path, HttpMethod? method = null, object? body = null, CancellationToken ct = default)
    {
        method ??= HttpMethod.Get;
        using var req = new HttpRequestMessage(method, path);
        if (method != HttpMethod.Get)
        {
            req.Headers.Add("x-dgov-csrf", "1");
            var json = JsonSerializer.Serialize(body ?? new { });
            req.Content = new StringContent(json, Encoding.UTF8, "application/json");
        }

        using var resp = await _http.SendAsync(req, ct).ConfigureAwait(false);
        var text = await resp.Content.ReadAsStringAsync(ct).ConfigureAwait(false);
        return (text, resp.StatusCode);
    }

    private static T? Unwrap<T>(string body)
    {
        var env = JsonSerializer.Deserialize<Envelope<T>>(body, JsonOptions);
        return env is null ? default : env.Data;
    }

    /// <summary>GET /api/me → хэрэглэгчийн профайл. Нэвтрээгүй бол null.</summary>
    public async Task<MeUser?> MeAsync(CancellationToken ct = default)
    {
        try
        {
            var (body, status) = await RequestAsync("/api/me", ct: ct).ConfigureAwait(false);
            if ((int)status >= 400) return null;
            return Unwrap<MeWrapper>(body)?.User;
        }
        catch (HttpRequestException)
        {
            return null;
        }
        catch (TaskCanceledException)
        {
            return null;
        }
    }

    /// <summary>
    /// eID нэгдсэн тоо. PKI_READ эрхгүй хэрэглэгчид 403 — энэ нь алдаа биш тул null.
    /// </summary>
    public async Task<EidSummary?> EidSummaryAsync(CancellationToken ct = default)
    {
        try
        {
            var (body, status) = await RequestAsync("/api/me/eid/summary", ct: ct).ConfigureAwait(false);
            if ((int)status >= 400) return null;
            return Unwrap<EidSummary>(body);
        }
        catch (HttpRequestException)
        {
            return null;
        }
        catch (TaskCanceledException)
        {
            return null;
        }
    }

    public async Task LogoutAsync(CancellationToken ct = default)
    {
        try
        {
            await RequestAsync("/api/auth/logout", HttpMethod.Post, new { }, ct).ConfigureAwait(false);
        }
        catch (HttpRequestException)
        {
            // Сервер хүрэхгүй байсан ч локал cookie-г цэвэрлэнэ.
        }
        catch (TaskCanceledException)
        {
        }

        foreach (Cookie cookie in Cookies.GetCookies(BaseUrl))
        {
            cookie.Expired = true;
        }
    }

    /// <summary>WebView2-оос авсан cookie-г HttpClient-ийн сан руу хуулна.</summary>
    public void AdoptCookie(string name, string value, string domain, string path)
    {
        try
        {
            Cookies.Add(new Cookie(name, value, string.IsNullOrEmpty(path) ? "/" : path, domain));
        }
        catch (CookieException)
        {
            // Домэйн тохирохгүй cookie — алгасна (BFF-ийнх биш).
        }
    }
}
