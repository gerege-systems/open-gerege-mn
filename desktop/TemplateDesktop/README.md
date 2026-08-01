# Gerege Template Platform V3.0 — Desktop App (TemplateDesktop)

> 🌐 **Монгол** · [中文](README_ZH.md) · [Русский](README_RU.md)

> **Цахим үйлчилгээг бүтээх суурь** — _Нэг суурь — төр, хувийн хэвшлийн бүх үйлчилгээ._

**Gerege Template Platform V3.0**-ийн **desktop клиент**. Энэ бол Electron
бүрхүүл — платформын web интерфейсийг **1:1** ачаалж, хөтчийн оронд native
цонх, цэс, товчлол, эрхийн бодлого нэмнэ.

> **Юуг нь дахин бичээгүй вэ:** хуудас, урсгал, дизайн, i18n, BFF — бүгд
> `frontend/`-ийн яг тэр код. Desktop тал нь өөрийн UI-гүй тул web дээр гарсан
> шинэчлэлт **дахин build хийхгүйгээр** аппад шууд тусна.

Дэмжигдсэн платформууд: **macOS 12+**, **Windows 10/11**, **Linux**
(AppImage · deb · rpm).

| Платформ | Багц | Архитектур | Авто-шинэчлэлт |
|---|---|---|---|
| macOS 12+ | `dmg`, `zip` | arm64 · x64 | ✅ (zip-ээр) |
| Windows 10/11 | `nsis` суулгагч, `portable` | x64 (nsis: + arm64) | ✅ зөвхөн NSIS — portable шинэчлэгдэхгүй |
| Linux | `AppImage`, `deb`, `rpm` | x64 (AppImage/deb: + arm64) | ✅ зөвхөн AppImage — deb/rpm-ыг пакет менежер шинэчилнэ |

> **Багц бүрийг өөрийнх нь OS дээр бүтээнэ.** macOS багцад `codesign`,
> Windows-ийн NSIS-д wine шаардлагатай тул нэг хостоос гурвуулангийн багцыг
> найдвартай гаргах боломжгүй — CI-ийн тухайн runner дээр (эсвэл зорилтот OS
> дээр) build хийнэ.

## Архитектур

```
┌────────────────────────────┐
│  TemplateDesktop (Electron)│  цонх · цэс · шилжилтийн бодлого · эрх
│  ┌──────────────────────┐  │
│  │ Chromium BrowserWindow│ │  →  https://template.gerege.mn  (Next.js BFF)
│  └──────────────────────┘  │           │
└────────────────────────────┘           └→  Go API (/api/v1/*) — апп шууд хандахгүй
```

- Апп **backend-тэй шууд харьцахгүй** — бүх хүсэлт web аппын BFF-ээр явна.
- Session нь **httpOnly cookie** (`dgov_access` / `dgov_refresh`). Chromium-ы
  cookie сав нь `userData` дотор тогтвортой хадгалагдана — апп хаагаад нээхэд
  нэвтэрсэн хэвээр байна.
- CSRF, Origin шалгалт, CSP — бүгд web талын хэвээрээ. Desktop нь ямар ч
  токен барихгүй, JS рүү нэвтрүүлэхгүй.

### Цонхны preload

Preload нь ачаалж буй хуудасны схемээр хоёр өөр гүүр тавина:

| Хуудас | Схем | Гүүр | Чадвар |
|---|---|---|---|
| Web апп | `https:` | `window.geregeDesktop` | зөвхөн уншигдах тэмдэглэгээ (`isDesktop`, `platform`, `appVersion`, `overlayTitleBar`, `titleBarInset`) |
| Дотоод хуудас | `file:` | `window.geregeShell` | сервер солих, дахин ачаалах, цонх хаах |

Алсын агуулга бүрхүүлийн IPC-д **хэзээ ч** хүрэхгүй. Main процесс нь IPC бүрийг
илгээгчийн `file://` хаягаар давхар шалгадаг (`src/main.ts` → `fromInternalPage`).

### Шилжилтийн бодлого (`src/policy.ts`)

| Хаяг | Үйлдэл |
|---|---|
| Аппын өөрийн origin | цонхон дотор |
| `*.gerege.mn`, `eidmongolia.mn`, `accounts.google.com`, `*.dropbox.com` | цонхон дотор — OAuth callback нь аппын cookie сав руу буцах ёстой |
| Бусад `http(s)` (баримт бичиг, GitHub, dgov.mn) | системийн хөтчөөр |
| `mailto:`, `geregesmartid://` гэх мэт | үйлдлийн систем рүү |
| `javascript:`, `data:`, өөр origin-ы `blob:` | бүрэн хаагдана |

`<webview>` таслагдана, төхөөрөмжийн (HID/Serial/USB) эрх хаалттай. Хөтчийн
эрхээс зөвхөн **микрофон** (AI чат · дуут мессеж · амьд орчуулга), мэдэгдэл,
бүтэн дэлгэц нээлттэй — камер, байршил хаалттай.

User-Agent-аас `Electron/…` шошго хасагддаг: Google/Dropbox зэрэг нэвтрэлтийн
үйлчилгээ уг шошготой агентыг татгалздаг. Chromium-ы жинхэнэ хувилбар үлдэнэ.

## Desktop харагдац

Web апп нь хөтөч дээрхтэй **ижил код** хэвээр — гэхдээ desktop цонхонд хөтчийн
таб, хаягийн мөр байхгүй, харин цонхны удирдлага байдаг. Тиймээс аппын шинэ
UI бичихгүйгээр загварын нэг давхарга нэмэв:

```
preload  →  window.geregeDesktop { isDesktop, platform, overlayTitleBar, titleBarInset }
              ↓  (theme-bootstrap.js — hydration-аас ӨМНӨ)
<html data-desktop="darwin" data-titlebar="overlay" style="--titlebar-inset: 78px">
              ↓
frontend/src/app/globals.css → html[data-desktop] { … }
```

Тэмдэглэгээг блоклогч `public/theme-bootstrap.js` тавьдаг тул desktop харагдац
**эхний зурагдалтаас** тогтоно — layout анивчихгүй.

| Юу өөрчлөгдөх | Яагаад |
|---|---|
| macOS дээр гарчгийн мөр цонхонд шингэнэ (`hiddenInset`) | Аппын дээд эгнээ (icon rail · sidepanel толгой · `topbar2`) өөрөө гарчгийн мөр болно — 64px өндөр давхар зурвас гарахгүй |
| Дээд эгнээ бүхэлдээ **чирэх бүс** | Цонхыг хаанаас ч зөөнө. Товч/хайлт/цэс `no-drag` тул дарагдана |
| Зүүн дээд буланд `--titlebar-inset` (78px) | Гэрлэн товчнууд (traffic lights) агуулгыг дарахгүй |
| Цэс, самбарын бичвэр сонгогдохгүй | Native цонхонд chrome нь бичвэр биш — чирэхэд "тодрох" нь гажиг |
| Нимгэн гүйлгүүр, rubber-band унтраасан | macOS-ийн native мэдрэмж |

Гэрлэн товчнууд icon rail-ийн толгойд суудаг тул тэнд байсан **жижиг брэнд
тэмдэг нуугдана** (брэнд нэр нь sidepanel-ийн толгойд хэвээр). Бүтэн дэлгэц
үед товчнууд алга болдог — үүнийг DOM мэдэх аргагүй тул бүрхүүл өөрөө
`webContents.insertCSS`-ээр нөөцөлсөн зайг тэглэнэ (`src/windows.ts`).

Windows/Linux дээр цонх **стандарт хүрээтэй** хэвээр (`data-titlebar` тавигдахгүй)
— энэ нь **зориудын шийдвэр**: тэдгээр платформ дээр цонхны удирдлагын байрлал,
дараалал нь орчны сэдэвээс (Windows 11 snap, GNOME/KDE) хамаардаг тул өөрсдөө
зурвал жижиг зөрүү бүр эвдрэл шиг харагдана. `data-desktop` тэмдэглэгээ бүх
платформд тавигдана.

## Авто-шинэчлэлт

Апп нь **өөрөө** шинэ хувилбарыг олж, татаж, дахин эхэлнэ — хэрэглэгч гараар
татаж суулгах шаардлагагүй. Суурь нь [`electron-updater`](https://www.electron.build/auto-update).

```
эхлээд 30 сек → дараа 6 цаг тутам → latest-mac.yml уншина
        ↓ шинэ хувилбар мөн үү (semver шалгалт — ХУУЧИН багц татахгүй)
    арын дэвсгэрт татна (цэсний шошгонд % харагдана)
        ↓ дуусахад
   «Одоо дахин эхлүүлэх» / «Дараа»
        ↓                      ↓
   шууд суугаад сэргэнэ    аппыг хаахад автоматаар суух
```

**Яагаад асуудаг вэ:** татаж дуусах мөчид хэрэглэгч маягт бөглөж, AI-тай ярьж
байж болно — тэр хором аппыг чимээгүй хаах нь өгөгдөл алдана. Анхдагч товч нь
«Одоо дахин эхлүүлэх», хойшлуулсан ч `autoInstallOnAppQuit` дараагийн удаа
хаахад нь өөрөө суулгана. Аль ч тохиолдолд гараар татах алхам байхгүй.

Цэсний **«Шинэчлэлт шалгах…»** (macOS: аппын цэс, бусад: Тусламж) нь урсгалын
төлөвөө өөрөө хэлнэ — `Шинэчлэлт татаж байна… 42%`, `Шинэчлэлт бэлэн (1.1.0) —
дахин эхлүүлэх`. Гараар шалгахад л «шинэ хувилбар алга» / алдааны мэдэгдэл
гарна; авто шалгалт чимээгүй ажиллана.

| Тохиргоо | Утга |
|---|---|
| Суваг | `https://template.gerege.mn/desktop/updates/` (`src/config.ts` · `electron-builder.yml` — **хоёулаа ижил байх ёстой**) |
| `GEREGE_UPDATE_URL` | сувгийг түр солих (staging турших). Зөвхөн **https** (loopback дээр http) — хүчингүй бол үндсэн суваг руу буцна |
| `GEREGE_UPDATE_DEV=1` | багцлаагүй горимд шалгалтыг албадах (`dev-app-update.yml` шаардана) |

Хэрэглэгчийн UI-аас суваг солих боломж **зориуд байхгүй** — суваг солих нь код
солихтой дүйцнэ.

### Шинэ хувилбар тараах

```bash
# 1. package.json дахь version-ыг ахиулна (semver)
npm version patch --no-git-tag-version

# 2. Гарын үсэгтэй багц (авто-шинэчлэлт ЗААВАЛ гарын үсэг шаардана)
npm run dist:mac:signed

# 3. release/-ээс сувгийн лавлах руу байршуулна
#    Gerege Template-<v>-arm64-mac.zip        ← Squirrel.Mac зөвхөн zip-ээс суулгана
#    Gerege Template-<v>-arm64-mac.zip.blockmap
#    Gerege Template-<v>-x64-mac.zip (+ blockmap)
#    latest-mac.yml                            ← сувгийн "заагч" — ХАМГИЙН СҮҮЛД нь хуулна
#    (dmg нь зөвхөн анхны гар суулгалтад — шинэчлэлтэд оролцохгүй)
```

`latest-mac.yml`-ыг хамгийн сүүлд хуулах нь чухал: багц бүрэн хуулагдаагүй
байхад заагч шинэчлэгдвэл апп байхгүй файл татах гэж алдаа өгнө.

> ⚠️ **Гарын үсэггүй build дээр авто-шинэчлэлт ажиллахгүй.** macOS-ийн
> Squirrel.Mac нь татсан багцын код гарын үсгийг суусан аппынхтай тулгадаг —
> тохирохгүй бол суулгахаас татгалзана. Локал турших багц (`npm run dist:mac`)
> шинэчлэлт шалгаж, татаж чадах ч суулгах алхамд алдаа өгнө.

## Хөгжүүлэлт

```bash
cd desktop/TemplateDesktop
npm install

npm start        # үйлдвэрлэлийн сервер рүү (template.gerege.mn)
npm run dev      # локал frontend руу (localhost:3000) + DevTools
npm test         # шилжилт · эрх · шинэчлэлтийн бодлогын тест (node --test)
npm run typecheck
```

`npm run dev`-ийг ажиллуулахын өмнө өөр терминалд `cd frontend && npm run dev`.

Эдгээр script нь **гурван OS дээр, Node-ийн аль ч хувилбар дээр** адилхан
ажиллана — хоёулаа жижиг оболочкоор дамжина:

- `scripts/dev.mjs` — орчны хувьсагчийг энд тогтооно. POSIX-ийн
  `VAR=утга команд` бичлэг Windows дээр «команд олдсонгүй» гэж унадаг.
- `scripts/test.mjs` — тестийн файлуудыг олж `node --test`-д **тодорхой замаар**
  дамжуулна. `dist/*.test.js` бол `cmd.exe` глоб задалдаггүй тул Windows дээр
  унана; `"dist/**/*.test.js"` бол глоб дэмжлэг зөвхөн Node 22+; `dist` лавлах
  нь Node 20 дээр ажиллавч шинэ хувилбарууд түүнийг файл гэж үздэг. Тодорхой
  жагсаалт нь аль ч хослол дээр ажиллана.

### Серверийг сонгох

Эрэмбэ: `GEREGE_APP_URL` орчны хувьсагч → аппад хадгалсан сонголт → `template.gerege.mn`.

Цэсээс **Сервер солих…** (`⌘⇧S`) — бэлэн сонголт эсвэл өөрийн хаяг. Сонголт
`userData/state.json`-д хадгалагдана. `GEREGE_APP_URL` тогтоогдсон бол дараагийн
ажиллагаанд түүнийг ашиглана (цонхонд анхааруулга гарна).

## Багцлах

```bash
npm run icon           # brand.webp → resources/icon.png (+ macOS дээр icon.icns)
npm run pack           # release/*-unpacked/ — багцлалгүй, тохиргоо шалгах хурдан арга

npm run dist:mac       # release/*.dmg + *.zip (arm64 · x64), гарын үсэггүй
npm run dist:win       # release/*.exe — NSIS суулгагч + portable
npm run dist:linux     # release/*.AppImage + *.deb + *.rpm
```

Windows/Linux-ийн гаралт нь `Gerege Template-<хувилбар>-<os>-<arch>.<өргөтгөл>`
нэртэй. macOS-ийн нэршлийг **зориуд хөндөөгүй** — түүний авто-шинэчлэлтийн суваг
аль хэдийн тодорхойлогдсон тул нэр солих нь шаардлагагүй эрсдэл.

**Дүрс.** `npm run icon` нь 1024px `resources/icon.png` үүсгэнэ — Linux шууд
хэрэглэнэ, Windows-ийн `.ico`-г electron-builder эндээс автоматаар хөрвүүлнэ.
macOS-ийн `icon.icns` нь зөвхөн macOS дээр (`iconutil`) үүснэ; script нь macOS
дээр суурин `sips`-ийг, бусад OS дээр ImageMagick-ийг ашиглана. Хоёр дүрс хоёулаа
репод tracked тул энгийн build-д дахин үүсгэх шаардлагагүй.

### macOS

Гарын үсэггүй build нь **зөвхөн локал турших** зориулалттай — macOS Gatekeeper
"эвдэрсэн" гэж анхааруулна (`xattr -dr com.apple.quarantine "/Applications/Gerege Template.app"`
эсвэл Системийн тохиргоо → Аюулгүй байдал → "Ямар ч байсан нээх").

Тараахад Apple Developer ID шаардлагатай:

```bash
export CSC_LINK=... CSC_KEY_PASSWORD=...          # Developer ID Application гэрчилгээ
export APPLE_ID=... APPLE_APP_SPECIFIC_PASSWORD=... APPLE_TEAM_ID=...
npm run dist:mac:signed                            # signed + notarized
```

Hardened runtime, entitlements (`build/entitlements.mac.plist`) болон
`NSMicrophoneUsageDescription` нь урьдчилан тохируулагдсан.

Хоёр script хоёулаа `--publish never`-тэй: суваг нь энгийн HTTPS лавлах тул
байршуулалт нь тусдаа алхам ([Шинэ хувилбар тараах](#шинэ-хувилбар-тараах)).
Build бүрд `release/latest-mac.yml` (сувгийн заагч) давхар үүснэ.

### Windows

`npm run dist:win` нь хоёр гаралт өгнө: **NSIS суулгагч** (хэрэглэгч суулгах
хавтсаа сонгоно, desktop + Start menu товчлол үүснэ, админ эрх шаардахгүй —
`perMachine: false`) болон **portable** `.exe` (суулгахгүй шууд ажиллана —
түгжээтэй байгууллагын компьютерт хэрэгтэй).

> Авто-шинэчлэлт нь **зөвхөн NSIS-ээр суулгасан** аппад ажиллана. Portable
> хувилбарыг хэрэглэгч гараар татаж солино — electron-updater түүнийг
> шинэчилдэггүй.

Гарын үсэг зурахад гэрчилгээгээ `CSC_LINK` / `CSC_KEY_PASSWORD`-оор өгнө. Үгүй
бол SmartScreen "тодорхойгүй нийтлэгч" гэж анхааруулна. Build-д `latest.yml`
давхар үүснэ.

### Linux

`npm run dist:linux` нь `AppImage` (ямар ч дистрод шууд ажиллана), `deb`
(Debian/Ubuntu) болон `rpm` (Fedora/RHEL) гаргана. `deb`-ийн хамаарлууд
(`libgtk-3-0`, `libnss3`, `libsecret-1-0` г.м) `electron-builder.yml`-д
жагсаагдсан. Цонхыг `.desktop` бичлэгтэй холбохын тулд `StartupWMClass`
тогтоосон — эс бөгөөс Wayland/GNOME дээр taskbar-т дүрсгүй харагдана.

> Linux дээр авто-шинэчлэлт нь **зөвхөн AppImage**-д ажиллана (`latest-linux.yml`).
> `deb`/`rpm`-ыг дистрогийн пакет менежерээр шинэчилнэ.

## Файлын бүтэц

```
src/
  main.ts        аппын эхлэх цэг — session, эрх, IPC, амьдралын мөчлөг
  windows.ts     цонх үүсгэх, байрлал хадгалах, шилжилтийн бодлого тогтоох
  menu.ts        системийн цэс (монгол)
  policy.ts      цэвэр шийдвэрүүд — classifyURL, allowPermission, UA цэвэрлэгээ
  update.ts      цэвэр шийдвэрүүд — semver харьцуулалт, давтамж, цэсний шошго
  updater.ts     авто-шинэчлэлтийн урсгал (electron-updater, асуулга, дахин эхлүүлэлт)
  config.ts      суурь хаягууд, цагаан жагсаалт, шинэчлэлтийн суваг, хаяг цэгцлэх
  store.ts       userData/state.json (цонхны байрлал, сервер, сүүлийн шалгалт)
  preload.ts     схемээс хамаарсан хоёр гүүр
  policy.test.ts бодлогын тест
  update.test.ts шинэчлэлтийн шийдвэрүүдийн тест
static/          дотоод хуудсууд — offline.html, server.html, shell.css
build/           entitlements
resources/       icon.png (Linux · Windows), icon.icns (macOS)
scripts/         make-icon.sh, dev.mjs, test.mjs
```

## Товчлолууд

macOS дээр `⌘`, Windows/Linux дээр `Ctrl`.

| macOS | Windows / Linux | Үйлдэл |
|---|---|---|
| `⌘R` / `⌘⇧R` | `Ctrl+R` / `Ctrl+⇧R` | дахин ачаалах / хүчээр |
| `⌘[` / `⌘]` | `Alt+←` / `Alt+→` | буцах / урагш |
| `⌘+` / `⌘-` / `⌘0` | `Ctrl+…` | томсгох / жижигрүүлэх / бодит хэмжээ |
| `⌘N` | `Ctrl+N` | шинэ цонх |
| `⌘P` | `Ctrl+P` | хэвлэх |
| `⌘,` | `Ctrl+,` | тохиргоо (`/me/settings`) |
| `⌘⇧S` | `Ctrl+⇧S` | сервер солих |
| `⌘⇧H` | `Ctrl+⇧H` | нүүр хуудас |

Хуудас ухрах/урагшлах нь хулганаар ч ажиллана: macOS дээр **хоёр хуруутай
зөөлт**, Windows/Linux дээр хулганы **4/5-р товч** (`app-command`).

Цэс нь платформын жишгээр өөр байна: macOS дээр аппын нэрээр эхэлсэн цэс
(Тохиргоо · Үйлчилгээ · Нуух), Windows/Linux дээр эдгээр нь **Файл** цэсэнд
шилжинэ. Зөвхөн macOS-д байдаг role-ууд (`zoom`, `front`, `services`) бусад OS
дээр огт нэмэгдэхгүй.

## Хязгаарлалт ба анхаарах зүйл

- **Интернэт шаардана** — офлайн горим байхгүй. Сервер хүрэхгүй бол дотоод
  офлайн хуудас гарч, "Дахин оролдох"-оор сэргэнэ (сүлжээ сэргэмэгц автоматаар).
- **Авто-шинэчлэлт нь зөвхөн бүрхүүлд хамаарна.** Web агуулга үргэлж шинэ байдаг
  тул шинэ хувилбар нь бүрхүүл (цонх, цэс, бодлого) өөрчлөгдөх үед л гарна.
  Гарын үсэггүй build дээр суулгах алхам ажиллахгүй (дээрх анхааруулга).
- **Desktop харагдац нь дан загварын давхарга.** Хуудсууд, урсгалууд web-тэйгээ
  1:1 хэвээр — desktop тал зөвхөн `html[data-desktop]`-оор chrome-ыг тохируулна.
- `geregetemp://eid/callback` (iOS App2App гүүр) desktop дээр бүртгэгдээгүй —
  desktop-ийн eID урсгал `/auth/eid/callback`-аар явна.
- `npm audit` нь `electron-builder`-ийн шилжсэн хамаарлуудад анхааруулга өгдөг.
  Эдгээр нь **зөвхөн build хугацааны** хэрэгсэл — багцад орохгүй. Засвар нь
  electron-builder-ийн эвдрэлтэй downgrade шаарддаг тул хойшлуулав.

## Холбоотой

- [frontend/README.md](../../frontend/README.md) — web апп (эх сурвалж нь)
- [ios/TemplateApp/README.md](../../ios/TemplateApp/README.md) — iOS клиент
- [docs/DEPLOYMENT.md](../../docs/DEPLOYMENT.md) — серверийн байршуулалт
