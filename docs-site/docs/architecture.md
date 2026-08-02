# Архитектур

Платформ нь **Clean Architecture** зарчмаар бүтээгдсэн: `handler → usecase →
repository → domain`. Business core нь web framework-ийг import хийдэггүй.

## Бүрэлдэхүүн

```
Internet ──► nginx (TLS)
   │
   ├─ /oauth2/*, /.well-known/*, /userinfo ─► Go API — өөрийн OIDC issuer
   ├─ /rp/sign/*   ─► eID sign relay (backend)
   ├─ /rp/eid/*     ─► eID service proxy — хувь хүн (backend)
   ├─ /rp/eid-org/* ─► eID service proxy — байгууллага (backend)
   └─ бусад бүх       ─► Next.js BFF (web) ──► backend API (:8080)
                                                   │
   internal network:  db (PostgreSQL) · redis
```

## Давхаргууд

| Давхарга | Технологи | Тайлбар |
|---|---|---|
| **Backend** | Go · chi (net/http) · pgx (ORM-гүй) | Clean Architecture, RLS, hand-written SQL |
| **Frontend** | Next.js 16 (BFF) + `@gerege/ui-core` | Браузер зөвхөн ижил-origin route-той харилцана; токен client JS-д гардаггүй |
| **OIDC provider** | Өөрийн Go код (usecases/oidc) | login/consent/logout урсгалыг платформ өөрөө жолоодоно |
| **Identity** | eID Mongolia RP | Цахим үнэмлэхээр баталгаажуулалт |
| **Cache/queue** | Redis | session deny-list, transient state |
| **AI** | Gemini (SDK-гүй REST) | чат, дуу хоолой, орчуулга |

## Аюулгүй байдал

- **Row-Level Security (RLS)** — хэрэглэгч бүр зөвхөн өөрийн мөрийг хардаг; boot-үеийн
  мөрдөлтийн guard (production-д non-superuser role шаардана).
- **BFF загвар** — токен httpOnly cookie-д, браузерийн JS-д хэзээ ч гардаггүй.
- **Давхар CSRF** — custom header + origin шалгалт.
- **Security headers** — CSP, HSTS, COOP/COEP/CORP; per-IP rate limiting.
- **Аудит** — hash-chain холбоост, зөвхөн-нэмэх бүртгэл.

## Backend бүтэц — цөмөөс ирдэг

Дээрх бүх чадвар (танилт, RBAC, gateway, audit, OIDC provider, eID/SSO, AI) нь
**энэ репод бичигдээгүй** — `open-gerege-core` Go модулиас `go.mod`-оор ирнэ.
Иймд `backend/` дотор ердөө **нэг Go файл** байна:

```
backend/
├── cmd/api/main.go        # ~30 мөр: цөмийг эхлүүлж, өөрийн маршрутаа нэмнэ
├── deploy/                # Dockerfile, db init
└── .env.example           # тохиргооны загвар
```

```go
func main() {
    server.ServiceName = "gerege-template"
    app, err := server.NewApp()          // ← бүх чадвар цөмөөс
    // Аппын өөрийн маршрутыг энд нэмнэ:
    //   app.Router().Route("/api/xxx", xxx.Routes(app.Pool()))
    app.Run()
}
```

Цөм нь **нэг давхар**: **`open-gerege-core`** — төрийн ба Gerege хоёр урсгал
хоёулаа шууд хэрэглэнэ. (2026-08-02 хүртэл дээр нь хаалттай
`private-gerege-core` давхарга байсныг гинжнээс хассан.)

## Frontend бүтэц — `@gerege/ui-core`

Frontend-ийн дийлэнх хэсэг нь **хуваалцсан багц** дотор байна. Апп нь зөвхөн
өөрийн онцлогийг эзэмшинэ — брэнд, landing текст, платформ тусгай хуудсууд.

```
frontend/
├── src/brand.config.ts     # брэндийн ЦОРЫН ГАНЦ эх сурвалж (нэр, домэйн, docsUrl…)
├── src/components/landing/ # аппын өөрийн landing текст
├── src/app/api/**/route.ts # BFF route-ын НЭГ МӨРИЙН бүрхүүл (158 ш)
└── node_modules/@gerege/ui-core
    ├── src/api/**          # BFF route-ын бодит логик
    └── src/components/**   # AppShell, UserMenu, admin/gov/gateway дэлгэцүүд
```

- Багцыг `package.json`-д **tag-аар пинлэнэ**
  (`…/ui-core/archive/refs/tags/v0.4.0.tar.gz`) — шинэчлэлт нь ил, санамсаргүй
  биш.
- Route бүр `export { GET, POST } from '@gerege/ui-core/api/<зам>'` гэсэн бүрхүүл.
  Next.js route-ыг файлын системээр бүртгэдэг тул бүрхүүл заавал хэрэгтэй;
  `npm run check:routes` нь багцад байгаад аппад бүрхүүлгүй route-ыг барина.
- Багц нь аппын `brand.config.ts`-ыг импортлохгүй — утгууд `<UiCoreProvider>`-оор
  (`brandName`, `docsUrl`, `docsLangs`) дамжина. Брэндийн нэрийг өөр файлд шууд
  бичихийг `npm run check:brand` хориглоно.

Хоёр шалгалт хоёулаа `npm run build`-ийн нэг хэсэг тул CI-д мөрдөгдөнө.
