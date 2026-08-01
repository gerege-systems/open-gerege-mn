# Gerege Template Platform V3.0 — Android 应用（TemplateApp）

> 🌐 [Монгол](README.md) · **中文** · [Русский](README_RU.md)

> **构建数字服务的基础** — _一套基础 — 承载政府与私营部门的所有服务。_

**Gerege Template Platform V3.0** 的示例 **Android 客户端**。通过 Gerege SSO 登录，
展示用户资料 + eID PKI 信息 — 是在基础平台之上构建原生移动服务的范例。
原生 Kotlin + Jetpack Compose；网络与 JSON 不使用第三方库（HttpURLConnection +
`org.json`），依赖仅限 AndroidX/Compose。

与 [iOS 客户端](../../ios/TemplateApp/README_ZH.md)在界面、流程与数据模型上逐行对应。

> 说明：这是一个**依赖方（RP）消费端**应用 — 不是公民的 eID **应用**（那是另一个项目）。
> 参考部署是 [public.template.gerege.mn](https://public.template.gerege.mn)；
> Gerege SSO（[sso.gerege.mn](https://sso.gerege.mn)）是独立的身份系统。
>
> 登录**完全**通过平台 BFF 完成 —— 应用不在 SSO 或 eID 平台上注册自己的 client
> 或回调地址（没有 native OIDC、App2App deeplink、App Links）。

## 架构

- 应用 → `https://public.template.gerege.mn/api/*`（BFF）— 不与后端直接通信。
- 会话保存在 httpOnly cookie（`dgov_access`/`refresh`）中。Cookie 的**唯一**来源是
  WebView 的 `android.webkit.CookieManager`：每个 HTTP 请求从中读取 `Cookie` 头，
  响应的 `Set-Cookie` 再写回其中。这样 SSO WebView 中写入的 cookie 无需另行桥接，
  并且应用重启后会话依旧有效。
- BFF 的写操作路由要求 `x-dgov-csrf: 1` 请求头（因为没有 Origin 头，这一项即足够）。
  令牌绝不会到达客户端。

### 登录

- **Gerege SSO** — 在 `WebView` 中加载 `/api/auth/sso/start`，在 sso.gerege.mn 上完成验证。
  跳转到 `/me*` 时中止导航、将 cookie 落盘，然后切换到原生界面
  （不在应用内渲染网页版仪表盘）。该判断被抽离到纯函数 `SsoPolicy` 中 —
  单元测试会验证它是否严格比对 host。
- **资料** — `GET /api/me` + `GET /api/me/eid/summary`。
- **退出** — `POST /api/auth/logout` 并清除 WebView 的 cookie/storage
  （否则 SSO 会话会残留，下次登录将不再重新验证）。

## 结构

```
mobile/android/TemplateApp/
  settings.gradle.kts · build.gradle.kts   # Gradle（Kotlin DSL）
  app/
    build.gradle.kts                       # AGP 配置 + BuildConfig.GEREGE_APP_URL
    src/main/AndroidManifest.xml
    src/debug/…                            # 本地 http BFF 的 network-security overlay
    src/main/java/mn/gerege/temp/
      MainActivity.kt      # Activity + AppState（ViewModel）+ RootScreen
      ApiClient.kt         # BFF 客户端（cookie 会话、CSRF 请求头）
      Models.kt            # org.json → MeUser、EidBlock、EidSummary…
      SsoPolicy.kt         # SSO 流程判断（纯函数，含测试）
      LoginScreen.kt       # SSO 登录入口
      SsoWebView.kt        # WebView SSO
      HomeScreen.kt        # 资料 + eID PKI + 退出
      ui/Tokens.kt         # 设计令牌（globals.css 的副本）
      ui/Theme.kt          # Material 3 配色 + 排版
    src/test/java/…        # JVM 单元测试（SsoPolicy · Models）
```

## 构建

要求：**JDK 17**、**Android SDK**（`compileSdk 35`、build-tools 35）。
Android Studio（Ladybug+）不是必需，但可直接打开本项目。

```bash
cd mobile/android/TemplateApp

./gradlew test            # JVM 单元测试
./gradlew assembleDebug   # → app/build/outputs/apk/debug/app-debug.apk
./gradlew installDebug    # 安装到已连接的设备/模拟器
```

SDK 路径通过环境变量 `ANDROID_HOME` 或 `local.properties`（`sdk.dir=…`）指定 —
`local.properties` 因机器而异，不纳入 git。

Release APK 未签名（`assembleRelease`）— 上架前请添加自己的签名配置。

## 配置

- **后端地址** — `BuildConfig.GEREGE_APP_URL`，默认
  `https://public.template.gerege.mn`。可在构建时覆盖：

  ```bash
  ./gradlew installDebug -PgeregeAppUrl=http://10.0.2.2:3000
  ```

  （`10.0.2.2` = Android 模拟器中指向宿主机的 `localhost`。）debug 构建允许
  `10.0.2.2` / `localhost` / `127.0.0.1` 使用明文 —— release 构建**只**走 https。
- **Bundle id** — `mn.gerege.temp`（与 iOS 一致）。
- **设计令牌** — `ui/Tokens.kt`。来源是 `frontend/src/app/globals.css`；
  新增颜色只能从那里复制（Web · macOS · Windows · Android 共用同一套调色板）。
- **依赖版本** — 固定写在 `app/build.gradle.kts` 中。升级 Compose BOM 时请一并检查
  `compileSdk`（较新的 AndroidX 版本通常需要更高的 compileSdk）。
