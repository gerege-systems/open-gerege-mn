# 架构

平台遵循**整洁架构（Clean Architecture）**：`handler → usecase → repository →
domain`。业务核心从不 import Web 框架。

## 组成部分

```
Internet ──► nginx (TLS)
   │
   ├─ /oauth2/*, /.well-known/*, /userinfo ─► Go API — 内置 OIDC issuer
   ├─ /rp/sign/*   ─► eID 签署中继（后端）
   ├─ /rp/eid/*     ─► eID 服务代理 — 个人（后端）
   ├─ /rp/eid-org/* ─► eID 服务代理 — 组织（后端）
   └─ 其余全部     ─► Next.js BFF (web) ──► 后端 API (:8080)
                                                   │
   内部网络:  db (PostgreSQL) · redis
```

## 分层

| 层 | 技术 | 说明 |
|---|---|---|
| **后端** | Go · chi (net/http) · pgx（无 ORM） | 整洁架构、RLS、手写 SQL |
| **前端** | Next.js 16 (BFF) + `@gerege/ui-core` | 浏览器只与同源路由通信；令牌绝不进入客户端 JS |
| **OIDC 提供方** | 内置（Go，usecases/oidc） | 平台自行驱动登录/授权/登出流程 |
| **身份** | eID Mongolia RP | 电子身份证验证 |
| **缓存/队列** | Redis | 会话拒绝名单、临时状态 |
| **AI** | Gemini（免 SDK 的 REST） | 聊天、语音、翻译 |

## 安全

- **行级安全（RLS）** — 每个用户只能看到属于自己的数据行；启动时会有可执行性守卫
  （生产环境要求使用非超级用户角色）。
- **BFF 模式** — 令牌保存在 httpOnly Cookie 中，绝不出现在浏览器 JS 里。
- **双重 CSRF** — 自定义请求头 + 来源（origin）校验。
- **安全响应头** — CSP、HSTS、COOP/COEP/CORP；按 IP 限流。
- **审计** — 哈希链式、仅追加的审计轨迹。

## 后端目录结构 —— 来自内核

上述所有能力（认证、RBAC、网关、审计、OIDC 提供方、eID/SSO、AI）**都没有写在
本仓库里** —— 它们通过 `go.mod` 来自 `open-gerege-core` 这个 Go 模块。因此
`backend/` 中**只有一个 Go 文件**：

```
backend/
├── cmd/api/main.go        # 约 30 行：启动内核，再加上自己的路由
├── deploy/                # Dockerfile、数据库初始化
└── .env.example           # 配置模板
```

```go
func main() {
    server.ServiceName = "gerege-template"
    app, err := server.NewApp()          // ← 全部能力来自内核
    // 在此添加本应用自己的路由：
    //   app.Router().Route("/api/xxx", xxx.Routes(app.Pool()))
    app.Run()
}
```

内核为**单层**：**`open-gerege-core`**，政务线与 Gerege 线均直接使用。
（2026-08-02 之前其上还有封闭的 `private-gerege-core` 层，现已从链路中移除。）

## 前端目录结构 — `@gerege/ui-core`

前端的大部分代码位于**共享包**中。应用只保留自身特有的部分：品牌、landing 文案
以及平台特定页面。

```
frontend/
├── src/brand.config.ts     # 品牌信息的唯一来源（名称、域名、docsUrl…）
├── src/components/landing/ # 应用自己的 landing 文案
├── src/app/api/**/route.ts # BFF 路由的单行包装（共 158 个）
└── node_modules/@gerege/ui-core
    ├── src/api/**          # BFF 路由的真正逻辑
    └── src/components/**   # AppShell、UserMenu、admin/gov/gateway 页面
```

- 该包在 `package.json` 中**按 tag 固定**
  （`…/ui-core/archive/refs/tags/v0.4.0.tar.gz`）— 升级是显式的，不会误升。
- 每个路由都是包装：`export { GET, POST } from '@gerege/ui-core/api/<路径>'`。
  Next.js 依据文件系统注册路由，因此包装不可省略；`npm run check:routes`
  会抓出包内存在、但应用中没有包装的路由。
- 该包绝不 import 应用的 `brand.config.ts` — 相关值通过 `<UiCoreProvider>`
  传入（`brandName`、`docsUrl`、`docsLangs`）。在其他文件里硬编码品牌名会被
  `npm run check:brand` 拒绝。

两项检查都属于 `npm run build`，因此由 CI 强制执行。
