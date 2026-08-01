# Gerege Template Platform V3.0 — Windows App

> 🌐 **Монгол** · [中文](README_ZH.md) · [Русский](README_RU.md)

**Gerege Template Platform V3.0**-ийн **native Windows клиент** (WinUI 3 ·
.NET 8). Вэбийг ачаалдаггүй — өөрийн native дэлгэцтэй.

Хамрах хүрээ нь зориудаар нарийн: **нэвтрэх** ба **хяналтын самбар** хоёрхон
дэлгэц. Энэ бол бүрэн апп биш, **суурь загвар**.

## Урсгал

```
Нэвтрэх дэлгэц
   │  «Gerege SSO-оор нэвтрэх»
   ▼
WebView2 → /api/auth/sso/start → Gerege SSO → /sso/callback (cookie суулгана)
   │  BFF нь /me/... руу шилжүүлэх агшинд навигацыг ЗОГСООНО
   ▼
cookie → CookieContainer → native Хяналтын самбар (/api/me, /api/me/eid/summary)
```

- Апп нь Go backend-тэй **шууд харьцахгүй** — бүх хүсэлт платформын Next.js
  BFF-ээр явна.
- Session нь **httpOnly cookie**. Токен клиент код руу **хэзээ ч гарахгүй**.
- SSO дээр **өөрийн OIDC client бүртгүүлэхгүй** — вэб client-ийн логикийг тэр
  чигт нь ашиглана.
- Вэб дашбоардыг апп дотор **рендэрлэхгүй** — WebView2 зөвхөн нэвтрэлтийн үед.

macOS клиенттэй **урсгал, өгөгдлийн модель, дизайны токен нь ижил** — зөвхөн
платформын API өөр (`WKWebView` → `WebView2`, `HTTPCookieStorage` →
`CookieContainer`).

## Бүтэц

```
src/GeregeDesktop.Client/
  App.xaml(.cs)              аппын эхлэх цэг
  MainWindow.xaml(.cs)       навигаци — шалгаж байна → нэвтрэх → самбар
  Design/Tokens.xaml         өнгө · зай · радиус · типографи · примитивүүд
  Core/ApiClient.cs          BFF клиент (CookieContainer, x-dgov-csrf)
  Domain/Models.cs           MeUser · EidBlock · GoogleBlock · EidSummary
  Features/Login/            LoginPage — split layout + WebView2 SSO
  Features/Dashboard/        DashboardPage
```

> **Нэг project.** eid-platform-mn нь 5 project-д (Domain · Application ·
> Infrastructure · Presentation · Client) хуваадаг. Хоёрхон дэлгэцэд тэр нь хэт
> хүнд тул энд **давхаргалалтыг хавтсаар** барив — концепц нь ижил, ceremony нь
> бага. Апп өсөхөд project болгон салгахад бэлэн.

## Дизайны токенууд

**`Design/Tokens.xaml` нь `frontend/src/app/globals.css`-тэй lockstep-д байна** —
macOS клиентийн `Tokens.swift`-тэй мөн ижил утгатай. Энэ файлаас гадуур шинэ
өнгө бүү нэмэгтүн.

Дэг журмыг [eid-platform-mn](https://github.com/gerege-systems/eid-platform-mn)-
ийн Windows клиентээс авав (`ThemeDictionaries` дотор Light/Dark, дараа нь
brush · spacing · radius · typography · component style).

## Хөгжүүлэлт

```powershell
cd desktop\windows-app
dotnet restore GeregeDesktop.sln
dotnet build GeregeDesktop.sln -c Debug -p:Platform=x64
dotnet run --project src\GeregeDesktop.Client -p:Platform=x64
```

Visual Studio 2022 (17.11+) дээр `GeregeDesktop.sln`-ийг нээж болно.

### Серверийг сонгох

Үндсэн хаяг нь `https://public.template.gerege.mn`. Локал frontend рүү заах бол:

```powershell
$env:GEREGE_APP_URL = "http://localhost:3000"
dotnet run --project src\GeregeDesktop.Client -p:Platform=x64
```

## Шаардлага

- Windows 10 (1809 / build 17763) буюу түүнээс дээш
- .NET 8 SDK
- **WebView2 Runtime** — Windows 11-д суурин; Windows 10-д
  [Microsoft-оос](https://developer.microsoft.com/microsoft-edge/webview2/)
  суулгана. Байхгүй бол SSO товч дарахад апп ойлгомжтой алдаа харуулна.
- **Windows App SDK Runtime** — project нь framework-dependent (энгийн
  `dotnet build` нь RuntimeIdentifier шаардахгүй байхын тулд). Тараахдаа
  бие даасан болгох бол RID-тай нийтэлнэ:

  ```powershell
  dotnet publish src\GeregeDesktop.Client -c Release -r win-x64 `
    -p:WindowsAppSDKSelfContained=true -p:SelfContained=true
  ```

> **Build нь зөвхөн Windows дээр.** WinUI project-ийг macOS/Linux дээр компиляц
> хийх боломжгүй (WindowsAppSDK target, XAML компилятор). Тиймээс CI-д
> `desktop-windows` job (windows runner) байдаг — тэр нь компиляцын гол
> баталгаа.

## Хязгаарлалт

- **Хоёрхон дэлгэц** (нэвтрэх · самбар).
- **Суулгацгүй (unpackaged)** горим — `WindowsPackageType=None`. MSIX багц
  шаардвал `Package.appxmanifest` нэмнэ.
- **Авто-шинэчлэлт байхгүй**, **гарын үсэг зураагүй** (SmartScreen анхааруулна).
- `TreatWarningsAsErrors` нь түр `false` — Windows дээр нэг удаа цэвэр build
  хийсний дараа `true` болгоно (`Directory.Build.props`).

## Холбоотой

- [desktop/macos-app/README.md](../macos-app/README.md) — macOS клиент
- [mobile/ios/TemplateApp/README.md](../../mobile/ios/TemplateApp/README.md) — iOS клиент
- [mobile/android/TemplateApp/README.md](../../mobile/android/TemplateApp/README.md) — Android клиент
- [frontend/README.md](../../frontend/README.md) — вэб апп ба BFF
