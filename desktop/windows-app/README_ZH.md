# Gerege Template Platform V3.0 — Windows 应用

> 🌐 [Монгол](README.md) · **中文** · [Русский](README_RU.md)

**Gerege Template Platform V3.0** 的**原生 Windows 客户端**（WinUI 3 · .NET 8）。
不加载 Web —— 拥有自己的原生界面。

范围是刻意收窄的：只有**登录**与**仪表盘**两个页面。这是**基础模板**。

## 流程

```
登录页
   │  「使用 Gerege SSO 登录」
   ▼
WebView2 → /api/auth/sso/start → Gerege SSO → /sso/callback（写入 cookie）
   │  BFF 跳转到 /me/... 的瞬间取消导航
   ▼
cookie → CookieContainer → 原生仪表盘（/api/me、/api/me/eid/summary）
```

- 应用**不直接**访问 Go 后端 —— 所有请求都经平台的 Next.js BFF。
- 会话是 **httpOnly cookie**。令牌**永远不会**进入客户端代码。
- **不在 SSO 上注册自己的 OIDC client** —— 直接复用 Web client 的逻辑。
- **不在应用内渲染** Web 仪表盘 —— WebView2 只在登录期间存在。

与 macOS 客户端的**流程、数据模型、设计令牌完全一致**，只有平台 API 不同
（`WKWebView` → `WebView2`，`HTTPCookieStorage` → `CookieContainer`）。

## 结构

```
src/GeregeDesktop.Client/
  App.xaml(.cs)              入口
  MainWindow.xaml(.cs)       导航 —— 检查中 → 登录 → 仪表盘
  Design/Tokens.xaml         颜色 · 间距 · 圆角 · 排版 · 基础组件
  Core/ApiClient.cs          BFF 客户端（CookieContainer、x-dgov-csrf）
  Domain/Models.cs           MeUser · EidBlock · GoogleBlock · EidSummary
  Features/Login/            LoginPage —— 分栏布局 + WebView2 SSO
  Features/Dashboard/        DashboardPage
```

> **单一 project。** eid-platform-mn 拆成 5 个 project（Domain · Application ·
> Infrastructure · Presentation · Client）。对两个页面而言过重，因此这里**用文件夹
> 表达分层** —— 概念相同、仪式更少。应用变大后可随时拆分为独立 project。

## 设计令牌

**`Design/Tokens.xaml` 与 `frontend/src/app/globals.css` 保持 lockstep**，并与
macOS 客户端的 `Tokens.swift` 数值一致。不要在此文件之外新增颜色。

做法取自 [eid-platform-mn](https://github.com/gerege-systems/eid-platform-mn)
的 Windows 客户端（`ThemeDictionaries` 中的 Light/Dark，随后是 brush · spacing ·
radius · typography · component style）。

## 开发

```powershell
cd desktop\windows-app
dotnet restore GeregeDesktop.sln
dotnet build GeregeDesktop.sln -c Debug -p:Platform=x64
dotnet run --project src\GeregeDesktop.Client -p:Platform=x64
```

也可用 Visual Studio 2022（17.11+）打开 `GeregeDesktop.sln`。

### 选择服务器

默认地址为 `https://open.gerege.mn`。指向本地 frontend：

```powershell
$env:GEREGE_APP_URL = "http://localhost:3000"
dotnet run --project src\GeregeDesktop.Client -p:Platform=x64
```

## 要求

- Windows 10（1809 / build 17763）及以上
- .NET 8 SDK
- **WebView2 Runtime** —— Windows 11 自带；Windows 10 需从
  [Microsoft](https://developer.microsoft.com/microsoft-edge/webview2/) 安装。
  缺失时点击 SSO 按钮会给出明确错误提示。

> **只能在 Windows 上构建。** WinUI project 无法在 macOS/Linux 上编译
> （WindowsAppSDK target、XAML 编译器）。因此 CI 中有 `desktop-windows` job
> （windows runner）—— 它是编译的主要保证。

## 限制

- **仅两个页面**（登录 · 仪表盘）。
- **免安装（unpackaged）**模式 —— `WindowsPackageType=None`。如需 MSIX，请添加
  `Package.appxmanifest`。
- **无自动更新**、**未签名**（SmartScreen 会警告）。
- `TreatWarningsAsErrors` 暂为 `false` —— 在 Windows 上完成一次干净构建后改为
  `true`（`Directory.Build.props`）。

## 相关文档

- [desktop/macos-app/README_ZH.md](../macos-app/README_ZH.md) —— macOS 客户端
- [mobile/ios/TemplateApp/README_ZH.md](../../mobile/ios/TemplateApp/README_ZH.md) —— iOS 客户端
- [mobile/android/TemplateApp/README_ZH.md](../../mobile/android/TemplateApp/README_ZH.md) —— Android 客户端
