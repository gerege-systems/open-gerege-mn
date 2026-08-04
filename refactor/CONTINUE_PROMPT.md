# Prompt — Modular Framework V4.0-ийг дуусгах (Claude Code CLI)

Чи Gerege платформын modular-framework refactor-ийг ДУУСГАХ ёстой. Төлөвлөгөө
болон хийгдсэн ажлын бүрэн контекст:

- Төлөвлөгөө: `open-gerege-mn/docs/MODULAR_REFACTOR_PLAN.md`
- Хийгдсэн ажлын тайлан: `open-gerege-mn/refactor/REFACTOR_PROGRESS_REPORT*.md` (1–4)
- Бэлэн 10 patch: `open-gerege-mn/refactor/patches/0001..0010` (core репод зориулсан)
- Модуль хөгжүүлэх гарын авлага patch дотор: `docs/MODULES.md`

Аль хэдийн хэрэгжсэн (patch-уудад): kernel/module (манифест, registry, gate,
Host + Provide/AddWorker/OnShutdown), 12 business модуль өөрөө угсардаг,
runtime enable/disable (migration 52 + admin API + audit), platformd
авто-updater, gerege CLI, golden route inventory тестүүд, frontend
primitives (mn репод шууд орсон: BFF proxy, useModules, ModuleGuard).

Ажлыг ҮЕ ШАТ БҮРЭЭР, шат бүрийг тусдаа PR болгож, CI ногоон болмогц
дараагийнхад шилж. Merge-ийг би өөрөө хийнэ — чи PR бэлдээд тайлагна.

## Шат 0 — Patch-уудыг оруулж CI-гээр батлах (эхэлж заавал)

1. open-gerege-core: цэвэр ажлын сан, origin/main-ээс `refactor/modular-framework`
   branch, patch 0001–0010-ыг дараалуулан `git am --3way`.
2. `make pre-push` + `make ci-test-integration` (Docker шаардана — migration 52,
   authz matrix бодит DB дээр батлагдана).
3. Push + PR (main руу ШУУД push хийхгүй — deploy trigger). CI бүх job дуустал
   хяна; унавал тусдаа fix commit-оор зас.

## Шат 1 — Core модулиудын нүүлгэлт (Phase 1 гүйцээлт)

`modules/gspace/module.go`-г загвар болгож auth, users, rbac, org, audit,
site, superadmin, assets core модулиудын wiring-ийг `modules/<id>/`-д нүүлгэ.
Нэг модуль = нэг commit. Хамгаалалт: golden route тест byte-identical байх
ёстой (`TestGoldenRoutes` унавал -update хийхээсээ өмнө шалтгааныг тодруул).
Дуусахад `server.go` нь: bootstrap + kernel-ийн OIDC цөм + host үүсгэлт +
platformModules() дуудлага л үлдэнэ (<200 мөр зорилт).

## Шат 2 — Per-module migration engine (плангийн Phase 2)

1. `kernel/data/migrate`: модуль бүрийн `Migrations() fs.FS` + өөрийн
   `mod_<id>_schema_migrations` хүснэгттэй runner (одоогийн
   core/datasources/migration-ий залгамж).
2. 94 глобал migration-ийг модуль бүрийн baseline болгож дахин зохион байгуул;
   ажиллаж буй DB-д зориулсан нэг удаагийн re-baseline migration.
   **Testcontainers дээр: хуучин schema-тай DB → шинэ runner → бүх хүснэгт/
   өгөгдөл алдагдалгүй гэдгийг батлах integration тест ЗААВАЛ.** Бодит
   production dump дээр туршихыг тайландаа сануул.
3. Migration бодлого: одооноос expand–contract (rollback-д down шаардлагагүй).

## Шат 3 — ui-core nav интеграци + admin "Модулиуд" UI (плангийн Phase 4)

gerege-systems/ui-core репод:
1. `useModules()` client (GET /api/platform/modules) — AppShell-ийн nav,
   dashboard плитка, command palette идэвхгүй модулийн entry-г нуудаг болго.
   Fail-open: жагсаалт ачаалагдаагүй бол бүгдийг харуул (аюулгүй байдлын хил
   нь backend gate, UI нь зөвхөн UX).
2. Admin хэсэгт "Модулиуд" хуудас: GET/PUT /api/v1/platform/admin/modules —
   жагсаалт (нэр, kind, хамаарал, төлөв) + асаах/унтраах toggle,
   баталгаажуулах dialog, алдааг (core модуль, хамаарал) ил харуулна.
3. mn репод BFF admin route-ууд (`checkOrigin` + `sendJSON` конвенцоор),
   `app/admin/modules/page.tsx` нимгэн хуудас, i18n түлхүүрүүд (mn/en/zh/ru
   бүгдэд — parity тест байгаа), README-үүд.

## Шат 4 — Marketplace + түгээлт (плангийн Phase 3 үлдэгдэл, Phase 5)

1. `gerege mod add/remove <id>@<ver>`: gerege-modules registry репогийн
   `index.yaml`-аас татаж `modules_gen.go` генераци + rebuild заавар.
   sha256 checksum шалгалт (cosign-ийг дараагийн ээлж гэж тэмдэглэ).
2. platformd release pipeline: git tag → GitHub Actions → `manifest.json`
   нийтлэх workflow (channels: stable/beta) + docs/DEPLOYMENT-д platformd
   суулгах хэсэг (deploy/platformd/*-ийг ашигла).
3. Gateway enforcement (ROADMAP-ийн ажил): тохируулсан route-уудыг бодит
   reverse-proxy болгож, external container модулийн бүртгэлийн зам нээ.

## Шат 5 — Флот + release (плангийн Phase 6)

1. core v2.0.0-beta таг; MIGRATION_GUIDE (EN/MN/ZH/RU) — NewApp/hook-уудын
   хуучин зам deprecated боловч ажиллана гэдгийг батал.
2. open-gerege-mn-ийн go.mod-ыг шинэ core руу өргөж, docker compose бүрэн
   стекийг локал асааж smoke: eID login дэлгэц, /api/v1/platform/modules,
   модуль унтраахад UI алга болох, platformd dry-run.
3. ROADMAP.md, README-үүд (4 хэл), docs-site-д Modular Platform хэсэг.

## Хатуу дүрмүүд (бүх шатанд)

- Чадвар алдагдахгүй: golden inventory + authz matrix + бүх одоогийн тест
  ногоон байх нь шат бүрийн гарцын нөхцөл.
- Kernel-ээс business import хийхгүй; business модуль business модулиас
  шууд хамаарахгүй (Host service/event-ээр).
- AI guardrail, RLS, security headers, boot guard-ыг модульд тохируулагдахуйц
  болгохгүй. Uninstall/disable үед өгөгдөл автоматаар устгахгүй (archive-first).
- Репо конвенцууд: файлын толгойн Gerege header, комментууд монголоор,
  conventional commits, swag drift, EN/MN/ZH/RU док parity (CLAUDE.md-г мөрд).
- Шат бүрийн төгсгөлд: юу хийснээ, CI линк, дараагийн шатанд юу үлдснийг
  товч тайлагна. Эргэлзсэн газраа таамаглалаа ил бичээд үргэлжлүүл —
  зөвхөн буцаахын аргагүй (production DB, main push, устгал) үйлдэл дээр зогсож асуу.
