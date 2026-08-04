# Modular Framework — Гүйцэтгэлийн тайлан №2 (плангийн үргэлжлэл)

> 2026-08-04 · `open-gerege-core` дээр нийт **7 commit** (patch series) ·
> frontend-д 3 шинэ файл · бүх тест ногоон

## Товч дүн

Модульчлагдсан framework-ийн **ажиллах бүрэн гогцоо** одоо бэлэн:

```
Манифест (21 модуль, хамаарлын граф)
  → Module.Register(host)      модуль өөрөө угсардаг (server.go мэдэхгүй)
  → Gate middleware            идэвхгүй модуль = 404
  → platform_modules DB        төлөв restart дамнан хадгалагдана
  → PUT /admin/modules/{id}    админ restart-ГҮЙГЭЭР асааж/унтраана
  → /api/platform/modules      frontend/mobile UI-гаа нуудаг
  → platformd                  шинэ release мэдэрч → шинэчилж → health
                               шалгаж → уначихвал өөрөө буцаадаг
```

## Commit тус бүрээр (0004–0007, өмнөх тайлангийн 0001–0003 дээр нэмэгдэв)

### 0004 — Host гэрээ + 3 модулийн wiring нүүлгэлт (Phase 1 үргэлжлэл)

- `kernel/module.Host` — модульд олгох орчин: `APIRouter()`, `Pool()`,
  `AuthMiddleware()`, `Service()` locator (rbac/audit/users/write-limiter).
  Kernel business кодоос хамаардаггүй хэвээр; `ServiceAs[T]` туслагч нь
  төрлийн зөрчлийг boot дээр ил унагаана.
- `kernel/module.Module` — `ID()` + `Register(ctx, host)`.
- **Жишиг нүүлгэлт:** `gspace`, `integrations`, `core-find` гурван модулийн
  бүх repo→usecase→route угсралт `modules/<id>/module.go` руу нүүв —
  server.go тэдний дотоод бүтцийг мэдэхээ больсон. **Golden inventory
  byte-identical** — zan төлөв өөрчлөгдөөгүйн баталгаа. Үлдсэн 18 модуль
  энэ загвараар нэг нэгээрээ нүүнэ (док бэлэн).

### 0005 — Runtime lifecycle (Phase 3-ын cөл)

- Migration **52**: `platform_modules` (зөвхөн ТӨЛӨВ — каталог нь кодын
  манифест тул stale мөр boot унагадаггүй, warning).
- `usecases/platform`: registry дүрэм → DB persistence → audit (best-effort).
- **Админ API:** `GET /api/v1/platform/admin/modules` (дэлгэрэнгүй),
  `PUT /api/v1/platform/admin/modules/{id}` `{"enabled":bool}` —
  **restart-гүйгээр** асааж/унтраана, RequireAdmin хамгаалалттай, hash-chain
  audit-д бичигдэнэ. Boot үед DB төлөв зөөлөн сэргэнэ (хамаарлын дараалал
  fixed-point).

### 0006 — `platformd` (Phase 5: update ооруу мэдэрч, асч буцдаг)

- `kernel/update`: semver (prerelease-тэй), **stable/beta суваг**,
  maintenance цонх (шөнө дамнасан дэмжлэгтэй), **major-bump хамгаалалт**
  (default: гар баталгаажуулалт), apply → health poll → амжилтад VERSION
  файл / унавал **авто-rollback** төлөвийн машин. Fake runner/clock/manifest-
  тэй 6 бүлэг unit тест.
- `cmd/platformd` — env-ээр тохируулагддаг даемон. **Бодит end-to-end smoke
  тест хийгдсэн:** локал манифест v1.6.3→v1.6.4 өгөхөд даемон мэдэрч, apply
  script-ээ зөв env-тэй ажиллуулж, VERSION-оо шинэчилснийг батлав.
- `deploy/platformd/`: `update.sh` (git tag checkout + compose rebuild,
  өмнөх commit-оо хадгална), `rollback.sh`, systemd unit.
- Зарчим: platformd платформыг шинэчилдэг, өөрийгөө биш — supervisor
  update урсгалын гадна тул rollback үргэлж боломжтой.

### 0007 — `docs/MODULES.md` — модуль хөгжүүлэгчийн гарын авлага

Шинэ business модуль нэмэх 5 алхам, идэвхийн удирдлага, platformd-ийн
ажиллагаа, юу хийхгүй жагсаалт.

## Frontend (open-gerege-mn — таны фолдерт шууд орсон)

| Файл | Юу |
|---|---|
| `frontend/src/app/api/platform/modules/route.ts` | BFF proxy (GET, public) |
| `frontend/src/lib/modules.ts` | `useModules()` + `useModuleEnabled()` (TanStack Query, 60с кэш, fail-open UI) |
| `frontend/src/components/ModuleGuard.tsx` | `<ModuleGuard module="ai">…</ModuleGuard>` wrapper |

UI нуулт нь UX; аюулгүй байдлын хил нь backend gate (404). **Nav-ийн бүрэн
интеграци нь `@gerege/ui-core` репод** (nav тэнд амьдардаг) — ui-core-ийн
AppShell-д `useModules()`-ээр цэс шүүх өөрчлөлтийг дараагийн ээлжинд.
Сандбоксод ui-core tarball татагдахгүй тул frontend build-ээ өөрийн машин
дээр `npm run build`-ээр баталгаажуулна уу (шинэ файлууд бие даасан, зөвхөн
одоо буй deps ашигласан).

## Тестийн үр дүн

| Шалгалт | Үр дүн |
|---|---|
| `gofmt -l .` | ✅ цэвэр |
| `go vet` (unit + integration tags) | ✅ |
| `go test -race ./...` | ✅ **54 package, 0 FAIL** (шинэ: kernel/update, usecases/platform, modules/gspace) |
| Golden route inventory | ✅ 221 route (+2 админ endpoint, зориуд `-update`) |
| Swag drift | ✅ regen дараа diff-гүй |
| API + platformd binary build | ✅ |
| Commit бүр тусдаа build (7/7) | ✅ |
| platformd end-to-end smoke | ✅ v1.6.3→v1.6.4 бодит апплай |
| Integration (testcontainers) | ⚠️ энэ орчинд Docker байхгүй — `make ci-test-integration`-ийг өөрөө/CI-гээр (migration 52-ыг мөн бодит DB-д батлана) |

## Суулгах дараалал (production идэвхжүүлэлт)

```bash
# 1. Core репод patch-уудыг оруул
cd open-gerege-core && git am refactor/patches/000*.patch
make pre-push && git push   # CI + integration тест бүрэн батлана

# 2. Таг гаргаж, mn репогийн go.mod-ыг өргө
git tag v1.7.0 && git push --tags
# open-gerege-mn/backend: go get github.com/gerege-systems/open-gerege-core@v1.7.0

# 3. Deploy (migrate service migration 52-ыг апплай хийнэ)
docker compose up -d --build

# 4. platformd-г VPS дээр асаа (сонголттой, дараа нь ч болно)
go build -o /usr/local/bin/platformd ./cmd/platformd
cp deploy/platformd/platformd.service /etc/systemd/system/ && systemctl enable --now platformd
# release pipeline-даа manifest.json нийтлэх алхам нэм

# Туршилт:
curl https://open.gerege.mn/api/v1/platform/modules
# админаар: PUT .../platform/admin/modules/gspace {"enabled":false}
# → /api/gspace/* = 404, UI-д ModuleGuard нуугдана, audit-д бичигдэнэ
```

## Планд үлдсэн ажлууд (дараагийн ээлж)

1. **Үлдсэн 18 модулийн wiring нүүлгэлт** — 0004-ийн загвараар механик,
   модуль тус бүр нэг жижиг PR (golden тест хамгаална).
2. **Phase 2:** per-module migration engine + 94 migration-ийн re-baseline
   (том, тусдаа төлөвлөсөн PR — bодит DB dump дээр туршилт заавал).
3. **`gerege` CLI + marketplace** (Phase 3 үлдэгдэл): `mod add/remove` +
   `modules_gen.go` генераци + cosign шалгалт.
4. **ui-core nav интеграци** (Phase 4 үлдэгдэл) + admin UI "Модулиуд" хуудас.
5. **Gateway enforcement** (external container модулиуд, Phase 5 үлдэгдэл).
6. Phase 6: core v2.0 таг, флотын migration guide.

— Gerege Modular Refactor, гүйцэтгэл №2
