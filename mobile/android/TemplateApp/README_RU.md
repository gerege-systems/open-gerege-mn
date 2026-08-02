# Gerege Template Platform V3.0 — приложение для Android (TemplateApp)

> 🌐 [Монгол](README.md) · [中文](README_ZH.md) · **Русский**

> **Основа для создания цифровых услуг** — _Одна основа — все государственные и частные услуги._

Образцовый **клиент для Android** платформы **Gerege Template Platform V3.0**.
Выполняет вход через Gerege SSO и показывает профиль пользователя и данные
eID PKI — пример того, как построить нативную мобильную услугу на базовой
платформе. Нативный Kotlin + Jetpack Compose; сторонние сетевые и JSON-библиотеки
не используются (HttpURLConnection + `org.json`), зависимости — только AndroidX/Compose.

Экраны, потоки и модели построчно совпадают с
[клиентом для iOS](../../ios/TemplateApp/README_RU.md).

> Пояснение: это приложение-**потребитель (доверяющая сторона)** — а не гражданское
> **приложение** eID (это другой проект). Эталонное развёртывание —
> [open.gerege.mn](https://open.gerege.mn); Gerege SSO
> ([sso.gerege.mn](https://sso.gerege.mn)) — отдельная система идентификации.
>
> Вход ПОЛНОСТЬЮ идёт через BFF платформы — приложение не регистрирует собственный
> client или адрес возврата ни в SSO, ни на платформе eID (нет native OIDC,
> App2App deeplink и App Links).

## Архитектура

- Приложение → `https://open.gerege.mn/api/*` (BFF) — с бэкендом
  напрямую не общается.
- Сессия хранится в httpOnly-куках (`dgov_access`/`refresh`). ЕДИНСТВЕННЫЙ
  источник кук — `android.webkit.CookieManager` из WebView: каждый HTTP-запрос
  берёт заголовок `Cookie` оттуда, а `Set-Cookie` из ответа записывается обратно.
  Поэтому куки, полученные в SSO-WebView, не нужно отдельно «мостить», а сессия
  переживает перезапуск приложения.
- Изменяющие маршруты BFF требуют заголовок `x-dgov-csrf: 1` (заголовка `Origin`
  нет, поэтому этого достаточно). Токены никогда не попадают в клиент.

### Вход

- **Gerege SSO** — в `WebView` загружается `/api/auth/sso/start`, подтверждение
  проходит на sso.gerege.mn. В момент перехода на `/me*` навигация
  останавливается, куки сбрасываются на диск, и приложение переключается на
  нативный экран (веб-дашборд внутри приложения не отображается). Это решение
  вынесено в чистую функцию `SsoPolicy` — юнит-тесты проверяют, что хост
  сравнивается строго.
- **Профиль** — `GET /api/me` + `GET /api/me/eid/summary`.
- **Выход** — `POST /api/auth/logout` и очистка кук/хранилища WebView (иначе
  сессия SSO останется и следующий вход пройдёт без повторной проверки).

## Структура

```
mobile/android/TemplateApp/
  settings.gradle.kts · build.gradle.kts   # Gradle (Kotlin DSL)
  app/
    build.gradle.kts                       # настройки AGP + BuildConfig.GEREGE_APP_URL
    src/main/AndroidManifest.xml
    src/debug/…                            # network-security overlay для локального http BFF
    src/main/java/mn/gerege/temp/
      MainActivity.kt      # Activity + AppState (ViewModel) + RootScreen
      ApiClient.kt         # Клиент BFF (сессия на куках, заголовок CSRF)
      Models.kt            # org.json → MeUser, EidBlock, EidSummary…
      SsoPolicy.kt         # Решения потока SSO (чистая функция, с тестами)
      LoginScreen.kt       # Начало входа через SSO
      SsoWebView.kt        # SSO в WebView
      HomeScreen.kt        # Профиль + eID PKI + выход
      ui/Tokens.kt         # Токены дизайна (копия globals.css)
      ui/Theme.kt          # Схема Material 3 + типографика
    src/test/java/…        # JVM-юнит-тесты (SsoPolicy · Models)
```

## Сборка

Требования: **JDK 17**, **Android SDK** (`compileSdk 35`, build-tools 35).
Android Studio (Ladybug+) не обязателен, но проект открывается в нём как есть.

```bash
cd mobile/android/TemplateApp

./gradlew test            # JVM-юнит-тесты
./gradlew assembleDebug   # → app/build/outputs/apk/debug/app-debug.apk
./gradlew installDebug    # установка на подключённое устройство/эмулятор
```

Путь к SDK задаётся переменной окружения `ANDROID_HOME` или файлом
`local.properties` (`sdk.dir=…`) — `local.properties` индивидуален для каждой
машины и в git не хранится.

Release-APK не подписан (`assembleRelease`) — для публикации добавьте свою
signing config.

## Настройка

- **Адрес бэкенда** — `BuildConfig.GEREGE_APP_URL`, по умолчанию
  `https://open.gerege.mn`. Можно переопределить при сборке:

  ```bash
  ./gradlew installDebug -PgeregeAppUrl=http://10.0.2.2:3000
  ```

  (`10.0.2.2` = `localhost` хоста, видимый из эмулятора Android.) В debug-сборке
  открытый трафик разрешён для `10.0.2.2` / `localhost` / `127.0.0.1` —
  release-сборка работает ТОЛЬКО по https.
- **Bundle id** — `mn.gerege.temp` (как в iOS).
- **Токены дизайна** — `ui/Tokens.kt`. Источник — `frontend/src/app/globals.css`;
  новые цвета добавляются только копированием оттуда (веб · macOS · Windows ·
  Android питаются одной палитрой).
- **Версии зависимостей** — зафиксированы в `app/build.gradle.kts`. При
  обновлении Compose BOM проверяйте `compileSdk` (новые версии AndroidX обычно
  требуют более высокий compileSdk).
