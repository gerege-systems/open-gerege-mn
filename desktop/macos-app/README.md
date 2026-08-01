# Gerege Template Platform V3.0 — macOS App

> 🌐 **Монгол** · [中文](README_ZH.md) · [Русский](README_RU.md)

**Gerege Template Platform V3.0**-ийн **native macOS клиент** (SwiftUI). Вэбийг
ачаалдаггүй — өөрийн native дэлгэцтэй.

Хамрах хүрээ нь зориудаар нарийн: **нэвтрэх** ба **хяналтын самбар** хоёрхон
дэлгэц. Энэ бол бүрэн апп биш, **суурь загвар** — өөрийн үйлчилгээний дэлгэцүүдээ
дээр нь нэмнэ.

## Урсгал

```
Нэвтрэх дэлгэц
   │  «Gerege SSO-оор нэвтрэх»
   ▼
WKWebView → /api/auth/sso/start → Gerege SSO → /sso/callback (cookie суулгана)
   │  BFF нь /me/... руу шилжүүлэх агшинд навигацыг ЗОГСООНО
   ▼
cookie → HTTPCookieStorage → native Хяналтын самбар (/api/me, /api/me/eid/summary)
```

- Апп нь Go backend-тэй **шууд харьцахгүй** — бүх хүсэлт платформын Next.js
  BFF-ээр явна (вэб, iOS-той яг ижил).
- Session нь **httpOnly cookie** (`dgov_access` / `dgov_refresh`). Токен клиент
  код руу **хэзээ ч гарахгүй** — аппад хадгалагдахгүй.
- SSO дээр **өөрийн OIDC client бүртгүүлэхгүй** (native/PKCE урсгал байхгүй) —
  вэб client-ийн логикийг тэр чигт нь ашиглана. Ингэснээр нэвтрэлтийн бодлого
  нэг л газар (BFF) байрлана.
- Вэб дашбоардыг апп дотор **рендэрлэхгүй** — WebView зөвхөн нэвтрэлтийн үед
  амьдарна.

## Бүтэц

```
Sources/
  App/
    GeregeDesktopApp.swift   аппын эхлэх цэг + RootView (3 үе шат)
    AppState.swift           нэвтрэлтийн төлөв, профайл ачаалалт
  Design/
    Tokens.swift             өнгө · зай · радиус · типографи
    Components.swift         AppCard · товчны style · Chip · DetailRow
  Core/
    APIClient.swift          BFF клиент (cookie session, x-dgov-csrf)
  Domain/
    Models.swift             MeUser · EidBlock · GoogleBlock · EidSummary
  Features/
    Login/LoginView.swift    split layout — брэнд самбар + нэвтрэх карт
    Login/SSOWebView.swift   WKWebView + cookie синк
    Dashboard/DashboardView.swift
project.yml                  xcodegen тодорхойлолт (.xcodeproj нь repo-д БАЙХГҮЙ)
```

Давхаргалалт (`App · Design · Core · Domain · Features`) ба дизайны токенуудын
дэг журмыг [eid-platform-mn](https://github.com/gerege-systems/eid-platform-mn)-ийн
desktop клиентүүдээс авав.

## Дизайны токенууд

**`Sources/Design/Tokens.swift` нь `frontend/src/app/globals.css`-тэй lockstep-д
байна.** Өнгө, радиус, зайн утга бүр тэндээс хуулбарлагдсан — энэ файлаас гадуур
шинэ өнгө бүү нэмэгтүн, `globals.css` өөрчлөгдвөл энэ файлыг мөн шинэчилнэ.
Native апп ба вэб нэг бүтээгдэхүүн тул нэг палитраас тэжээгдэх ёстой.

Мөн зарчмыг eid-platform-mn барьдаг — тэдний `Design/Colors.swift`-ийн толгойд
«Sourced from web/src/app/globals.css. Keep in lockstep» гэж бичсэн байдаг.

> Тэмдэглэл: `globals.css` нь oklch өнгө хэрэглэдэг ч SwiftUI түүнийг
> ойлгодоггүй тул токенууд sRGB hex болгож хөрвүүлсэн байдлаар хадгалагдана.

## Хөгжүүлэлт

```bash
cd desktop/macos-app
xcodegen generate          # GeregeDesktop.xcodeproj үүснэ (repo-д tracked БИШ)
open GeregeDesktop.xcodeproj
```

Терминалаас build хийх:

```bash
xcodebuild -project GeregeDesktop.xcodeproj -scheme GeregeDesktop \
  -configuration Debug -derivedDataPath build build
open build/Build/Products/Debug/GeregeDesktop.app
```

### Серверийг сонгох

Үндсэн хаяг нь `https://public.template.gerege.mn`. Локал frontend рүү заах бол:

```bash
GEREGE_APP_URL=http://localhost:3000 open -a build/Build/Products/Debug/GeregeDesktop.app
```

> `GEREGE_APP_URL` нь зөвхөн `http`/`https` хаягийг хүлээж авна; бусад тохиолдолд
> үндсэн утга руу буцна.

## Шаардлага

- macOS 13+
- Xcode 15+ (Swift 5.9+)
- [xcodegen](https://github.com/yonaskolb/XcodeGen) — `brew install xcodegen`

## Аюулгүй байдал

- **App Sandbox** асаалттай; цорын ганц эрх нь `network.client` (BFF рүү гарах).
  Файл, камер, микрофон, байршлын эрх шаардахгүй.
- **Hardened runtime** асаалттай.
- ATS сулруулаагүй — зөвхөн HTTPS.
- Токен, нууц үг аппад хадгалагдахгүй. Гарахад cookie нь локалаас устгагдана.

## Хязгаарлалт

- **Хоёрхон дэлгэц** (нэвтрэх · самбар). Бусад бүх үйлчилгээ вэб дээр байна.
- **Авто-шинэчлэлт байхгүй** — Sparkle гэх мэт суулгаагүй.
- **Гарын үсэг зураагүй** — тараахад Apple Developer ID шаардлагатай.
- Офлайн горим байхгүй — session шалгах, профайл татахад интернэт шаардана.

## Холбоотой

- [desktop/windows-app/README.md](../windows-app/README.md) — Windows клиент
- [ios/TemplateApp/README.md](../../ios/TemplateApp/README.md) — iOS клиент
- [frontend/README.md](../../frontend/README.md) — вэб апп ба BFF
