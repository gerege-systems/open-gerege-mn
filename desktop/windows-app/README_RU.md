# Gerege Template Platform V3.0 — приложение для Windows

> 🌐 [Монгол](README.md) · [中文](README_ZH.md) · **Русский**

**Нативный Windows-клиент** платформы **Gerege Template Platform V3.0**
(WinUI 3 · .NET 8). Веб не загружается — у приложения собственные нативные экраны.

Объём намеренно узкий: всего **два экрана** — вход и дашборд. Это **базовый
шаблон**.

## Поток

```
Экран входа
   │  «Войти через Gerege SSO»
   ▼
WebView2 → /api/auth/sso/start → Gerege SSO → /sso/callback (ставит cookie)
   │  в момент перехода BFF на /me/... навигация ОТМЕНЯЕТСЯ
   ▼
cookie → CookieContainer → нативный дашборд (/api/me, /api/me/eid/summary)
```

- Приложение **не обращается напрямую** к Go-бэкенду — все запросы идут через
  Next.js BFF платформы.
- Сессия — **httpOnly cookie**. Токен **никогда** не попадает в клиентский код.
- **Собственный OIDC-клиент в SSO не регистрируется** — переиспользуется логика
  веб-клиента.
- Веб-дашборд **внутри приложения не рендерится** — WebView2 живёт только во
  время входа.

Поток, модели данных и дизайн-токены **идентичны macOS-клиенту** — отличаются
только платформенные API (`WKWebView` → `WebView2`, `HTTPCookieStorage` →
`CookieContainer`).

## Структура

```
src/GeregeDesktop.Client/
  App.xaml(.cs)              точка входа
  MainWindow.xaml(.cs)       навигация — проверка → вход → дашборд
  Design/Tokens.xaml         цвета · отступы · радиусы · типографика · примитивы
  Core/ApiClient.cs          клиент BFF (CookieContainer, x-dgov-csrf)
  Domain/Models.cs           MeUser · EidBlock · GoogleBlock · EidSummary
  Features/Login/            LoginPage — сплит-раскладка + WebView2 SSO
  Features/Dashboard/        DashboardPage
```

> **Один project.** eid-platform-mn разделён на 5 проектов (Domain · Application ·
> Infrastructure · Presentation · Client). Для двух экранов это избыточно,
> поэтому здесь **слои выражены папками** — концепция та же, церемоний меньше.
> При росте приложения слои легко вынести в отдельные проекты.

## Дизайн-токены

**`Design/Tokens.xaml` держится в lockstep с `frontend/src/app/globals.css`** и
совпадает по значениям с `Tokens.swift` из macOS-клиента. Не добавляйте цвета
вне этого файла.

Подход взят у Windows-клиента
[eid-platform-mn](https://github.com/gerege-systems/eid-platform-mn)
(`ThemeDictionaries` с Light/Dark, затем brush · spacing · radius · typography ·
component style).

## Разработка

```powershell
cd desktop\windows-app
dotnet restore GeregeDesktop.sln
dotnet build GeregeDesktop.sln -c Debug -p:Platform=x64
dotnet run --project src\GeregeDesktop.Client -p:Platform=x64
```

Можно открыть `GeregeDesktop.sln` в Visual Studio 2022 (17.11+).

### Выбор сервера

Адрес по умолчанию — `https://open.gerege.mn`. Указать локальный
frontend:

```powershell
$env:GEREGE_APP_URL = "http://localhost:3000"
dotnet run --project src\GeregeDesktop.Client -p:Platform=x64
```

## Требования

- Windows 10 (1809 / build 17763) и выше
- .NET 8 SDK
- **WebView2 Runtime** — в Windows 11 встроен; в Windows 10 ставится
  [от Microsoft](https://developer.microsoft.com/microsoft-edge/webview2/).
  Если его нет, при нажатии кнопки SSO приложение покажет понятную ошибку.

> **Сборка только на Windows.** WinUI-проект невозможно скомпилировать на
> macOS/Linux (target WindowsAppSDK, компилятор XAML). Поэтому в CI есть job
> `desktop-windows` (windows runner) — он и является основной гарантией сборки.

## Ограничения

- **Только два экрана** (вход · дашборд).
- Режим **без установки (unpackaged)** — `WindowsPackageType=None`. Для MSIX
  добавьте `Package.appxmanifest`.
- **Нет автообновления**, **не подписано** (SmartScreen предупредит).
- `TreatWarningsAsErrors` временно `false` — переключите в `true` после первой
  чистой сборки на Windows (`Directory.Build.props`).

## Связанные документы

- [desktop/macos-app/README_RU.md](../macos-app/README_RU.md) — macOS-клиент
- [mobile/ios/TemplateApp/README_RU.md](../../mobile/ios/TemplateApp/README_RU.md) — iOS-клиент
- [mobile/android/TemplateApp/README_RU.md](../../mobile/android/TemplateApp/README_RU.md) — Android-клиент
