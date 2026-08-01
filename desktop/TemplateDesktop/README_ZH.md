# Gerege Template Platform V3.0 — 桌面应用 (TemplateDesktop)

> 🌐 [Монгол](README.md) · **中文** · [Русский](README_RU.md)

> **构建电子服务的基础平台** — _一个平台，服务政府与私营部门。_

**Gerege Template Platform V3.0** 的**桌面客户端**。这是一个 Electron 外壳——
以 **1:1** 的方式加载平台的 Web 界面，并在浏览器之外提供原生窗口、菜单、
快捷键与权限策略。

> **没有重写任何东西：** 页面、流程、设计、国际化、BFF 全部来自 `frontend/`
> 的同一份代码。桌面层没有自己的 UI，因此 Web 端的更新**无需重新打包**即可
> 直接出现在应用中。

当前支持的平台为 **macOS 12+**。`electron-builder.yml` 中已准备好 Windows/Linux
的基础配置，但尚未验证。

## 架构

```
┌────────────────────────────┐
│  TemplateDesktop (Electron)│  窗口 · 菜单 · 导航策略 · 权限
│  ┌──────────────────────┐  │
│  │ Chromium BrowserWindow│ │  →  https://template.gerege.mn  (Next.js BFF)
│  └──────────────────────┘  │           │
└────────────────────────────┘           └→  Go API (/api/v1/*) — 应用不直接访问
```

- 应用**不直接访问后端**——所有请求都经过 Web 应用的 BFF。
- 会话保存在 **httpOnly cookie**（`dgov_access` / `dgov_refresh`）中。Chromium
  的 cookie 存储持久化于 `userData`，重启应用后仍保持登录状态。
- CSRF、Origin 校验、CSP 全部沿用 Web 端逻辑。桌面层不接触任何令牌，也不会
  将其暴露给 JS。

### 窗口 preload

preload 会根据所加载页面的协议提供两种不同的桥接：

| 页面 | 协议 | 桥接 | 能力 |
|---|---|---|---|
| Web 应用 | `https:` | `window.geregeDesktop` | 仅只读标记（`isDesktop`、`platform`、`appVersion`、`overlayTitleBar`、`titleBarInset`） |
| 内部页面 | `file:` | `window.geregeShell` | 切换服务器、重新加载、关闭窗口 |

远程内容**永远**接触不到外壳的 IPC。主进程还会按发送方的 `file://` 地址
二次校验每一次 IPC（`src/main.ts` → `fromInternalPage`）。

### 导航策略（`src/policy.ts`）

| 地址 | 行为 |
|---|---|
| 应用自身 origin | 在窗口内打开 |
| `*.gerege.mn`、`eidmongolia.mn`、`accounts.google.com`、`*.dropbox.com` | 在窗口内打开——OAuth 回调必须回到应用的 cookie 存储 |
| 其他 `http(s)`（文档、GitHub、dgov.mn） | 交给系统浏览器 |
| `mailto:`、`geregesmartid://` 等 | 交给操作系统 |
| `javascript:`、`data:`、跨 origin 的 `blob:` | 完全阻止 |

`<webview>` 被拦截，设备权限（HID/Serial/USB）关闭。浏览器权限中仅开放
**麦克风**（AI 对话 · 语音消息 · 实时翻译）、通知与全屏——摄像头与定位关闭。

User-Agent 中的 `Electron/…` 标记会被移除：Google、Dropbox 等登录服务会拒绝
带该标记的用户代理。Chromium 的真实版本号保持不变。

## 桌面视图

Web 应用仍是**同一份代码**——但桌面窗口没有浏览器标签页和地址栏，却有窗口控件。
因此没有另写一套 UI，只增加了一层样式：

```
preload  →  window.geregeDesktop { isDesktop, platform, overlayTitleBar, titleBarInset }
              ↓  (theme-bootstrap.js —— 在 hydration 之前)
<html data-desktop="darwin" data-titlebar="overlay" style="--titlebar-inset: 78px">
              ↓
frontend/src/app/globals.css → html[data-desktop] { … }
```

标记由阻塞式 `public/theme-bootstrap.js` 写入，因此桌面视图**从首次绘制**即生效，
不会出现布局闪烁。

| 变化 | 原因 |
|---|---|
| macOS 下标题栏融入窗口（`hiddenInset`） | 应用顶行（icon rail · sidepanel 头部 · `topbar2`）本身就是标题栏，避免 64px 的重复横条 |
| 整个顶行成为**拖拽区** | 任意位置都能移动窗口。按钮/搜索/菜单为 `no-drag`，点击照常 |
| 左上角预留 `--titlebar-inset`（78px） | 交通灯按钮不会压住内容 |
| 菜单与侧栏文字不可选中 | 原生窗口的 chrome 不是文本，拖拽时"高亮"属于瑕疵 |
| 细滚动条、关闭橡皮筋滚动 | 贴近 macOS 原生手感 |

交通灯按钮位于 icon rail 顶部，因此那里的**小号品牌图标被隐藏**（品牌名仍在
sidepanel 头部）。全屏时按钮会消失，而 DOM 无法感知——由外壳自己通过
`webContents.insertCSS` 把预留间距归零（`src/windows.ts`）。

Windows/Linux 仍使用**标准窗口边框**（不写入 `data-titlebar`）——这两个平台在本仓库
尚未验证，因此不冒险自绘窗口控件。`data-desktop` 标记在所有平台都会写入。

## 自动更新

应用会**自行**发现新版本、下载并重启——用户无需手动下载安装。基于
[`electron-updater`](https://www.electron.build/auto-update)。

```
启动后 30 秒 → 之后每 6 小时 → 读取 latest-mac.yml
        ↓ 是否确为更新版本（semver 校验——绝不下载旧包）
    后台下载（菜单标签显示百分比）
        ↓ 完成后
   「立即重启」/「稍后」
        ↓                ↓
   立即安装并恢复    退出应用时自动安装
```

**为什么要询问：** 下载完成的那一刻用户可能正在填表单、与 AI 对话——此时静默
关闭应用会丢失数据。默认按钮是「立即重启」；即便推迟，`autoInstallOnAppQuit`
也会在下次退出时自动安装。两种情况都不需要手动下载。

菜单中的**「检查更新…」**（macOS：应用菜单；其他：帮助菜单）会显示当前状态——
`Шинэчлэлт татаж байна… 42%`、`Шинэчлэлт бэлэн (1.1.0) — дахин эхлүүлэх`。
只有手动检查才会弹出「已是最新」/错误提示；自动检查全程静默。

| 配置 | 值 |
|---|---|
| 更新源 | `https://template.gerege.mn/desktop/updates/`（`src/config.ts` 与 `electron-builder.yml` **必须一致**） |
| `GEREGE_UPDATE_URL` | 临时切换更新源（测试 staging）。仅限 **https**（loopback 可用 http），非法值回退到默认源 |
| `GEREGE_UPDATE_DEV=1` | 在未打包模式下强制检查（需要 `dev-app-update.yml`） |

**刻意不提供**从用户界面切换更新源的功能——切换更新源等同于替换代码。

### 发布新版本

```bash
# 1. 提升 package.json 中的 version（semver）
npm version patch --no-git-tag-version

# 2. 签名包（自动更新**必须**签名）
npm run dist:mac:signed

# 3. 将 release/ 中的产物上传到更新源目录
#    Gerege Template-<v>-arm64-mac.zip        ← Squirrel.Mac 只从 zip 安装
#    Gerege Template-<v>-arm64-mac.zip.blockmap
#    Gerege Template-<v>-x64-mac.zip (+ blockmap)
#    latest-mac.yml                            ← 更新源指针——务必最后上传
#    （dmg 仅用于首次手动安装，不参与更新）
```

最后上传 `latest-mac.yml` 很关键：若包尚未传完而指针已更新，应用会去下载不存在的
文件并报错。

> ⚠️ **未签名的构建无法自动更新。** macOS 的 Squirrel.Mac 会将下载包的代码签名与
> 已安装应用比对，不匹配即拒绝安装。本地测试包（`npm run dist:mac`）可以检查并
> 下载更新，但会在安装环节失败。

## 开发

```bash
cd desktop/TemplateDesktop
npm install

npm start        # 连接生产服务器（template.gerege.mn）
npm run dev      # 连接本地 frontend（localhost:3000）并打开 DevTools
npm test         # 导航 / 权限策略测试（node --test）
npm run typecheck
```

运行 `npm run dev` 前，请先在另一个终端执行 `cd frontend && npm run dev`。

### 选择服务器

优先级：`GEREGE_APP_URL` 环境变量 → 应用内保存的选择 → `template.gerege.mn`。

菜单中的**切换服务器…**（`⌘⇧S`）支持预设或自定义地址，选择保存在
`userData/state.json`。若设置了 `GEREGE_APP_URL`，下次启动仍以其为准
（窗口内会给出提示）。

## 打包

```bash
npm run icon           # frontend/public/brand.webp → resources/icon.icns
npm run dist:mac       # release/*.dmg + *.zip（arm64 · x64），未签名
```

未签名的构建**仅供本地测试**——macOS Gatekeeper 会提示应用"已损坏"
（`xattr -dr com.apple.quarantine "/Applications/Gerege Template.app"`
或在 系统设置 → 隐私与安全性 中选择"仍要打开"）。

对外分发需要 Apple Developer ID：

```bash
export CSC_LINK=... CSC_KEY_PASSWORD=...          # Developer ID Application 证书
export APPLE_ID=... APPLE_APP_SPECIFIC_PASSWORD=... APPLE_TEAM_ID=...
npm run dist:mac:signed                            # 签名 + 公证
```

Hardened runtime、entitlements（`build/entitlements.mac.plist`）与
`NSMicrophoneUsageDescription` 均已预先配置。

## 文件结构

```
src/
  main.ts        应用入口——session、权限、IPC、生命周期
  windows.ts     创建窗口、保存位置、绑定导航策略
  menu.ts        系统菜单（蒙古语）
  policy.ts      纯决策函数——classifyURL、allowPermission、UA 清理
  update.ts      纯决策函数——semver 比较、检查节流、菜单标签
  updater.ts     自动更新流程（electron-updater、询问、重启）
  config.ts      基础地址、白名单、更新源、地址规范化
  store.ts       userData/state.json（窗口位置、服务器、上次检查时间）
  preload.ts     按协议区分的两个桥接
  policy.test.ts 策略测试
  update.test.ts 更新决策测试
static/          内部页面——offline.html、server.html、shell.css
build/           entitlements
resources/       icon.icns
scripts/         make-icon.sh
```

## 快捷键

| 快捷键 | 操作 |
|---|---|
| `⌘R` / `⌘⇧R` | 重新加载 / 强制重新加载 |
| `⌘[` / `⌘]` | 后退 / 前进（也支持双指滑动） |
| `⌘+` / `⌘-` / `⌘0` | 放大 / 缩小 / 实际大小 |
| `⌘N` | 新建窗口 |
| `⌘P` | 打印 |
| `⌘,` | 设置（`/me/settings`） |
| `⌘⇧S` | 切换服务器 |
| `⌘⇧H` | 首页 |

## 限制与注意事项

- **需要联网**——没有离线模式。服务器不可达时会显示内部离线页面，可通过
  "重试"恢复（网络恢复后也会自动重试）。
- **自动更新只覆盖外壳。** Web 内容始终是最新的，因此新版本只在外壳（窗口、菜单、
  策略）变更时发布。未签名的构建无法完成安装步骤（见上文警告）。
- **桌面视图只是一层样式。** 页面与流程与 Web 保持 1:1——桌面端仅通过
  `html[data-desktop]` 调整 chrome。
- `geregetemp://eid/callback`（iOS App2App 桥）在桌面端未注册——桌面的 eID
  流程走 `/auth/eid/callback`。
- `npm audit` 会对 `electron-builder` 的传递依赖发出告警。这些**仅在构建期**
  使用，不会进入打包产物；修复需要将 electron-builder 降级到不兼容版本，
  因此暂缓处理。

## 相关文档

- [frontend/README.md](../../frontend/README.md) — Web 应用（内容来源）
- [ios/TemplateApp/README_ZH.md](../../ios/TemplateApp/README_ZH.md) — iOS 客户端
- [docs/DEPLOYMENT.md](../../docs/DEPLOYMENT.md) — 服务器部署
