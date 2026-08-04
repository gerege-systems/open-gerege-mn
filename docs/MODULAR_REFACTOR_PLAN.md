# Модульчлагдсан Framework — Refactoring төлөвлөгөө

> **Gerege Template Platform V3.0 → V4.0 "Modular Platform"**
> open-gerege-core + open-gerege-mn экосистемийг core / business модулиудад
> хуваасан, business модулийг суулгаж/устгаж болдог, update-ээ өөрөө мэдэрч
> шинэчлээд асдаг платформ болгох бүрэн төлөвлөгөө.
>
> **Тэг зарчим: одоо байгаа чадвараас ЮУ Ч алдагдахгүй.** §9-д одоогийн
> бүх чадвар → шинэ модулийн байршлын бүрэн зураглал бий.

---

## 1. Одоогийн байдлын үнэлгээ

### 1.1 Сайн хийгдсэн (хадгална, эвдэхгүй)

| Юу | Яагаад үнэ цэнтэй |
|---|---|
| Clean Architecture давхаргууд (`handler → usecase → repository → domain`) | Модулийн дотоод бүтэц болж шууд ашиглагдана |
| Repository interface (`repositories/interface`) + postgres adapter тусгаарлалт | Модулийн boundary-д бэлэн |
| `App` фасад (`Router()`, `Pool()`, `AuthMiddleware()`, `Users()`, `Sign()`) | Kernel API-ийн үр хөврөл — аль хэдийн downstream апп-ууд hook-оор өргөтгөдөг (`WalletProvisioner`) |
| Authz-matrix integration тест, route pattern тест | Refactor-ийн үеийн гол хамгаалалтын тор |
| API gateway-ийн удирдлагын загвар (services/routes/consumers/keys/policies) | Гадаад (container) модулиудын бүртгэлийн суурь болно |
| RLS + boot guard, audit hash-chain, security headers | Kernel-ийн өөрчлөгдөхгүй "хатуу цөм" |
| `merge=ours` удамшлын загвар (брэнд/deploy файлууд) | Флотын шинэчлэлт хэвээр ажиллана |

### 1.2 Дутуу / буруу хийгдсэн (refactor-ийн бай)

1. **Monolithic wiring.** `cmd/api/server/server.go` = 943 мөр гар DI: 30+
   usecase, 25+ repository, 30+ route бүгд нэг функцэд hardcode. Модуль
   нэмэх/хасах = core-ийн голыг засах. *Энэ бол хамгийн том өр.*
2. **Нэгдсэн migration дараалал.** 94 migration нэг глобал дугаарлалттай
   (`1..51`), домэйнууд хоорондоо шүргэлцэнэ (жишээ нь `17_` давхардал аль
   хэдийн гарсан). Модуль өөрийн schema хувилбараа эзэмшиж чадахгүй.
3. **`routes` package — бүх домэйны route нэг санд.** Route бүр өөрийн
   usecase-ийн import-той тул `routes` нь бүх домэйнээс хамаардаг "God package".
4. **`config.go` — 581 мөрийн нэг struct.** AI, eID, gateway, SFTP, Hydra…
   бүх модулийн тохиргоо нэг дор; модуль idэвхгүй байсан ч env-үүд нь
   глобал орон зайд амьдардаг.
5. **RBAC permission каталог глобал migration-аар seed хийгддэг.** Модуль
   өөрийн permission-оо авчирч/буцааж чаддаггүй.
6. **Модулийн ойлголт БАЙХГҮЙ:** manifest, версийн бүртгэл, install/enable/
   disable/uninstall lifecycle, модулийн health — аль нь ч үгүй. On/off нь
   зөвхөн env-ийн байгаа эсэхээр далд шийдэгддэг (Hydra, OAUTH_ISSUER,
   Gemini key г.м.) — далд feature-flag нь баримтгүй, шалгагдахгүй.
7. **Frontend бүхэлдээ hardcode.** `app/` модны 25+ route бүлэг, BFF-ийн
   80+ proxy route, нэг `i18n.ts` толь, нэг nav — модуль унтраахад UI талд
   юу ч алга болдоггүй.
8. **Gateway нь enforcement биш.** Одоогоор удирдлага + телеметр; бодит
   reverse-proxy биш тул гадаад модулийг залгах зам хараахан алга
   (ROADMAP-д ч тэмдэглэгдсэн).
9. **Update механизм байхгүй.** Deploy = гар runbook (compose pull/build);
   систем өөрөө шинэ хувилбар мэдэрдэггүй, rollback гар ажиллагаатай.

---

## 2. Зорилтот архитектур (Target)

Дэлхийн платформуудын шилдэг зарчмуудаас авч буй загвар:
**modular monolith + microkernel** (Shopify/Spring Modulith загвар),
**манифесттэй extension lifecycle** (VS Code / Kubernetes operator),
**хоёр төрлийн модулийн байршуулалт** (Grafana: in-process + external),
**semver + сувагт update, авто-rollback** (GitLab Omnibus / Talos загвар).
Go runtime-д dynamic code loading найдваргүй (`plugin` package-ийг
production-д хэн ч хэрэглэдэггүй) тул **"суулгах" = build-время бүрдүүлэлт +
blue-green солилт**, харин **хүнд/гуравдагч модуль = тусдаа container +
gateway бүртгэл** гэсэн hybrid зам сонгосон (таны баталсан сонголт).

### 2.1 Гурван давхарга

```
┌─────────────────────────────────────────────────────────────┐
│  BUSINESS МОДУЛИУД (суулгаж/устгаж болно)                   │
│  gov · ai · sign · relay · integrations · gspace · registry │
│  provider(OIDC) · gateway-console · theme …                 │
├─────────────────────────────────────────────────────────────┤
│  CORE МОДУЛИУД (үргэлж байна, unінstall хийгдэхгүй)         │
│  auth(eID+Google+SSO) · users · rbac · org · audit ·        │
│  security · site · language · assets · superadmin           │
├─────────────────────────────────────────────────────────────┤
│  KERNEL (framework runtime — модуль БИШ)                    │
│  http host (chi) · config · DB/Redis drivers · RLS ·        │
│  migration engine · module registry & lifecycle ·           │
│  event bus · observability · apperror · validators · jwt    │
└─────────────────────────────────────────────────────────────┘
```

Хараат байдлын дүрэм (import-ын чиглэл, lint-ээр мөрдүүлнэ):

- Kernel ХЭНЭЭС Ч хамаарахгүй (модулиудыг мэдэхгүй).
- Core модуль → зөвхөн kernel + бусад core модулийн **interface**.
- Business модуль → kernel + core модулийн interface. **Business модуль
  business модулиас шууд хамаарахгүй** — зөвхөн event bus эсвэл
  зарлагдсан extension point-оор харилцана.

### 2.2 Модулийн гэрээ (Module contract)

Repo бүтэц (core repo дотор):

```
open-gerege-core/
├── kernel/                    # одоогийн pkg/ + drivers + config + apperror
│   ├── app/                   # host: DI container, lifecycle, health
│   ├── module/                # Module interface, registry, manifest
│   ├── httpx/                 # chi host, middlewares, response helpers
│   ├── data/                  # pgx drivers, redis, RLS, migration engine
│   ├── events/                # in-proc event bus + transactional outbox
│   └── obs/                   # otel, prometheus, zap
├── modules/
│   ├── auth/                  # core модуль бүр өөрийн бүрэн стектэй:
│   │   ├── module.go          #   Module interface-ийн хэрэгжилт (DI энд!)
│   │   ├── manifest.yaml      #   ID, версия, төрөл, хамаарал, permissions
│   │   ├── domain/ usecase/ repo/ handler/ routes.go
│   │   ├── migrations/        #   ЗӨВХӨН энэ модулийн SQL
│   │   └── frontend/          #   энэ модулийн UI багц (§2.6)
│   ├── users/  rbac/  org/  audit/ …
│   ├── gov/    ai/    sign/  relay/ …
└── cmd/api/main.go            # kernel + модулийн жагсаалт (генерацитай)
```

Go interface (kernel/module/module.go):

```go
type Module interface {
    Manifest() Manifest                 // ID, semver, kind(core|business), deps
    Register(ctx context.Context, host *app.Host) error // DI + routes өөрөө
}

// Сонголтот чадварууд — хэрэгжүүлсэн модульд нь kernel автоматаар дуудна:
type HasMigrations interface{ Migrations() fs.FS }
type HasPermissions interface{ Permissions() []rbac.PermissionDef }
type HasJobs        interface{ Jobs() []jobs.Spec }          // background workers
type HasAITools     interface{ AITools() []ai.ToolDef }      // AI function-calling
type HasNav         interface{ Nav() []nav.Entry }           // frontend цэс
type HasEventHooks  interface{ Subscriptions() []events.Sub }
type HasHealth      interface{ Health(ctx) error }
type HasUninstall   interface{ OnUninstall(ctx, host, DataPolicy) error }
```

manifest.yaml жишээ (business модуль):

```yaml
id: gov
name: "Төрийн үйлчилгээний портал"
kind: business            # core | business
version: 2.0.0
core: ">=2.0.0 <3.0.0"    # kernel/core нийцтэй хүрээ (semver)
depends: [auth, users, rbac, org]     # core модулиуд
optional: [ai]            # байвал AI tool-оо бүртгэнэ, байхгүй бол алгасна
db:
  schema: mod_gov         # өөрийн Postgres schema (§2.4)
permissions: [gov.services.read, gov.applications.manage, ...]
routes:  [/api/gov/*]
frontend:
  nav: [{area: me, key: services}, {area: me, key: applications}, ...]
  bff: [/api/gov/*]
config:                   # env prefix — kernel зөвхөн энэ prefix-ийг өгнө
  prefix: GOV_
uninstall:
  data: archive           # archive | keep | drop(зөвхөн гараар баталгаажуулж)
```

### 2.3 Kernel-ийн шинэ үйлчилгээнүүд

1. **Module Registry (DB):**

```sql
CREATE TABLE platform_modules (
  id           text PRIMARY KEY,        -- 'gov'
  version      text NOT NULL,
  kind         text NOT NULL,           -- core | business | external
  status       text NOT NULL,           -- enabled | disabled | installing
                                        -- | failed | pending_uninstall
  checksum     text,                    -- багцын sha256 (signing §2.7)
  installed_at timestamptz, updated_at timestamptz,
  config       jsonb DEFAULT '{}'
);
```

2. **Lifecycle engine.** Boot үед: манифест унших → dependency graph
   байгуулах (topological sort) → модуль тус бүрийн migration ажиллуулах →
   permission sync → `Register()` → job/AI tool/nav бүртгэх → health.
   Модуль fail болбол (config дутуу г.м.) — **платформ унахгүй**, тухайн
   модуль `failed` төлөвт орж, route-ууд нь 503 + admin UI-д шалтгаан
   харагдана. (Одоогийн "env байхгүй бол чимээгүй алгасах"-ын оронд ил
   төлөвтэй болно.)
3. **Enable/Disable — restart-гүй.** Бүх модулийн route нэг gate
   middleware-ээр ороосон: `if !registry.Enabled("gov") → 404`. Disable
   нь агшин зуурын (DB флаг + cache invalidate), install/uninstall л build
   шаарддаг. Nav/feature API мөн registry-ээс уншина.
4. **Event bus.** In-process publish/subscribe + чухал үйл явдалд
   transactional outbox (audit, мэдэгдэл). Business модулиуд хоорондоо
   зөвхөн үүгээр ярина (жишээ: `sign.completed` → gov модуль сонсоно).
5. **Config namespacing.** Kernel config (DB, Redis, JWT, HTTP) + модуль
   бүрийн prefix-тэй хэсэг. Модуль зөвхөн өөрийн namespace-ийг авна;
   `config.AppConfig` глобалыг үе шаттай устгана.

### 2.4 Өгөгдлийн сангийн стратеги

- **Модуль бүр өөрийн Postgres schema** (`mod_gov`, `mod_ai`, …); core
  модулиуд `public`-д үлдэж болно (users, rbac — бусад нь FK-ээр харьдаг).
- **Migration engine v2:** модуль бүр өөрийн `migrations/` fs.FS + өөрийн
  `mod_<id>.schema_migrations` хүснэгт. Глобал дугаарлалтын мөргөлдөөн
  бүрмөсөн арилна.
- **Одоогийн 94 migration-ийг re-baseline хийнэ:** module бүрт `0001_baseline.sql`
  (одоогийн эцсийн төлөв). Шинэ суулгац baseline-аас эхэлнэ; ажиллаж буй
  DB-үүд `re-baseline` migration-аар (хүснэгтүүдийг schema руу `ALTER TABLE
  ... SET SCHEMA` нүүлгэх) шилжинэ. Down файлуудын зарчим хэвээр.
- **Uninstall-ийн өгөгдлийн бодлого:** default = `archive` (schema-г
  `archived_mod_gov_<ts>` болгож нэрлэх + export). **Автомат DROP хэзээ ч
  хийхгүй** — зөвхөн superadmin-ийн 2 шаттай баталгаажуулалтаар.
- Cross-module унших хэрэгцээг interface-ээр (`users.Reader` г.м.), SQL
  JOIN-оор биш — schema хилийг lint/тестээр хамгаална.

### 2.5 Түгээлт ба install/uninstall урсгал (hybrid)

**A. In-process business модуль (үндсэн зам):**

```
Marketplace (Git registry: gerege-modules/index.yaml + модуль бүр Go module)
      │  gerege mod add gov@v2.1.0
      ▼
CLI/Builder service:
  1. манифест татаж checksum + гарын үсэг шалгана (§2.7)
  2. go.mod-д нэмж modules_gen.go-г дахин генерацилна
     (import _ "…/modules/gov" + registry.Add(gov.New()))
  3. шинэ image build (docker buildx, layer cache)
  4. blue-green: шинэ container асаана → migration + health OK →
     traffic шилжүүлнэ → хуучныг унтраана; health FAIL → хуучин хэвээр,
     төлөв=failed, лог admin UI-д
```

`gerege` CLI бол шинэ бүтээгдэхүүн-хэрэгсэл (Go binary, VPS дээр сууна);
admin UI-ийн "Модулиуд" хуудас нь үүнийг API-аар (builder service) дууддаг.

**B. External/container модуль (хүнд, өөр хэл, гуравдагч этгээд):**

- Модуль = OCI image + ижил manifest.yaml. `gerege mod add --external`
  нь compose/systemd unit үүсгэж, **gateway-г бодит reverse-proxy болгож
  хэрэгжүүлсний** (одоогийн ROADMAP ажил) дараа route-ыг нь gateway-д
  бүртгэнэ. Auth нь kernel-ийн JWT/introspection middleware-ийг gateway
  түвшинд ашиглана. Ингэснээр ROADMAP-ийн "gateway enforcement" ажил
  модулийн архитектурын хэсэг болж давхар үр өгнө.

### 2.6 Frontend модульчлал (Next.js BFF)

Next.js-ийн app router build-время статик тул frontend ч мөн "build-время
бүрдүүлэлт + registry-ээр нуух" загвар:

- Модуль бүрийн UI нь core repo-ийн `modules/<id>/frontend/` дотор npm
  workspace багц (`@gerege/mod-gov`): pages, components, BFF handlers,
  i18n намespace (`gov.*` түлхүүрүүд), nav entries.
- Апп талд `modules.config.ts` (генерацитай) — суулгасан модулиудын UI-г
  import хийж `app/(modules)/…` руу залгана; BFF route-ууд нь модулийн
  фабрикаас үүснэ (одоогийн 80+ бараг ижил route.ts файлын оронд).
- **Runtime нуулт:** `/api/platform/modules` (public, нэвтэрсэн хэрэглэгчид)
  идэвхтэй модулиудыг буцаана; nav, dashboard плитка, command palette
  бүгд үүнээс render хийнэ. Disable хийсэн модулийн BFF route 404.
- Mobile (SwiftUI/Compose) ба desktop клиентүүд мөн `/api/platform/modules`-ээс
  feature flag уншиж дэлгэцээ нуана/харуулна — native код build-ээ дагана,
  гэхдээ идэвхгүй модулийн таб дарагдахгүй.
- i18n: толь модуль бүрээр namespace-лагдана; parity тест модуль дотроо
  ажиллана (одоогийн глобал parity тестийн залгамж).

### 2.7 Update — систем өөрөө мэдэрч, шинэчлээд, буцаад асна

Шинэ **`platformd` supervisor** (жижиг Go daemon, VPS дээр compose-ийн
хажууд; дараа нь k8s operator болгож өргөтгөж болно):

1. **Мэдрэх:** registry-ийн release feed-ийг (RSS/OCI tag) интервалаар
   шалгана. Суваг: `stable` / `beta` / `pinned`. Модуль тус бүр + core
   тус бүрдээ сувагтай.
2. **Шийдэх:** semver дүрэм — patch = авто, minor = авто (тохиргоогоор),
   major = admin баталгаажуулалт шаардана. Maintenance цонх тохируулж
   болно (жишээ: 03:00–05:00 ULAT).
3. **Шинэчлэх:** §2.5-ын blue-green урсгалаар: татах → checksum + cosign
   гарын үсэг шалгах → build/pull → шинэ instance асаах → migration →
   health + smoke (авто) → traffic switch.
4. **Буцаах:** health/smoke fail → автомат rollback (хуучин image + DB
   migration down эсвэл expand-contract тул down шаардлагагүй байх нь
   зорилт), incident бичлэг audit-д, admin-д мэдэгдэл.
5. **Мэдээлэх:** admin UI "Модулиуд" хуудсанд: одоогийн/шинэ версия,
   changelog, update түүх, rollback товч.

Аюулгүй байдал: багц бүр sha256 checksum + sigstore/cosign гарын үсэгтэй;
platformd зөвхөн гарын үсэгтэй багц ажиллуулна. AI guardrail давхарга,
RLS boot guard, security headers зэрэг kernel-ийн хатуу цөм модулиар
дарж бичигдэхгүй (kernel API-д ил гаргахгүй).

---

## 3. Модулийн ангилал (бүрэн жагсаалт)

### Kernel (модуль биш — framework)

`pkg/logger`, `pkg/observability`, `pkg/jwt`, `pkg/validators`,
`pkg/crypto`, `pkg/clock`, `pkg/helpers`, `pkg/secrethash`, `pkg/recovery`,
`core/apperror`, `core/config`(→намespace-лагдана), `core/datasources/drivers`,
`caches`, `rls`, `migration`(→v2), http host + middlewares + response
helpers, swagger host.

### Core модулиуд (үргэлж суусан; disable боломжгүй эсвэл хязгаартай)

| Модуль | Одоогийн эх сурвалж | Тайлбар |
|---|---|---|
| `auth` | usecases/auth, sso, ssotoken, oidc(consumer тал), handlers auth | eID QR/push/poll, Google OAuth, dgov SSO consumer, session/JWT rotation, deny-list |
| `users` | usecases/users + eidprofile | профайл, eID PKI профайл (`/me/eid/*`) |
| `rbac` | usecases/rbac | динамик role/permission + модулийн permission sync |
| `org` | usecases/org | байгууллага, гишүүнчлэл, Verify/XYP lookup |
| `audit` | usecases/audit, security | hash-chain audit + security events |
| `superadmin` | superadmin + superadmin_onboarding + MFA/TOTP | |
| `site` | site, theme, language | харагдац, theme, динамик хэл (Gemini орчуулга нь `ai` optional dep) |
| `assets` | usecases/assets | гарын үсэг/тамгын asset |
| `platform` | ШИНЭ | module registry, lifecycle, feature API, update оркестрація |

### Business модулиуд (суулгаж/устгаж болно)

| Модуль | Одоогийн эх сурвалж | Depends |
|---|---|---|
| `gov` | usecases/gov (портал: каталог, хүсэлт, лавлагаа, мэдэгдэл, төлбөр, цаг) | auth, users, rbac, org |
| `ai` | usecases/ai + pkg/gemini (чат, STT, TTS, орчуулга, pgvector KB) | auth; tools-оо бусад модулиас цуглуулна |
| `sign` | usecases/sign + pdfsign (PAdES) | auth, users, assets |
| `relay` | usecases/relay + provider/signrelay | sign, gateway |
| `integrations` | usecases/integrations (Drive/Meet/Dropbox, AES-GCM токен) | auth |
| `gspace` | usecases/gspace + pkg/gspace (SFTP) | auth |
| `gateway-console` | usecases/gateway (удирдлага+телеметр+ирээдүйн proxy) | auth, rbac |
| `registry` | usecases/registry + catalog (үйлчилгээний бүртгэл, evidences, once-only) | auth, rbac |
| `provider` | usecases/provider + oidc issuer + Hydra урд + devapps/adminapi/adminkeys | auth |
| `applications` | usecases/applications (OAuth client апп) | provider |
| `core-find` | usecases/core (`/core/*` lookup wrap) | users, org |
| `eidproxy` | route_eidproxy + pkg/ssoeidproxy | auth, gateway-console |

*(Нэр, бүлэглэлийг хэрэгжилтийн үед нарийвчилж болно — гол зарчим:
хүснэгтэд байгаа бүх юм ЯГ НЭГ модульд эзэнтэй болно.)*

---

## 4. Үе шатууд (incremental — big-bang БИШ)

Бүх шат "ногоон CI, ажиллаж буй open.gerege.mn" төлөвтэй дуусна.
Strangler-fig: хуучин зам ажиллаж байх зуур шинэ суурь зэрэгцэн орж ирнэ.

### Phase 0 — Хамгаалалтын тор (1–2 долоо хоног)

- API golden/contract тест: одоогийн бүх endpoint-ийн жагсаалт + статус
  матрицыг snapshot болгож CI-д тогтооно (authz-matrix тестийг өргөтгөнө).
- `routes_authz_matrix_test`-ийг модуль бүрчлэн хуваахад бэлдэж тэмдэглэнэ.
- Feature inventory (§9-ийн хүснэгт)-ийг тестээр баталгаажуулна:
  route pattern бүр ирээдүйн модуль ID-тай map-лагдсан байх ёстой.
- `golangci-lint`-ийг CI-д буцаах + `depguard`/`importas` дүрэм бэлдэх
  (дараа нь модулийн import хилийг мөрдүүлэх суурь).

### Phase 1 — Kernel extraction + Module interface (2–3 долоо хоног)

- `kernel/` мод үүсгэж `pkg/*`, drivers, config, apperror-ийг нүүлгэнэ
  (alias package үлдээж хуучин import замуудыг deprecate хийнэ).
- `kernel/module`: `Module`, `Manifest`, registry (эхэндээ зөвхөн
  in-memory, бүгд enabled).
- **server.go задлах:** модуль бүрд `modules/<id>/module.go` үүсгэж өөрийн
  repo→usecase→route wiring-ийг нүүлгэнэ. `NewApp()` нь модулиудыг
  жагсаалтаар register хийдэг нимгэн host болно. Хуучин `NewApp()` гадаад
  сигнатур хэвээр (флот эвдрэхгүй).
- Route-уудыг `routes` God-package-аас модуль руу нүүлгэнэ.
- Config namespacing: модуль бүр өөрийн config struct-ээ манифестийн
  prefix-ээр уншина.
- **Гарц:** server.go < 150 мөр; модуль бүр bounded, CI ногоон, API
  өөрчлөлтгүй (golden тест нотолно).

### Phase 2 — Migration engine v2 + DB schema хил (2 долоо хоног)

- Per-module migration runner (модулийн fs.FS + өөрийн version хүснэгт).
- 94 migration-ийг модуль бүрийн baseline болгож дахин зохион байгуулна;
  ажиллаж буй DB-д зориулсан нэг удаагийн re-baseline migration
  (`SET SCHEMA` нүүлгэлт) + testcontainers-т хуучин→шинэ upgrade тест.
- RBAC permission sync: `HasPermissions` hook → boot үед идempotent sync.
- **Гарц:** шинэ суулгац цэвэр baseline-аас босдог; хуучин DB алдагдалгүй
  шилждэг нь integration тестээр нотлогдсон.

### Phase 3 — Lifecycle: registry, enable/disable, install/uninstall (3 долоо хоног)

- `platform_modules` хүснэгт + `platform` core модуль + admin UI хуудас.
- Route gate middleware (disable → 404), nav/feature API
  (`/api/platform/modules`).
- `gerege` CLI v1: `mod list/add/remove/enable/disable`; `modules_gen.go`
  генераци; локал build + compose blue-green скрипт.
- Marketplace repo формат (`index.yaml` + семвер таг) + checksum/cosign.
- Uninstall урсгал: disable → data policy (archive) → генерациас хасах →
  rebuild. Мөн `OnUninstall` hook.
- **Гарц:** demo — `gerege mod remove gspace && gerege mod add gspace@…`
  бүрэн circle, өгөгдөл archive/restore-той.

### Phase 4 — Frontend модульчлал (3 долоо хоног)

- npm workspaces: `modules/<id>/frontend` багцууд; `@gerege/ui-core`-ийн
  дээр модулийн UI convention (`registerModuleUI()`).
- BFF route фабрик (одоогийн 80+ бараг ижил route.ts-ийг халана) +
  per-module proxy allowlist; `checkOrigin`/CSRF хэвээр.
- Nav/dashboard/command-palette-ийг registry-driven болгох; i18n
  namespace хуваалт + parity тест модуль дотор.
- Mobile/desktop: feature flag client (модуль идэвхгүй → таб нуух).
- **Гарц:** модуль disable хийхэд UI-ээс бүрэн алга болдог, build дахин
  хийхгүйгээр.

### Phase 5 — platformd updater + gateway enforcement (3–4 долоо хоног)

- `platformd` daemon: release feed watch, суваг/цонх, blue-green,
  авто-rollback, admin мэдэгдэл (§2.7).
- Gateway-г бодит reverse-proxy болгох (ROADMAP ажил) + external модулийн
  бүртгэл (`--external` зам), consumer түвшний rate-limit enforcement.
- Migration бодлогыг **expand–contract** болгож баримтжуулна (rollback-д
  down migration шаардлагагүй байлгах).
- **Гарц:** тест орчинд минор update автоматаар орж, эвдэрхий release
  автоматаар буцдаг demo.

### Phase 6 — Флотын шилжилт + v2.0 release (үргэлжилдэг)

- `open-gerege-core v2.0.0`: Module API stable; v1 фасад (`NewApp`,
  `WalletProvisioner` г.м.) deprecated боловч 2–3 minor release ажиллана.
- MIGRATION_GUIDE (EN/MN/ZH/RU) + template-gerege-mn, template-dgov-mn-ийг
  эхэлж шилжүүлж, wallet hook-ийг extension point болгож албажуулна
  (`auth.LoginHook` interface).
- docs-site-д "Модуль хөгжүүлэх гарын авлага" (add-a-module walkthrough —
  одоогийн add-a-feature-ийн залгамж).

**Нийт баримжаа:** ~3.5–4 сар (нэг үндсэн хөгжүүлэгч + Claude туслалцаа
гэсэн одоогийн хурдаар); Phase 0–2 нь хамгийн өндөр өгөөжтэй тул эхний
сард багтаана.

---

## 5. Юуг ЗОРИУД хийхгүй вэ (anti-patterns)

- **Go `plugin` (.so) / runtime code loading** — cross-compile, версийн
  эмзэглэлээс болж production-д найдваргүй. Хийхгүй.
- **Uninstall үед автомат DROP** — хэзээ ч. Archive-first.
- **AI guardrail, RLS, security headers-ийг модульд тохируулагдахуйц
  болгох** — kernel-ийн хатуу цөм хэвээр (одоогийн CLAUDE.md-ийн зарчим).
- **Microservices руу бөөнөөр задлах** — одоогийн багийн хэмжээнд modular
  monolith нь зөв; external container зам нь хэрэгтэй үед нь байгаа.
- **ORM оруулах** — гар SQL + pgx зарчим модуль дотор хэвээр.
- **Нэг мөчид бүх юмыг rewrite** — үе шат бүр deploy-логдож байх ёстой.

## 6. Эрсдэл ба хамгаалалт

| Эрсдэл | Магадлал | Хамгаалалт |
|---|---|---|
| Re-baseline migration ажиллаж буй DB эвдэх | Дунд | Testcontainers-т бодит dump дээр upgrade тест; production-д snapshot + rollback runbook; `SET SCHEMA` нь өгөгдөл хөдөлгөдөггүй |
| server.go задлахад далд дараалал/side-effect алдагдах | Өндөр | Phase 0 golden тест; модуль бүрийг нэг нэгээр нь нүүлгэж commit бүрд CI |
| Downstream флот эвдрэх | Дунд | v1 фасад хадгалах; template-gerege-mn-ийг canary болгож эхэлж шилжүүлэх |
| Blue-green нь нэг VPS дээр нөөц шаардах | Дунд | Хоёр контейнер зэрэг ~2× RAM богино хугацаанд; swap headroom шалгах, эсвэл rolling-in-place fallback |
| Frontend workspace болгоход build цаг өсөх | Бага | Turborepo/Next cache; модуль тус бүрийн lint scope |
| Update автоматжуулалт өөрөө эвдрэх | Дунд | platformd нь платформоос тусдаа, өөрийгөө биш зөвхөн платформыг update хийнэ; kill-switch env |

## 7. Амжилтын шалгуур (Definition of Done)

1. `gerege mod remove <business-модуль>` → систем ажиллаж, UI/nav/route/
   permission/job бүгд алга болж, өгөгдөл archive-лагдсан байна.
2. `gerege mod add <модуль>@vX` → migration, permission, nav автоматаар
   орж ирнэ; нэг ч гар wiring алхам байхгүй.
3. Minor update: platformd мэдэрч, шөнийн цонхонд шинэчилж, health OK үед
   traffic шилжсэн байна; эвдэрхий release авто-rollback болсон түүх
   audit-д бичигдэнэ.
4. §9-ийн бүх чадвар шинэ бүтцэд ажиллана (golden + authz matrix ногоон).
5. Шинэ business модулийг docs-site-ийн гарын авлагаар core-д гар
   оролцоогүй, тусдаа repo-оос хөгжүүлж суулгаж болно.
6. server.go < 150 мөр; `routes`, глобал `config.AppConfig`, глобал
   migration дараалал гэсэн 3 God-объект устсан.

## 8. Дэлхийн жишигтэй харьцуулал (яагаад энэ загвар)

- **Spring Modulith / Shopify modular monolith** — модулийн хил нь
  package + тест enforced, deploy нэг unit: бидний kernel/core/business.
- **VS Code / Backstage** — manifest + contribution points (nav, tools,
  jobs): бидний `Has*` hooks.
- **Grafana** — in-process + external plugin hybrid: бидний §2.5 A/B зам.
- **Kubernetes operator / Talos** — өөрийгөө update хийдэг, суваг +
  авто-rollback: бидний platformd.
- **OpenTelemetry/12-factor** — config namespacing, ил health, per-module
  observability хэвээр гүнзгийрнэ.

---

## 9. Чадвар алдагдахгүйн баталгаа — бүрэн зураглал

Одоогийн README/ROADMAP-ийн чадвар бүр → шинэ байршил:

| Одоогийн чадвар | Шинэ модуль |
|---|---|
| eID нэвтрэлт (QR `/eid/start`, РД push `/eid/start-id`, long-poll `/eid/poll`) | core: `auth` |
| Google OAuth холболт/салгалт, түүгээр нэвтрэх | core: `auth` |
| dgov SSO consumer (start/callback/native PKCE/logout) | core: `auth` |
| JWT access+refresh rotation, logout deny-list, `kind` guard | core: `auth` |
| eID PKI профайл (`/me/*`, `/users/me/eid/*`) | core: `users` |
| Байгууллага/гишүүнчлэл + Verify/XYP lookup + RLS | core: `org` |
| RBAC динамик role/permission, 4-үүрэгт загвар | core: `rbac` |
| Superadmin удирдлага + onboarding + MFA/TOTP | core: `superadmin` |
| Audit hash-chain (`/audit`, `/audit/verify`) + security events | core: `audit` |
| Сайтын харагдац, themes, динамик хэл (`/admin/languages`) | core: `site` |
| Гарын үсэг/тамгын asset (`/assets/*`) | core: `assets` |
| Төрийн үйлчилгээний портал (`/gov/*` бүхэлдээ, officer queue хамт) | business: `gov` |
| AI: чат, voice, STT, TTS, live орчуулга, pgvector KB, admin prompts, public AI (landing чат `/public/ai/*`, degraded fallback) | business: `ai` |
| PAdES гарын үсэг + Document-Signer + sign-relay (`/rp/sign/*`) | business: `sign`, `relay` |
| API gateway удирдлага/телеметр (+ирээдүйн enforcement) | business: `gateway-console` |
| Registry (services/evidences/life-events/once-only) + catalog | business: `registry` |
| OIDC provider (Hydra урд, `/provider/*`, `/oauth` UI, devapps) | business: `provider`, `applications` |
| Интеграци (Drive/Meet/Dropbox, AES-GCM) | business: `integrations` |
| Gerege Space SFTP (`/gspace/*`) | business: `gspace` |
| Core find (`/core/*`) | business: `core-find` |
| eID proxy (`/eidproxy/*`) | business: `eidproxy` |
| Wallet hook (`WalletProvisioner`) | kernel extension point: `auth.LoginHook` |
| PWA, BFF CSRF/cookie загвар, security headers, rate limits | kernel + модулийн manifest-д rate-limit тодорхойлолт |
| Observability (OTel/Prometheus/Zap), swagger | kernel (per-module label нэмэгдэнэ) |
| Mobile/desktop native клиентүүд | өөрчлөгдөхгүй + feature-flag API нэмэгдэнэ |
| Testcontainers integration, authz matrix, i18n parity тестүүд | модуль бүрд хуваагдаж бүгд хадгалагдана |

---

**Дараагийн алхам (санал):** Phase 0-ийг шууд эхлүүлье — golden route
snapshot тест + feature inventory тест хоёрыг core repo-д нэмэх нь
хамгийн бага эрсдэлтэй, refactor бүхэлдээ түүн дээр тулгуурлана.

*Gerege Template Platform — Modular Refactor Plan v1.0 · 2026-08-04*
