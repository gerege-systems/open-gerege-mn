# Despliegue

Despliega la plataforma en un único VPS con **Docker Compose + nginx**. La pila
está formada por PostgreSQL + Redis + la API en Go (que además es el emisor
OIDC) + el BFF de Next.js.

## Requisitos previos

- Docker y el complemento compose
- nginx y certbot (TLS)
- Un registro DNS que apunte al servidor

## Topología

```
Internet ──► nginx (80/443, Let's Encrypt)
   ├─ /oauth2/*, /.well-known/*, /userinfo ─► api (emisor OIDC)
   ├─ /rp/sign/*      ─► relé de api
   ├─ /rp/eid/*, /rp/eid-org/* ─► api (proxy eID)
   └─ todo lo demás    ─► web (BFF de Next.js) ──► api
   interna: db (Postgres 16) · redis (7)
```

## Archivos de entorno (ignorados por git)

- **`.env`** — interpolación de compose (secretos de Postgres/Redis, puertos,
  dominio).
- **`backend.env`** — configuración de la API (JWT_SECRET, EID_RP_*,
  OAUTH_ISSUER, SSO_*, …).

!!! warning "Secretos separados"
    Cada despliegue debe tener sus propios `JWT_SECRET`, `SSO_STATE_KEY` y
    credenciales de parte confiante; nunca se comparten entre despliegues.

## Pasos del despliegue

```bash
# 1) obtener el código
git clone git@github.com:gerege-systems/sso-dgov-mn.git /srv/sso-dgov-mn
cd /srv/sso-dgov-mn

# 2) crear los archivos de entorno (.env + backend.env)

# 3) levantar la pila: migrate aplica el esquema automáticamente
docker compose up -d --build

# o volver a desplegar:
bash deploy/deploy.sh
```

## nginx (ejemplo)

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

## Nombre del proyecto de compose

Puedes ejecutar varios despliegues en paralelo en un mismo servidor. Cada uno
debe tener sus propios `COMPOSE_PROJECT_NAME`, puertos y volúmenes en su `.env`;
de lo contrario, las etiquetas de imagen y los volúmenes colisionan.

| Despliegue | Dominio | Puertos (ejemplo) |
|---|---|---|
| `sso-dgov-mn` | sso.gerege.mn | web 3008 |
| `template-dgov-mn` | template.gerege.mn | web 3009 |
