// Gerege Template Platform V3.0
// Gerege Systems Development Team болон Claude AI хамтран бүтээв, 2026.

// Цонхны навигаци: шалгаж байна → нэвтрэх → хяналтын самбар.
// macOS клиентийн `AppState.Phase`-тэй ижил гурван үе шат.

using GeregeDesktop.Client.Core;
using GeregeDesktop.Client.Features.Dashboard;
using GeregeDesktop.Client.Features.Login;
using Microsoft.UI.Xaml;

namespace GeregeDesktop.Client;

public sealed partial class MainWindow : Window
{
    public MainWindow()
    {
        InitializeComponent();
        _ = BootstrapAsync();
    }

    /// <summary>Апп нээгдэхэд хадгалсан cookie-гоор session амьд эсэхийг шалгана.</summary>
    private async Task BootstrapAsync()
    {
        var user = await ApiClient.Shared.MeAsync().ConfigureAwait(true);
        if (user is null)
        {
            ShowLogin();
        }
        else
        {
            await ShowDashboardAsync().ConfigureAwait(true);
        }
    }

    private void ShowLogin()
    {
        var page = new LoginPage();
        page.SignedIn += async (_, _) => await ShowDashboardAsync().ConfigureAwait(true);
        SwapPage(page);
    }

    private async Task ShowDashboardAsync()
    {
        var user = await ApiClient.Shared.MeAsync().ConfigureAwait(true);
        if (user is null)
        {
            // Session хүчингүй болсон — буцаад нэвтрэх рүү.
            ShowLogin();
            return;
        }

        var eid = await ApiClient.Shared.EidSummaryAsync().ConfigureAwait(true);
        var page = new DashboardPage(user, eid);
        page.SignedOut += (_, _) => ShowLogin();
        SwapPage(page);
    }

    private void SwapPage(UIElement page)
    {
        PageHost.Content = page;
        PageHost.Visibility = Visibility.Visible;
        SplashPanel.Visibility = Visibility.Collapsed;
    }
}
