# Modular Framework — Гүйцэтгэлийн тайлан №3 (Phase 1 гүйцээлт)

> 2026-08-04 · commit 0008 нэмэгдэв (нийт 8 patch) · 54 package `-race` 0 FAIL

## Юу хийгдэв

**12 business модулиас 10 нь одоо бүрэн өөрөө угсардаг** —
`modules/<id>/module.go` дотор:

| Модуль | Онцлог |
|---|---|
| `ai` | Gemini repo/tools/чат + нээлттэй чат, өөрийн 3 rate limiter (OnShutdown-тэй), knowledge warm-up goroutine, aiUC-гээ **Provide**-оор нийтэлж core admin route (/admin/ai/prompts) хэрэглэнэ |
| `sign` | Signer материал ачаалалт + PAdES usecase, `ServiceSign` нийтэлж `App.Sign()` accessor түүнээс уншина |
| `gov` | Route + **SLA sweep worker** (60с) — worker-оо өөрөө бүртгэнэ |
| `relay` | Route + SLA sweep (20с) + RELAY_DEMO_MODE simulator (10/25с) worker-ууд |
| `registry` | Админ бүртгэл + нийтийн каталог хоёул |
| `applications` | oauth_clients repo-гоо өөрөө үүсгэнэ (stateless тул давхар instance аюулгүй) |
| `gateway-console` | Удирдлагын гадаргуу (gateway usecase нь kernel-д үлдэнэ — лог queue + eID proxy хамааралтай) |
| `gspace`, `integrations`, `core-find` | (өмнөх ээлжид) |

Үлдсэн inline: core модулиуд (auth, users, rbac, org, audit, site,
superadmin, assets — эдгээр нь үргэлж суudag тул яаралгүй) ба OIDC-той гүн
уялдсан `provider`/`eidproxy` (дараагийн ээлж).

## Host гэрээний өргөтгөл (kernel/module)

- **`Provide(name, svc)`** — модуль usecase-ээ буцааж нийтэлнэ (ai, sign).
- **`AddWorker(name, every, fn)`** — модулийн background ажлууд; App.Run
  асаана, алхам бүр 20с timeout, shutdown-д context-оор зогсоно.
- **`OnShutdown(fn)`** — graceful shutdown-ийн цэвэрлэгээ (limiter Stop г.м.).
- Бүгд СОНГОЛТТОЙ интерфэйс — нимгэн Host (тест, гадаад орчин) заавал
  хэрэгжүүлэхгүй.

`server.go`: sign/relay/gov/ai-ийн бүх талбар, AI pipeline блок, signer
helper-ууд устаж, модулиудын worker/shutdown бүртгэлд шилжив.

## Баталгаа

| Шалгалт | Үр дүн |
|---|---|
| Golden route inventory (221 route) | ✅ **byte-identical** — 7 модулийн нүүлгэлт зан төлөв өөрчлөөгүй |
| `go test -race ./...` | ✅ 54 package, 0 FAIL |
| gofmt / vet (unit + integration) | ✅ |
| Swag drift | ✅ diff-гүй |
| API binary + commit build | ✅ |

Patch-ууд `refactor/patches/`-д шинэчлэгдсэн (0001–0008). Integration
тестийг `git am`-ийн дараа Docker-той орчинд ажиллуулна уу.

## Дараагийн ээлж

1. provider/eidproxy модулийн нүүлгэлт (OIDC service-ийн хил тогтоох).
2. Core модулиудын нүүлгэлт + `platformModules()`-ийг generated болгох
   (`gerege` CLI-ийн эхлэл).
3. Phase 2 migration engine, ui-core nav интеграци, admin "Модулиуд" UI.

— Gerege Modular Refactor, гүйцэтгэл №3
