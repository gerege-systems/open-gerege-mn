# Architecture

The platform follows **Clean Architecture**: `handler → usecase → repository →
domain`. The business core never imports the web framework.

## Components

```
Internet ──► nginx (TLS)
   │
   ├─ /oauth2/*, /.well-known/*, /userinfo ─► Go API — built-in OIDC issuer
   ├─ /rp/sign/*   ─► eID sign relay (backend)
   ├─ /rp/eid/*     ─► eID service proxy — personal (backend)
   ├─ /rp/eid-org/* ─► eID service proxy — organizations (backend)
   └─ everything else ─► Next.js BFF (web) ──► backend API (:8080)
                                                   │
   internal network:  db (PostgreSQL) · redis
```

## Layers

| Layer | Technology | Notes |
|---|---|---|
| **Backend** | Go · chi (net/http) · pgx (no ORM) | Clean Architecture, RLS, hand-written SQL |
| **Frontend** | Next.js 16 (BFF) + `@gerege/ui-core` | The browser talks only to same-origin routes; tokens never reach client JS |
| **OIDC provider** | Built-in (Go, usecases/oidc) | the platform drives login/consent/logout itself |
| **Identity** | eID Mongolia RP | electronic-ID verification |
| **Cache/queue** | Redis | session deny-list, transient state |
| **AI** | Gemini (SDK-free REST) | chat, voice, translation |

## Security

- **Row-Level Security (RLS)** — each user sees only their own rows; a boot-time
  enforceability guard (requires a non-superuser role in production).
- **BFF pattern** — tokens live in httpOnly cookies, never in browser JS.
- **Double CSRF** — custom header + origin check.
- **Security headers** — CSP, HSTS, COOP/COEP/CORP; per-IP rate limiting.
- **Audit** — hash-chained, append-only trail.

## Backend layout — it comes from the core

Every capability above (auth, RBAC, gateway, audit, OIDC provider, eID/SSO, AI)
is **not written in this repository** — it arrives from the `public-gerege-core`
Go module via `go.mod`. As a result `backend/` holds **exactly one Go file**:

```
backend/
├── cmd/api/main.go        # ~30 lines: start the core, add your own routes
├── deploy/                # Dockerfile, db init
└── .env.example           # configuration template
```

```go
func main() {
    server.ServiceName = "gerege-template"
    app, err := server.NewApp()          // ← every capability from the core
    // Add this app's own routes here:
    //   app.Router().Route("/api/xxx", xxx.Routes(app.Pool()))
    app.Run()
}
```

The core comes in two layers: **`public-gerege-core`** (the open foundation,
consumed directly by the government line) and **`private-gerege-core`**, which
inherits from it via `go.mod` (closed, used by the Gerege line).

## Frontend layout — `@gerege/ui-core`

Most of the frontend lives in a **shared package**. The app owns only what is
specific to it: branding, landing copy and platform-specific pages.

```
frontend/
├── src/brand.config.ts     # single source of truth for branding (name, domain, docsUrl…)
├── src/components/landing/ # the app's own landing copy
├── src/app/api/**/route.ts # ONE-LINE wrappers for the BFF routes (158 of them)
└── node_modules/@gerege/ui-core
    ├── src/api/**          # the actual BFF route logic
    └── src/components/**   # AppShell, UserMenu, admin/gov/gateway screens
```

- The package is **pinned by tag** in `package.json`
  (`…/ui-core/archive/refs/tags/v0.4.0.tar.gz`) — upgrades are explicit, never
  accidental.
- Every route is a wrapper: `export { GET, POST } from '@gerege/ui-core/api/<path>'`.
  Next.js registers routes from the file system, so the wrapper is mandatory;
  `npm run check:routes` catches package routes that have no wrapper in the app.
- The package never imports the app's `brand.config.ts` — values arrive through
  `<UiCoreProvider>` (`brandName`, `docsUrl`, `docsLangs`). Hard-coding the brand
  name anywhere else is rejected by `npm run check:brand`.

Both checks are part of `npm run build`, so CI enforces them.
