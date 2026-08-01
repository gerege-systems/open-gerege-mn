// Gerege Template Platform V3.0
// Gerege Systems Development Team болон Claude AI хамтран бүтээв, 2026.

// Gerege SSO нэвтрэлт — вэбтэй ЯГ ИЖИЛ урсгал, бүхэлдээ платформын BFF-ээр:
//
//   /api/auth/sso/start → Gerege SSO (нэвтрэлт) → /sso/callback (cookie суулгана)
//   → /me/dashboard
//
// Апп нь SSO дээр ӨӨРИЙН OIDC client бүртгүүлэхгүй (native/PKCE урсгал байхгүй) —
// вэб client-ийн логикийг тэр чигт нь ашиглана.
//
// Дашбоард руу шилжих АГШИНД навигацыг зогсоож, WebView2-ийн cookie-г
// ApiClient-ийн CookieContainer руу хуулна. Вэб дашбоардыг апп дотор
// РЕНДЭРЛЭХГҮЙ — native дэлгэц рүү шилжинэ.
//
// Энэ нь macOS клиентийн `SSOWebView.swift`-ийн Windows эквивалент:
// WKWebView → WebView2, HTTPCookieStorage → CookieContainer.

using GeregeDesktop.Client.Core;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.Web.WebView2.Core;

namespace GeregeDesktop.Client.Features.Login;

public sealed partial class LoginPage : UserControl
{
    /// <summary>Нэвтрэлт амжилттай дуусахад — цонх дашбоард руу шилжинэ.</summary>
    public event EventHandler? SignedIn;

    private bool _finished;

    public LoginPage()
    {
        InitializeComponent();
        HostText.Text = ApiClient.BaseUrl.Host;
    }

    private async void OnSsoClick(object sender, RoutedEventArgs e)
    {
        ErrorText.Visibility = Visibility.Collapsed;
        _finished = false;

        try
        {
            SsoOverlay.Visibility = Visibility.Visible;
            await SsoWebView.EnsureCoreWebView2Async();
            SsoWebView.CoreWebView2.NavigationStarting += OnNavigationStarting;
            SsoWebView.CoreWebView2.Navigate(new Uri(ApiClient.BaseUrl, "/api/auth/sso/start").ToString());
        }
        catch (Exception ex)
        {
            // WebView2 Runtime суулгаагүй бол энд унана — хэрэглэгчид ойлгомжтой хэлнэ.
            SsoOverlay.Visibility = Visibility.Collapsed;
            ShowError($"SSO цонхыг нээж чадсангүй. WebView2 Runtime суусан эсэхийг шалгана уу. ({ex.Message})");
        }
    }

    private void OnNavigationStarting(CoreWebView2 sender, CoreWebView2NavigationStartingEventArgs args)
    {
        if (_finished) return;
        if (!Uri.TryCreate(args.Uri, UriKind.Absolute, out var uri)) return;

        // Cookie суусны дараа BFF нь /me/... руу шилжүүлнэ — яг энд зогсооно.
        if (uri.Host == ApiClient.BaseUrl.Host && uri.AbsolutePath.StartsWith("/me", StringComparison.Ordinal))
        {
            _finished = true;
            args.Cancel = true;
            DispatcherQueue.TryEnqueue(async () => await CompleteAsync().ConfigureAwait(true));
        }
    }

    private async Task CompleteAsync()
    {
        await SyncCookiesAsync().ConfigureAwait(true);
        SsoOverlay.Visibility = Visibility.Collapsed;
        SignedIn?.Invoke(this, EventArgs.Empty);
    }

    /// <summary>WebView2-ийн cookie сан → ApiClient.CookieContainer (HttpClient уншина).</summary>
    private async Task SyncCookiesAsync()
    {
        var manager = SsoWebView.CoreWebView2.CookieManager;
        var cookies = await manager.GetCookiesAsync(ApiClient.BaseUrl.ToString());
        foreach (var cookie in cookies)
        {
            ApiClient.Shared.AdoptCookie(cookie.Name, cookie.Value, cookie.Domain, cookie.Path);
        }
    }

    private void OnCancelSso(object sender, RoutedEventArgs e)
    {
        _finished = true;
        SsoOverlay.Visibility = Visibility.Collapsed;
    }

    private void ShowError(string message)
    {
        ErrorText.Text = message;
        ErrorText.Visibility = Visibility.Visible;
    }
}
