# Архитектура

Платформа следует **Clean Architecture**: `handler → usecase → repository →
domain`. Бизнес-ядро никогда не импортирует веб-фреймворк.

## Компоненты

```
Internet ──► nginx (TLS)
   │
   ├─ /oauth2/*, /.well-known/*, /userinfo ─► Go API — встроенный OIDC issuer
   ├─ /rp/sign/*   ─► ретранслятор подписи eID (бэкенд)
   ├─ /rp/eid/*     ─► прокси сервисов eID — личный (бэкенд)
   ├─ /rp/eid-org/* ─► прокси сервисов eID — организации (бэкенд)
   └─ всё остальное ─► Next.js BFF (web) ──► API бэкенда (:8080)
                                                   │
   внутренняя сеть:  db (PostgreSQL) · redis
```

## Слои

| Слой | Технология | Примечания |
|---|---|---|
| **Бэкенд** | Go · chi (net/http) · pgx (без ORM) | Clean Architecture, RLS, рукописный SQL |
| **Фронтенд** | Next.js 15 (BFF) + `@gerege/ui-core` | Браузер общается только со своим origin; токены не попадают в клиентский JS |
| **Провайдер OIDC** | Встроенный (Go, usecases/oidc) | платформа сама ведёт вход/согласие/выход |
| **Идентификация** | eID Mongolia RP | проверка электронного удостоверения |
| **Кэш/очередь** | Redis | список отозванных сессий, временное состояние |
| **AI** | Gemini (REST без SDK) | чат, голос, перевод |

## Безопасность

- **Row-Level Security (RLS)** — каждый пользователь видит только свои строки;
  проверка применимости при старте (в продакшене требуется роль без прав суперпользователя).
- **Модель BFF** — токены живут в httpOnly-куках и никогда не попадают в JS браузера.
- **Двойная защита от CSRF** — собственный заголовок + проверка origin.
- **Заголовки безопасности** — CSP, HSTS, COOP/COEP/CORP; ограничение запросов по IP.
- **Аудит** — журнал с хеш-цепочкой, только на добавление.

## Структура бэкенда (обзор)

```
backend/
├── cmd/api/server/        # ручная сборка зависимостей (server.go)
├── internal/
│   ├── business/
│   │   ├── domain/         # чистый домен (без внутренних импортов)
│   │   └── usecases/       # бизнес-логика (зависит от интерфейсов)
│   ├── datasources/
│   │   ├── repositories/   # адаптеры pgx + интерфейсы
│   │   └── caches/         # redis
│   └── http/
│       ├── handlers/       # func(w,r) error, v1.Wrap
│       ├── middlewares/    # аутентификация, oauth-bearer, лимиты, …
│       └── routes/         # группировка маршрутов
├── pkg/                    # eid, oidc, secrethash, gemini, …
└── migrations/             # нумерованный SQL (N_name.up/down.sql)
```

## Структура фронтенда — `@gerege/ui-core`

Большая часть фронтенда живёт в **общем пакете**. Приложению принадлежит только
то, что специфично для него: брендинг, тексты landing и особые страницы.

```
frontend/
├── src/brand.config.ts     # единственный источник брендинга (имя, домен, docsUrl…)
├── src/components/landing/ # собственные тексты landing
├── src/app/api/**/route.ts # ОДНОСТРОЧНЫЕ обёртки BFF-маршрутов (158 шт.)
└── node_modules/@gerege/ui-core
    ├── src/api/**          # сама логика BFF-маршрутов
    └── src/components/**   # AppShell, UserMenu, экраны admin/gov/gateway
```

- Пакет **закреплён по тегу** в `package.json`
  (`…/ui-core/archive/refs/tags/v0.4.0.tar.gz`) — обновление всегда явное.
- Каждый маршрут — обёртка: `export { GET, POST } from '@gerege/ui-core/api/<путь>'`.
  Next.js регистрирует маршруты по файловой системе, поэтому обёртка обязательна;
  `npm run check:routes` находит маршруты пакета без обёртки в приложении.
- Пакет никогда не импортирует `brand.config.ts` приложения — значения приходят
  через `<UiCoreProvider>` (`brandName`, `docsUrl`, `docsLangs`). Имя бренда,
  вписанное в любой другой файл, отклоняет `npm run check:brand`.

Обе проверки входят в `npm run build`, поэтому их обеспечивает CI.
