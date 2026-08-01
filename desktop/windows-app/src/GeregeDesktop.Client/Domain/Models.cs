// Gerege Template Platform V3.0
// Gerege Systems Development Team болон Claude AI хамтран бүтээв, 2026.

// BFF-ийн хариунуудын модель. Талбарын нэр, дугтуйны бүтэц нь macOS клиентийн
// Domain/Models.swift болон ios/TemplateApp-тай ЯГ ижил — гурван native клиент
// нэг backend гэрээтэй.

using System.Text.Json.Serialization;

namespace GeregeDesktop.Client.Domain;

/// <summary>BFF-ийн <c>proxyResult</c> дугтуй — { ok, status, data, message }.</summary>
internal sealed class Envelope<T>
{
    [JsonPropertyName("ok")] public bool? Ok { get; set; }
    [JsonPropertyName("status")] public int? Status { get; set; }
    [JsonPropertyName("message")] public string? Message { get; set; }
    [JsonPropertyName("data")] public T? Data { get; set; }
}

/// <summary>Backend <c>/users/me</c> нь data-г { "user": {…} } гэж боодог.</summary>
internal sealed class MeWrapper
{
    [JsonPropertyName("user")] public MeUser? User { get; set; }
}

internal sealed class MeUser
{
    [JsonPropertyName("id")] public string Id { get; set; } = "";
    [JsonPropertyName("username")] public string Username { get; set; } = "";
    [JsonPropertyName("first_name")] public string? FirstName { get; set; }
    [JsonPropertyName("last_name")] public string? LastName { get; set; }
    [JsonPropertyName("full_name")] public string? FullName { get; set; }
    [JsonPropertyName("full_name_en")] public string? FullNameEn { get; set; }
    [JsonPropertyName("email")] public string? Email { get; set; }
    [JsonPropertyName("role_id")] public int RoleId { get; set; }
    [JsonPropertyName("created_at")] public string? CreatedAt { get; set; }
    [JsonPropertyName("eid")] public EidBlock? Eid { get; set; }
    [JsonPropertyName("google")] public GoogleBlock? Google { get; set; }

    public string DisplayName =>
        string.IsNullOrWhiteSpace(FullName) ? Username : FullName!;

    public string RoleLabel => RoleId switch
    {
        1 => "Супер админ",
        2 => "Админ",
        3 => "Менежер",
        _ => "Хэрэглэгч",
    };

    /// <summary>Дүрсэнд харуулах эхний үсэг.</summary>
    public string Initials
    {
        get
        {
            var parts = DisplayName.Split(' ', StringSplitOptions.RemoveEmptyEntries);
            if (parts.Length == 0) return "—";
            var letters = parts.Take(2).Select(p => char.ToUpperInvariant(p[0]));
            return string.Concat(letters);
        }
    }
}

internal sealed class EidBlock
{
    [JsonPropertyName("civil_id")] public string? CivilId { get; set; }
    [JsonPropertyName("national_id")] public string? NationalId { get; set; }
    [JsonPropertyName("kyc_level")] public string? KycLevel { get; set; }
    [JsonPropertyName("document_number")] public string? DocumentNumber { get; set; }
}

internal sealed class GoogleBlock
{
    [JsonPropertyName("email")] public string? Email { get; set; }
    [JsonPropertyName("name")] public string? Name { get; set; }
    [JsonPropertyName("picture")] public string? Picture { get; set; }
    [JsonPropertyName("email_verified")] public bool? EmailVerified { get; set; }
}

/// <summary>GET /api/me/eid/summary → eID PKI-ийн нэгдсэн тоо.</summary>
internal sealed class EidSummary
{
    [JsonPropertyName("certificates")] public CertCounts Certificates { get; set; } = new();
    [JsonPropertyName("activity")] public ActivityCounts Activity { get; set; } = new();
    [JsonPropertyName("devices_active")] public int DevicesActive { get; set; }
    [JsonPropertyName("devices_total")] public int DevicesTotal { get; set; }
    [JsonPropertyName("representation_count")] public int RepresentationCount { get; set; }

    internal sealed class CertCounts
    {
        [JsonPropertyName("valid")] public int Valid { get; set; }
        [JsonPropertyName("total")] public int Total { get; set; }
    }

    internal sealed class ActivityCounts
    {
        [JsonPropertyName("authentication")] public int Authentication { get; set; }
        [JsonPropertyName("signature")] public int Signature { get; set; }
    }
}
