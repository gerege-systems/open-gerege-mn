# Gerege Template Platform V3.0 — Android App (TemplateApp)

> 🌐 **Монгол** · [中文](README_ZH.md) · [Русский](README_RU.md)

> **Цахим үйлчилгээг бүтээх суурь** — _Нэг суурь — төр, хувийн хэвшлийн бүх үйлчилгээ._

**Gerege Template Platform V3.0**-ийн жишиг **Android клиент**. Gerege SSO-гоор
нэвтэрч, хэрэглэгчийн профайл + eID PKI мэдээллийг харуулна — суурь платформ дээр
бүтээгдсэн native мобайл үйлчилгээг хэрхэн босгохын үлгэр жишээ. Native Kotlin +
Jetpack Compose; сүлжээ/JSON-ий гуравдагч сан ашиглахгүй (HttpURLConnection +
`org.json`), хамаарал нь зөвхөн AndroidX/Compose.

Ижил төстэй [iOS клиент](../../ios/TemplateApp/README.md)-тэй дэлгэц, урсгал,
моделиороо мөр мөрөөрөө тохирно.

> Тайлбар: энэ бол **Relying-Party консюмер** апп — иргэний eID **апп** (өөр төсөл)
> биш. Жишиг deployment нь [open.gerege.mn](https://open.gerege.mn);
> Gerege SSO ([sso.gerege.mn](https://sso.gerege.mn)) нь тусдаа таних систем.
>
> Нэвтрэлт БҮХЭЛДЭЭ платформын BFF-ээр явна — апп нь SSO ч, eID платформ ч дээр
> өөрийн client/буцах хаяг бүртгүүлдэггүй (native OIDC, App2App deeplink,
> App Links байхгүй).

## Архитектур

- Апп → `https://open.gerege.mn/api/*` (BFF) — backend-тэй шууд харьцахгүй.
- Session нь httpOnly cookie (`dgov_access`/`refresh`)-д. Cookie-ийн ГАНЦ эх
  сурвалж нь WebView-ийн `android.webkit.CookieManager`: HTTP хүсэлт бүрт
  `Cookie` толгойг тэндээс уншиж, хариуны `Set-Cookie`-г буцааж хадгална.
  Ингэснээр SSO WebView-д суусан cookie-г тусад нь гүүрлэх шаардлагагүй бөгөөд
  апп хаагдаад нээгдэхэд session хэвээр үлдэнэ.
- BFF-ийн mutating route `x-dgov-csrf: 1` header шаарддаг (Origin header
  байхгүй тул энэ л хангалттай). Токен клиент рүү хэзээ ч гарахгүй.

### Нэвтрэлт

- **Gerege SSO** — `WebView`-д `/api/auth/sso/start` ачаалж, sso.gerege.mn дээр
  баталгаажуулна. `/me*` руу шилжих агшинд навигацыг зогсоож, cookie-г диск рүү
  flush хийгээд native дэлгэц рүү шилжинэ (вэб дашбоардыг апп дотор
  рендэрлэхгүй). Энэ шийдвэр нь `SsoPolicy`-д цэвэр функцээр тусгаарлагдсан —
  хостыг тулгадаг эсэхийг unit тест шалгана.
- **Профайл** — `GET /api/me` + `GET /api/me/eid/summary`.
- **Гарах** — `POST /api/auth/logout` + WebView-ийн cookie/storage-ыг цэвэрлэнэ
  (эс бөгөөс SSO-гийн session үлдэж, дараагийн нэвтрэлт дахин баталгаажуулахгүй).

## Бүтэц

```
mobile/android/TemplateApp/
  settings.gradle.kts · build.gradle.kts   # Gradle (Kotlin DSL)
  app/
    build.gradle.kts                       # AGP тохиргоо + BuildConfig.GEREGE_APP_URL
    src/main/AndroidManifest.xml
    src/debug/…                            # локал http BFF-д зориулсан network-security overlay
    src/main/java/mn/gerege/temp/
      MainActivity.kt      # Activity + AppState (ViewModel) + RootScreen
      ApiClient.kt         # BFF client (cookie session, CSRF header)
      Models.kt            # org.json → MeUser, EidBlock, EidSummary…
      SsoPolicy.kt         # SSO урсгалын шийдвэр (цэвэр функц, тесттэй)
      LoginScreen.kt       # SSO-гоор нэвтрэх эхлэл
      SsoWebView.kt        # WebView SSO
      HomeScreen.kt        # профайл + eID PKI + гарах
      ui/Tokens.kt         # дизайны токен (globals.css-ийн хуулбар)
      ui/Theme.kt          # Material 3 схем + типографи
    src/test/java/…        # JVM unit тестүүд (SsoPolicy · Models)
```

## Build

Шаардлага: **JDK 17**, **Android SDK** (`compileSdk 35`, build-tools 35).
Android Studio (Ladybug+) шаардлагагүй ч дэмжинэ — төслийг нээхэд л хангалттай.

```bash
cd mobile/android/TemplateApp

./gradlew test            # JVM unit тестүүд
./gradlew assembleDebug   # → app/build/outputs/apk/debug/app-debug.apk
./gradlew installDebug    # холбогдсон төхөөрөмж/эмулятор дээр суулгана
```

SDK-ийн замыг `ANDROID_HOME` орчны хувьсагчаар эсвэл `local.properties`
(`sdk.dir=…`) файлаар зааж өгнө — `local.properties` нь машин тус бүрийнх тул
git-д ороогүй.

Release APK гарын үсэггүй (`assembleRelease`) — дэлгүүрт тавихдаа өөрийн
signing config нэмнэ.

## Тохиргоо

- **Backend хаяг** — `BuildConfig.GEREGE_APP_URL`, анхдагч нь
  `https://open.gerege.mn`. Build үед дарж болно:

  ```bash
  ./gradlew installDebug -PgeregeAppUrl=http://10.0.2.2:3000
  ```

  (`10.0.2.2` = Android эмулятороос харагдах хостын `localhost`.) Debug build
  дээр `10.0.2.2` / `localhost` / `127.0.0.1`-д cleartext зөвшөөрөгдсөн —
  release build ЗӨВХӨН https-ээр ярина.
- **Bundle id** — `mn.gerege.temp` (iOS-тэй ижил).
- **Дизайны токен** — `ui/Tokens.kt`. Эх сурвалж нь `frontend/src/app/globals.css`;
  шинэ өнгийг зөвхөн тэндээс хуулж нэмнэ (вэб · macOS · Windows · Android нэг
  палитраас тэжээгдэнэ).
- **Хамаарлын хувилбар** — `app/build.gradle.kts`-д тогтмол бичигдсэн. Compose
  BOM-ыг шинэчлэхдээ `compileSdk`-г нь хамт шалга (шинэ AndroidX хувилбарууд
  ихэвчлэн шинэ compileSdk шаарддаг).
