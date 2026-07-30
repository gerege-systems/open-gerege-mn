# النشر

انشر المنصّة على خادم افتراضي واحد باستخدام **Docker Compose + nginx**. تتألّف
الحزمة من PostgreSQL + Redis + واجهة Go الخلفية (وهي أيضًا مُصدِر OIDC) + واجهة
Next.js بنمط BFF.

## المتطلّبات المسبقة

- Docker وملحق compose
- nginx وcertbot (لشهادات TLS)
- سجلّ DNS يشير إلى الخادم

## الطوبولوجيا

```
الإنترنت ──► nginx (80/443، Let's Encrypt)
   ├─ /oauth2/*, /.well-known/*, /userinfo ─► api (مُصدِر OIDC)
   ├─ /rp/sign/*      ─► مرحِّل api
   ├─ /rp/eid/*, /rp/eid-org/* ─► api (وكيل eID)
   └─ كلّ ما عدا ذلك   ─► web (BFF بـ Next.js) ──► api
   داخليًّا: db (Postgres 16) · redis (7)
```

## ملفّات البيئة (مستثناة من git)

- **`.env`** — استبدال قيم compose (أسرار Postgres/Redis، والمنافذ، والنطاق).
- **`backend.env`** — إعدادات الواجهة الخلفية (JWT_SECRET، وEID_RP_*،
  وOAUTH_ISSUER، وSSO_*، …).

!!! warning "أسرار منفصلة"
    يجب أن يكون لكلّ عملية نشر `JWT_SECRET` و`SSO_STATE_KEY` وبيانات اعتماد طرف
    معتمِد خاصّة بها — ولا تُشارَك بين عمليات النشر أبدًا.

## خطوات النشر

```bash
# 1) إحضار الشيفرة
git clone git@github.com:gerege-systems/sso-dgov-mn.git /srv/sso-dgov-mn
cd /srv/sso-dgov-mn

# 2) إنشاء ملفّي البيئة (.env و backend.env)

# 3) تشغيل الحزمة — يطبّق migrate المخطّط تلقائيًّا
docker compose up -d --build

# أو إعادة النشر:
bash deploy/deploy.sh
```

## nginx (مثال)

```nginx
server {
    server_name sso.gerege.mn;
    client_max_body_size 30m;

    location /oauth2/                           { proxy_pass http://127.0.0.1:4446; include /etc/nginx/proxy_params; }
    location = /.well-known/openid-configuration { proxy_pass http://127.0.0.1:4446; include /etc/nginx/proxy_params; }
    location = /.well-known/jwks.json            { proxy_pass http://127.0.0.1:4446; include /etc/nginx/proxy_params; }
    location = /userinfo                         { proxy_pass http://127.0.0.1:4446; include /etc/nginx/proxy_params; }

    location /rp/sign/    { proxy_pass http://127.0.0.1:8081/rp/sign/; include /etc/nginx/proxy_params; }
    location /rp/eid/     { proxy_pass http://127.0.0.1:8081/api/v1/eid/;     include /etc/nginx/proxy_params; }
    location /rp/eid-org/ { proxy_pass http://127.0.0.1:8081/api/v1/eid-org/; include /etc/nginx/proxy_params; }

    location / { proxy_pass http://127.0.0.1:3008; include /etc/nginx/proxy_params; }
    listen 443 ssl;  # certbot managed
}
```

## اسم مشروع compose

يمكنك تشغيل عدّة عمليات نشر جنبًا إلى جنب على خادم واحد. ويجب أن يكون لكلّ منها
`COMPOSE_PROJECT_NAME` ومنافذ ووحدات تخزين خاصّة في ملفّ `.env` الخاصّ بها —
وإلّا تتضارب وسوم الصور ووحدات التخزين.

| النشر | النطاق | المنافذ (مثال) |
|---|---|---|
| `sso-dgov-mn` | sso.gerege.mn | web 3008 |
| `template-dgov-mn` | template.gerege.mn | web 3009 |
