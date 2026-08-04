# Modular Refactor — Гүйцэтгэлийн тайлан №1 (Phase 0 + Phase 1 суурь)

> 2026-08-04 · `open-gerege-core` дээр 3 commit · бүх тест ногоон

## Юу хийгдсэн

MODULAR_REFACTOR_PLAN-ийн **Phase 0 бүрэн** + **Phase 1-ийн суурь** нь
`open-gerege-core`-д хэрэгжиж, commit болсон. Кодыг GitHub-ын нээлттэй
репогоос авч ажилласан тул үр дүн нь **3 git patch** хэлбэрээр таны
`refactor/patches/` хавтсанд байна — core репо дээрээ:

```bash
cd open-gerege-core
git am path/to/patches/000*.patch
make pre-push        # локал дээрээ давхар шалгана
```

### Commit 1 — `feat(kernel): add module registry ...`

Шинэ `kernel/module` package (плангийн §2.2–2.3-ын эхлэл):

- `Manifest` — модулийн зарлал: ID, нэр, **kind (core|business)**,
  хамаарлууд, route угтварууд. Validation-тэй.
- `Registry` — concurrency-safe бүртгэл: `Enable`/`Disable`/`Enabled`/
  `List`. Дүрмүүд нь кодоор мөрдөгдөнө: core модуль унтрахгүй; идэвхтэй
  хамаарагчтай модуль унтрахгүй (эхлээд хамаарагчаа); хамаарал нь унтарсан
  модуль асахгүй; давхардсан ID/угтвар, бүртгэлгүй хамаарал, хамаарлын
  **цикл** — бүгд бүтээх үед алдаа.
- `Builtin()` — одоогийн платформын **21 модулийн манифест** (9 core + 12
  business) — плангийн §3-ын ангилал одоо код болов. Route бүрийн эзэн энд.
- `Gate` middleware — идэвхгүй модулийн бүх route **404** (модуль байхгүйтэй
  ижил гадаргуу — тандалт өгөхгүй), v1 BaseResponse хэлбэрийн JSON.
- `ModuleForPath` — хамгийн урт угтвар ялдаг тааруулалт (`/api/v1/admin/ai/`
  → ai, үлдсэн `/api/v1/admin/` → users г.м.).

### Commit 2 — `feat(platform): wire module registry into server boot ...`

- `MODULES_DISABLED` env (CSV) — boot үед business модулиудыг унтраана.
  Core/бүртгэлгүй ID → boot шууд унана (чимээгүй үл тоохгүй). Fixed-point
  алгоритм нь жагсаалтын дарааллыг өөрөө шийднэ (`relay,sign` = `sign,relay`).
- Gate middleware `/api`-д суусан (gateway телеметрийн дараа — хаагдсан
  хүсэлт ч логт үлдэнэ).
- **Шинэ нийтийн endpoint: `GET /api/v1/platform/modules`** →
  `{id, kind, enabled}[]` — frontend nav, mobile/desktop feature flag-ийн
  эх сурвалж (плангийн §2.6-ийн суурь). Дотоод мэдээлэл (хамаарал, route)
  зориуд задлахгүй.
- `App.Modules()` accessor — нимгэн downstream апп-ууд өөрийн модулиа
  бүртгэх зам нээгдэв.
- Swagger docs дахин үүсгэгдсэн. Дашрамд: хуучин docs нь репо
  `platform-core` нэртэй байх үеийн definition нэрстэй **аль хэдийн drift**
  болсон байсныг энэ regen засав (өөрөөр CI-ийн swag-drift gate дараагийн
  аннотаци нэмэхэд унах байсан).

### Commit 3 — `test(routes): golden route inventory ...` (Phase 0 тор)

- **`TestGoldenRoutes`** — бүртгэгддэг **219 endpoint**-ийн бүрэн жагсаалт
  `testdata/routes_golden.txt`-д snapshot болов. Одооноос route алга
  болох/өөрчлөгдөх бүр тест унана; санаатай өөрчлөлтийг `-update`-ээр
  баталгаажуулж commit хийнэ. Refactor-ийн бүх дараагийн алхам энэ торон
  дээр тулна.
- **`TestEveryRouteHasOwnerModule`** — endpoint бүр builtin манифестийн
  **яг нэг модульд** харьяалагдахыг шаардана: эзэнгүй route нэмэх боломжгүй
  болов (модульчлалын үндсэн инвариант).
- **`TestPlatformModulesEndpoint`** — шинэ API-ийн хэлбэр + унтарсан
  модулийн 404 зан төлөвийг төгсгөлөөс төгсгөл шалгана.
- kernel/module-д registry/gate-ийн 8 бүлэг unit тест.

## Тестийн үр дүн (CI gate-уудын толь)

| Шалгалт | Үр дүн |
|---|---|
| `gofmt -l .` | ✅ цэвэр |
| `go vet ./...` | ✅ |
| `go vet -tags=integration ./...` (integration compile) | ✅ |
| `go test -race ./...` (бүх unit) | ✅ **51 package, 0 FAIL** |
| Golden route inventory | ✅ 219 route, бүгд эзэнтэй |
| `go build ./cmd/api/main.go` (binary) | ✅ 54MB binary |
| `swag init` drift | ✅ дахин үүсгэж commit-д багтсан |
| Commit бүр тусдаа build болох | ✅ 3/3 |
| Integration (testcontainers) | ⚠️ энэ орчинд Docker байхгүй тул ажиллаагүй — өөрийн машин дээрээ `make ci-test-integration` (эсвэл CI push) ажиллуулна уу |
| golangci-lint | ⏭️ CI-д одоогоор gate биш (ROADMAP-ийн pending ажил) тул алгассан |
| Frontend | ⏭️ өөрчлөгдөөгүй тул тест шаардлагагүй |

Тэмдэглэл: энэ sandbox-д proxy.golang.org хаалттай байсан тул хамаарлуудыг
GitHub mirror-уудаас нь локал GOPROXY босгож татсан — **бүх модуль go.sum-ийн
H1 hash-аар баталгаажсан** тул supply-chain талаас канон эх кодтой ижил.

## Таны фолдерт орсон файлууд

```
open-gerege-mn/
├── docs/MODULAR_REFACTOR_PLAN.md          (өмнөх — төлөвлөгөө)
├── refactor/
│   ├── REFACTOR_PHASE0_REPORT.md          (энэ тайлан)
│   └── patches/
│       ├── 0001-feat-kernel-...patch      (kernel/module package + тестүүд)
│       ├── 0002-feat-platform-...patch    (server wiring + config + docs)
│       └── 0003-test-routes-...patch      (golden inventory тестүүд)
└── backend/.env.example                    (MODULES_DISABLED баримтжуулалт нэмэгдсэн)
```

## Дараагийн алхам (плангийн дагуу)

1. **Patch-уудыг core репод оруулж CI-гээр бүрэн батлах** (integration
   тестүүд Docker-той орчинд).
2. Phase 1 үргэлжлэл: `server.go`-ийн 943 мөр гар DI-г модуль бүрийн
   `modules/<id>/module.go` руу нүүлгэж эхлэх (голden тест тор одоо бэлэн
   тул аюулгүй). Эхний нүүлгэлтэнд `gspace` шиг жижиг, хамааралгүй модулийг
   санал болгож байна.
3. Frontend: `/api/v1/platform/modules`-ээс уншиж nav-ийг нуух эхний
   хэрэглээ (BFF route + `useModules()` hook).
4. Phase 2: миграцийн engine v2 (per-module migrations).

— Gerege Modular Refactor, гүйцэтгэл №1
