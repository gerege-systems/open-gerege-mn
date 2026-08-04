# Modular Framework — Гүйцэтгэлийн тайлан №4

> 2026-08-04 · commit 0009–0010 нэмэгдэв (нийт 10 patch) · 55 package `-race` 0 FAIL

## Юу хийгдэв

### 0009 — provider + eidproxy нүүлгэлт: **12/12 business модуль өөрөө угсардаг боллоо**

- `modules/provider` — OIDC login/consent/logout урсгал (/v1/provider).
  OIDC цөм (Service, гарын үсгийн түлхүүр, нийтийн /.well-known + /oauth2,
  /admin оператор гадаргуу) нь kernel түвшинд ЗОРИУД үлдсэн — root router +
  fail-closed түлхүүр менежменттэй уялдсан хэсэг.
- `modules/eidproxy` — RP-уудын eID service proxy (/v1/eid*, OAuth bearer
  introspection middleware-уудаа өөрөө угсарна).
- Host-д 2 шинэ service: `auth` usecase, `*oidcuc.Service`.
- Golden route inventory өөрчлөгдөөгүй.

### 0010 — `gerege` CLI v1 (оператор хэрэгсэл)

```bash
export GEREGE_API=https://open.gerege.mn GEREGE_ADMIN_TOKEN=...
gerege modules list              # бүх модулийн төлөв (admin token → дэлгэрэнгүй)
gerege modules disable gspace    # restart-гүй унтраана (admin API-аар)
gerege modules enable gspace
gerege modules new ring-pay      # modules/ringpay/module.go skeleton + чеклист
```

Тестлэгдэх цөм `cmd/gerege/cli`-д: httptest-ээр API харилцаа, go/parser-ээр
scaffold-ийн хүчинтэй Go эх код болохыг баталдаг тестүүд. Build:
`go build -o gerege ./cmd/gerege`.

## Одоогийн нийт байдал (10 commit)

| Бүрэлдэхүүн | Төлөв |
|---|---|
| Манифест + registry + gate + 21 модулийн ангилал | ✅ |
| Business модулиуд өөрөө угсардаг (`modules/<id>/module.go`) | ✅ **12/12** |
| Host: Service locator + Provide + AddWorker + OnShutdown | ✅ |
| Runtime enable/disable (DB + admin API + audit) | ✅ |
| `platformd` авто-updater (суваг/цонх/rollback) | ✅ |
| `gerege` CLI (list/enable/disable/new) | ✅ |
| Frontend primitives (BFF + hook + guard) | ✅ (mn репод) |
| docs/MODULES.md гарын авлага | ✅ |

server.go-д үлдсэн inline wiring = зөвхөн core модулиуд (auth, users, rbac,
org, audit, site, superadmin, assets) + kernel-ийн OIDC цөм. Эдгээр нь
"үргэлж суусан" ангилал тул модульчлалын зорилгод нөлөөгүй; дараагийн
цэвэрлэгээний ээлжинд мөн загвараар нүүлгэж болно.

## Баталгаажуулалт

gofmt цэвэр · vet (unit+integration) ✅ · `go test -race` **55 package 0
FAIL** · golden 221 route unchanged · swag drift-гүй · commit бүр build ·
CLI httptest + scaffold parser тестүүд ✅. Integration (testcontainers) —
таны Docker-той орчинд `make ci-test-integration`.

## Үлдсэн (дараагийн ээлжүүд)

1. Core модулиудын нүүлгэлт + `platformModules()` генераци (CLI-д `mod add`).
2. Phase 2: per-module migration engine + 94 migration re-baseline (бодит
   DB dump-тэй туршилт шаардлагатай — тусдаа, болгоомжтой PR).
3. ui-core: nav-ийг `/api/platform/modules`-ээс шүүх + admin "Модулиуд" UI.
4. Marketplace repo + cosign гарын үсэг; gateway enforcement (external
   container модулиуд); core v2.0 таг + флотын шилжилт.

— Gerege Modular Refactor, гүйцэтгэл №4
