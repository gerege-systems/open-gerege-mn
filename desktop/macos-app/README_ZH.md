# Gerege Template Platform V3.0 — macOS 应用

> 🌐 [Монгол](README.md) · **中文** · [Русский](README_RU.md)

**Gerege Template Platform V3.0** 的**原生 macOS 客户端**（SwiftUI）。不加载
Web —— 拥有自己的原生界面。

范围是刻意收窄的：只有**登录**与**仪表盘**两个页面。这不是一个完整应用，而是
**基础模板** —— 在其之上添加你自己的业务页面。

## 流程

```
登录页
   │  「使用 Gerege SSO 登录」
   ▼
WKWebView → /api/auth/sso/start → Gerege SSO → /sso/callback（写入 cookie）
   │  BFF 跳转到 /me/... 的瞬间取消导航
   ▼
cookie → HTTPCookieStorage → 原生仪表盘（/api/me、/api/me/eid/summary）
```

- 应用**不直接**访问 Go 后端 —— 所有请求都经平台的 Next.js BFF（与 Web、iOS 相同）。
- 会话是 **httpOnly cookie**（`dgov_access` / `dgov_refresh`）。令牌**永远不会**
  进入客户端代码，也不会保存在应用中。
- **不在 SSO 上注册自己的 OIDC client**（没有 native/PKCE 流程）—— 直接复用 Web
  client 的逻辑，使登录策略只存在于一处（BFF）。
- **不在应用内渲染** Web 仪表盘 —— WebView 只在登录期间存在。

## 结构

```
Sources/
  App/
    GeregeDesktopApp.swift   入口 + RootView（三个阶段）
    AppState.swift           登录状态、加载资料
  Design/
    Tokens.swift             颜色 · 间距 · 圆角 · 排版
    Components.swift         AppCard · 按钮样式 · Chip · DetailRow
  Core/
    APIClient.swift          BFF 客户端（cookie 会话、x-dgov-csrf）
  Domain/
    Models.swift             MeUser · EidBlock · GoogleBlock · EidSummary
  Features/
    Login/LoginView.swift    分栏布局 —— 品牌面板 + 登录卡片
    Login/SSOWebView.swift   WKWebView + cookie 同步
    Dashboard/DashboardView.swift
project.yml                  xcodegen 定义（仓库中**不含** .xcodeproj）
```

分层（`App · Design · Core · Domain · Features`）与设计令牌的做法取自
[eid-platform-mn](https://github.com/gerege-systems/eid-platform-mn) 的桌面客户端。

## 设计令牌

**`Sources/Design/Tokens.swift` 与 `frontend/src/app/globals.css` 保持 lockstep。**
所有颜色、圆角、间距都从那里复制而来 —— 不要在此文件之外新增颜色；`globals.css`
变更时同步更新本文件。原生应用与 Web 是同一个产品，必须由同一套调色板供给。

eid-platform-mn 也遵循同样的原则 —— 其 `Design/Colors.swift` 顶部写着
「Sourced from web/src/app/globals.css. Keep in lockstep」。

> 注意：`globals.css` 使用 oklch，而 SwiftUI 不支持，因此令牌以转换后的 sRGB
> hex 保存。

## 开发

```bash
cd desktop/macos-app
xcodegen generate          # 生成 GeregeDesktop.xcodeproj（不纳入版本控制）
open GeregeDesktop.xcodeproj
```

命令行构建：

```bash
xcodebuild -project GeregeDesktop.xcodeproj -scheme GeregeDesktop \
  -configuration Debug -derivedDataPath build build
open build/Build/Products/Debug/GeregeDesktop.app
```

### 选择服务器

默认地址为 `https://public.template.gerege.mn`。指向本地 frontend：

```bash
GEREGE_APP_URL=http://localhost:3000 open -a build/Build/Products/Debug/GeregeDesktop.app
```

## 要求

- macOS 13+
- Xcode 15+（Swift 5.9+）
- [xcodegen](https://github.com/yonaskolb/XcodeGen) —— `brew install xcodegen`

## 安全

- 启用 **App Sandbox**；唯一权限是 `network.client`（访问 BFF）。不需要文件、
  摄像头、麦克风、定位权限。
- 启用 **Hardened runtime**。
- 未放宽 ATS —— 仅 HTTPS。
- 不保存令牌或密码。登出时会清除本地 cookie。

## 限制

- **仅两个页面**（登录 · 仪表盘）。
- **无自动更新**。
- **未签名** —— 分发需要 Apple Developer ID。
- 无离线模式。

## 相关文档

- [desktop/windows-app/README_ZH.md](../windows-app/README_ZH.md) —— Windows 客户端
- [ios/TemplateApp/README_ZH.md](../../ios/TemplateApp/README_ZH.md) —— iOS 客户端
