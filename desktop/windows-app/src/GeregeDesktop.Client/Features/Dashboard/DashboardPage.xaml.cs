// Gerege Template Platform V3.0
// Gerege Systems Development Team болон Claude AI хамтран бүтээв, 2026.

// Хяналтын самбарын логик — BFF-ээс ирсэн профайл, eID тоог дэлгэцэнд байрлуулна.

using GeregeDesktop.Client.Core;
using GeregeDesktop.Client.Domain;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;

namespace GeregeDesktop.Client.Features.Dashboard;

public sealed partial class DashboardPage : UserControl
{
    /// <summary>Гарсны дараа — цонх нэвтрэх дэлгэц рүү буцна.</summary>
    public event EventHandler? SignedOut;

    internal DashboardPage(MeUser user, EidSummary? eid)
    {
        InitializeComponent();

        UserNameText.Text = user.DisplayName;
        RoleText.Text = user.RoleLabel;
        InitialsText.Text = user.Initials;

        if (eid is not null)
        {
            StatRow.Visibility = Visibility.Visible;
            CertValue.Text = eid.Certificates.Valid.ToString(System.Globalization.CultureInfo.InvariantCulture);
            CertNote.Text = $"нийт {eid.Certificates.Total}";
            AuthValue.Text = eid.Activity.Authentication.ToString(System.Globalization.CultureInfo.InvariantCulture);
            SignValue.Text = eid.Activity.Signature.ToString(System.Globalization.CultureInfo.InvariantCulture);
            DeviceValue.Text = eid.DevicesActive.ToString(System.Globalization.CultureInfo.InvariantCulture);
            DeviceNote.Text = $"нийт {eid.DevicesTotal}";
        }

        BuildProfileRows(user);
        BuildIdentityRows(user);
    }

    private void BuildProfileRows(MeUser user)
    {
        ProfileRows.Children.Add(DetailRow("Нэр", user.DisplayName));
        if (!string.IsNullOrWhiteSpace(user.FullNameEn))
        {
            ProfileRows.Children.Add(DetailRow("Латинаар", user.FullNameEn!));
        }
        ProfileRows.Children.Add(DetailRow("Хэрэглэгчийн нэр", user.Username, mono: true));
        ProfileRows.Children.Add(DetailRow("И-мэйл", user.Email ?? "—"));
        ProfileRows.Children.Add(DetailRow("Эрх", user.RoleLabel));
    }

    private void BuildIdentityRows(MeUser user)
    {
        if (user.Eid is { } eid)
        {
            EidChip.Visibility = Visibility.Visible;
            IdentityRows.Children.Add(DetailRow("Регистр", eid.CivilId ?? "—", mono: true));
            IdentityRows.Children.Add(DetailRow("Үндэсний дугаар", eid.NationalId ?? "—", mono: true));
            IdentityRows.Children.Add(DetailRow("Баримтын дугаар", eid.DocumentNumber ?? "—", mono: true));
            IdentityRows.Children.Add(DetailRow("KYC түвшин", eid.KycLevel ?? "—"));
        }
        else
        {
            IdentityRows.Children.Add(new TextBlock
            {
                Text = "eID-ээр баталгаажаагүй байна.",
                Style = (Style)Application.Current.Resources["BodyText"],
            });
        }

        if (user.Google?.Email is { } googleEmail)
        {
            IdentityRows.Children.Add(new Border
            {
                Height = 1,
                Margin = new Thickness(0, 8, 0, 8),
                Background = (Microsoft.UI.Xaml.Media.Brush)Application.Current.Resources["BorderBrush2"],
            });
            IdentityRows.Children.Add(DetailRow("Google", googleEmail));
        }
    }

    /// <summary>Нэр → утга мөр (macOS клиентийн DetailRow-тэй ижил хэмжээ).</summary>
    private static Grid DetailRow(string label, string value, bool mono = false)
    {
        var grid = new Grid();
        grid.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(132) });
        grid.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });

        var labelBlock = new TextBlock
        {
            Text = label,
            Style = (Style)Application.Current.Resources["LabelText"],
        };
        Grid.SetColumn(labelBlock, 0);

        var valueBlock = new TextBlock
        {
            Text = value,
            TextWrapping = TextWrapping.Wrap,
            IsTextSelectionEnabled = true,
            Style = mono
                ? (Style)Application.Current.Resources["MonoText"]
                : null,
        };
        if (!mono)
        {
            valueBlock.FontSize = 14;
            valueBlock.Foreground = (Microsoft.UI.Xaml.Media.Brush)Application.Current.Resources["FgBrush"];
        }
        Grid.SetColumn(valueBlock, 1);

        grid.Children.Add(labelBlock);
        grid.Children.Add(valueBlock);
        return grid;
    }

    private async void OnSignOut(object sender, RoutedEventArgs e)
    {
        await ApiClient.Shared.LogoutAsync().ConfigureAwait(true);
        SignedOut?.Invoke(this, EventArgs.Empty);
    }
}
