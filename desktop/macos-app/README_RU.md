# Gerege Template Platform V3.0 — приложение для macOS

> 🌐 [Монгол](README.md) · [中文](README_ZH.md) · **Русский**

**Нативный macOS-клиент** платформы **Gerege Template Platform V3.0** (SwiftUI).
Веб не загружается — у приложения собственные нативные экраны.

Объём намеренно узкий: всего **два экрана** — вход и дашборд. Это не готовое
приложение, а **базовый шаблон**: свои экраны вы добавляете поверх.

## Поток

```
Экран входа
   │  «Войти через Gerege SSO»
   ▼
WKWebView → /api/auth/sso/start → Gerege SSO → /sso/callback (ставит cookie)
   │  в момент перехода BFF на /me/... навигация ОТМЕНЯЕТСЯ
   ▼
cookie → HTTPCookieStorage → нативный дашборд (/api/me, /api/me/eid/summary)
```

- Приложение **не обращается напрямую** к Go-бэкенду — все запросы идут через
  Next.js BFF платформы (так же, как web и iOS).
- Сессия — **httpOnly cookie** (`dgov_access` / `dgov_refresh`). Токен **никогда**
  не попадает в клиентский код и не хранится в приложении.
- **Собственный OIDC-клиент в SSO не регистрируется** (нет native/PKCE-потока) —
  переиспользуется логика веб-клиента, поэтому политика входа живёт в одном месте.
- Веб-дашборд **внутри приложения не рендерится** — WebView существует только во
  время входа.

## Структура

```
Sources/
  App/
    GeregeDesktopApp.swift   точка входа + RootView (три фазы)
    AppState.swift           состояние входа, загрузка профиля
  Design/
    Tokens.swift             цвета · отступы · радиусы · типографика
    Components.swift         AppCard · стили кнопок · Chip · DetailRow
  Core/
    APIClient.swift          клиент BFF (cookie-сессия, x-dgov-csrf)
  Domain/
    Models.swift             MeUser · EidBlock · GoogleBlock · EidSummary
  Features/
    Login/LoginView.swift    сплит-раскладка — бренд-панель + карточка входа
    Login/SSOWebView.swift   WKWebView + синхронизация cookie
    Dashboard/DashboardView.swift
project.yml                  описание для xcodegen (.xcodeproj в репозитории НЕТ)
```

Слои (`App · Design · Core · Domain · Features`) и подход к дизайн-токенам взяты
у десктоп-клиентов
[eid-platform-mn](https://github.com/gerege-systems/eid-platform-mn).

## Дизайн-токены

**`Sources/Design/Tokens.swift` держится в lockstep с
`frontend/src/app/globals.css`.** Каждый цвет, радиус и отступ скопирован
оттуда — не добавляйте новые цвета вне этого файла, а при изменении
`globals.css` обновляйте и его. Нативное приложение и веб — один продукт, и
питаться они должны от одной палитры.

Тот же принцип держит eid-platform-mn — в шапке их `Design/Colors.swift`
написано «Sourced from web/src/app/globals.css. Keep in lockstep».

> Примечание: `globals.css` использует oklch, который SwiftUI не понимает,
> поэтому токены хранятся сконвертированными в sRGB hex.

## Разработка

```bash
cd desktop/macos-app
xcodegen generate          # создаст GeregeDesktop.xcodeproj (не под контролем версий)
open GeregeDesktop.xcodeproj
```

Сборка из терминала:

```bash
xcodebuild -project GeregeDesktop.xcodeproj -scheme GeregeDesktop \
  -configuration Debug -derivedDataPath build build
open build/Build/Products/Debug/GeregeDesktop.app
```

### Выбор сервера

Адрес по умолчанию — `https://public.template.gerege.mn`. Указать локальный
frontend:

```bash
GEREGE_APP_URL=http://localhost:3000 open -a build/Build/Products/Debug/GeregeDesktop.app
```

## Требования

- macOS 13+
- Xcode 15+ (Swift 5.9+)
- [xcodegen](https://github.com/yonaskolb/XcodeGen) — `brew install xcodegen`

## Безопасность

- Включён **App Sandbox**; единственное право — `network.client` (доступ к BFF).
  Доступ к файлам, камере, микрофону и геолокации не требуется.
- Включён **hardened runtime**.
- ATS не ослаблен — только HTTPS.
- Токены и пароли не хранятся. При выходе локальные cookie удаляются.

## Ограничения

- **Только два экрана** (вход · дашборд).
- **Нет автообновления.**
- **Не подписано** — для распространения нужен Apple Developer ID.
- Офлайн-режима нет.

## Связанные документы

- [desktop/windows-app/README_RU.md](../windows-app/README_RU.md) — Windows-клиент
- [mobile/ios/TemplateApp/README_RU.md](../../mobile/ios/TemplateApp/README_RU.md) — iOS-клиент
- [mobile/android/TemplateApp/README_RU.md](../../mobile/android/TemplateApp/README_RU.md) — Android-клиент
