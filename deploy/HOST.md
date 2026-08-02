# open.gerege.mn — байршуулалтын тэмдэглэл

Нээлттэй суурь template-ийн амьд жишиг байршуулалт.

| | |
|---|---|
| Домэйн | <https://open.gerege.mn> |
| Хост | `66.181.175.199` (`grg`, дотоод `10.0.0.31`) — нэгдсэн Gerege хост |
| Хэрэглэгч / зам | `grgdev` : `/home/grgdev/open-gerege-mn` |
| Compose project | `public-template` (⚠️ зориуд хуучин нэрээрээ — доор үз) |
| Портууд | web `3010`, api relay `8094` |
| DB | `public_template` (тусдаа volume `public-template_dbdata`) |
| Цөм | [`open-gerege-core`](https://github.com/gerege-systems/open-gerege-core) — **нээлттэй**, token шаардахгүй |

`template.gerege.mn` (хаалттай хувилбар) нь **өөр стек** — ижил хост дээр
`temp-gerege-mn` project нэрээр тусдаа ажиллана. Хоёулаа бие биедээ
нөлөөлөхгүй.

### Compose project яагаад `public-template` хэвээрээ вэ

Домэйн `open.gerege.mn` болсон ч compose project нэр, контейнерийн нэр,
volume-ууд **зориуд** хуучнаараа үлдсэн. Учир нь өгөгдлийн сангийн volume нь
project нэрээр угсардаг (`public-template_dbdata`) — project-ыг `open-gerege-mn`
болговол compose нь ХООСОН шинэ volume үүсгэж, амьд өгөгдөл орхигдоно.

Project нэр нь зөвхөн дотоод (хостын untracked `.env`-ийн
`COMPOSE_PROJECT_NAME`); гаднаас юу ч үүнийг харахгүй. Хэрэв хожим цэгцлэх бол
volume-ыг гараар нүүлгэх шаардлагатай — тусдаа, төлөвлөсөн ажил байх ёстой.

## Хостын онцлог тохиргоо (git-д БАЙХГҮЙ)

Хост дээр `docker-compose.override.yml` байдаг — CI-ийн `git reset --hard`-д
амьд үлдэхийн тулд зориудаар untracked:

- `web`-д `container_name: public-template-web` өгч, хуваалцсан `gerege` edge
  сүлжээнд холбоно (edge nginx үүгээр танина).
- `BACKEND_URL`-ийг `http://public-template-api-1:8080` руу **pin** хийнэ.
  Үүнгүйгээр хуваалцсан сүлжээн дэх өөр `api` руу очиж бүх `/api/v1/*` 404 болно.

## SSO client (`backend.env`, git-д БАЙХГҮЙ)

Энэ байршуулалт нь `sso.gerege.mn`-ий **өөрийн** OAuth2 client-ийг хэрэглэнэ —
хаалттай `template.gerege.mn`-ийнхийг ЗЭЭЛЖ БОЛОХГҮЙ (redirect_uri таарахгүй):

| Түлхүүр | Утга |
|---|---|
| `SSO_ISSUER` | `https://sso.gerege.mn` |
| `SSO_CLIENT_ID` | `open-gerege-mn` |
| `SSO_CLIENT_SECRET` | (нууц — зөвхөн хостын `backend.env`) |
| `SSO_SCOPE` | `openid profile email nationalid` |
| `SSO_REDIRECT_URI` | `https://open.gerege.mn/sso/callback` |

⚠️ `SSO_REDIRECT_URI`-ийн зам нь **`/sso/callback`** — BFF-ийн бодит route
(`frontend/src/app/sso/callback/route.ts`). `/api/auth/sso/callback` гэсэн
route БАЙХГҮЙ (`/api/auth/sso/` дор зөвхөн `start` ба `native` байна), тиймээс
тэр замыг бичвэл нэвтрэлт `?error=sso`-оор унана.

Шалгах (нэвтрэхгүйгээр):

```bash
curl -sS -o /dev/null -w '%{redirect_url}\n' \
  https://open.gerege.mn/api/auth/sso/start
# → https://sso.gerege.mn/oauth2/auth?client_id=open-gerege-mn&…&redirect_uri=…%2Fsso%2Fcallback
```

`backend.env` нь uid `65532` (distroless nonroot)-ийн эзэмшилтэй тул `grgdev`
шууд уншиж/бичиж чадахгүй — контейнерээр дамжина:

```bash
docker run --rm -i -v "$PWD:/w" busybox sh -c 'grep ^SSO_ /w/backend.env'
```

## Edge nginx

vhost: `open.gerege.mn.conf` — edge контейнерийн `conf.d`
(`/home/deploy/sso-gerege-mn/newsrv-nginx/conf.d`) дотор. Rate-limit zone-ууд
нь `ptpl_auth` / `ptpl_app` (амьд `template.gerege.mn`-ий `tpl_*`-тай
зөрчилдөхгүйн тулд өөр нэртэй).

TLS: Let's Encrypt, `certbot/certbot` webroot аргаар
(`gerege-sso-eid_certbot_certs` / `_www` volume-ууд).

## ⚠️ Анхны суулгалтын алхмууд (`docker compose up` дангаараа хангалтгүй)

Шинэ DB volume дээр дараах зүйлс **гараар** шаардлагатай байв:

1. **Extension-ууд** — `uuid-ossp`, `pgcrypto`, `vector`, `citext`-ийг
   `postgres` эрхээр урьдчилан үүсгэнэ. Migration нь эдгээрийг үүсгэх гэж
   оролддог боловч `app_user`-т superuser эрх байхгүй.
2. **`DB_POSTGRE_DSN` нь `postgres` (superuser) байх ёстой** — migration DDL
   ажиллуулдаг. Ажиллах үеийн холболт нь compose-оос `app_user` авдаг тул
   аюулгүй байдал алдагдахгүй.

Хэрэв `schema public`-ыг дахин үүсгэвэл init скриптийн олгосон эрхүүд
устана — тэр үед дараахыг сэргээнэ:

```sql
GRANT USAGE ON SCHEMA public TO app_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO app_user;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO app_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO app_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT USAGE, SELECT ON SEQUENCES TO app_user;
```

## CI/CD

`main` руу push хийхэд `ci.yml`-ийн `deploy` ажил SSH-ээр орж
`deploy/deploy.sh` ажиллуулна. Шаардлагатай repo secret:
`DEPLOY_HOST` · `DEPLOY_USER` · `DEPLOY_PATH` · `DEPLOY_SSH_KEY`.

Deploy түлхүүр нь `grgdev`-ийн `authorized_keys`-д бүртгэлтэй, зөвхөн энэ
репогийн CI-д зориулсан (оператортой хуваалцаагүй).
