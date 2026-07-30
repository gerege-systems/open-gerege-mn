# Déploiement

Déployez la plateforme sur un seul VPS avec **Docker Compose + nginx**. La pile
se compose de PostgreSQL + Redis + l'API Go (également émetteur OIDC) + le BFF
Next.js.

## Prérequis

- Docker et le plugin compose
- nginx et certbot (TLS)
- Un enregistrement DNS pointant vers le serveur

## Topologie

```
Internet ──► nginx (80/443, Let's Encrypt)
   ├─ /oauth2/*, /.well-known/*, /userinfo ─► api (émetteur OIDC)
   ├─ /rp/sign/*      ─► relais api
   ├─ /rp/eid/*, /rp/eid-org/* ─► api (proxy eID)
   └─ tout le reste    ─► web (BFF Next.js) ──► api
   interne : db (Postgres 16) · redis (7)
```

## Fichiers d'environnement (ignorés par git)

- **`.env`** — interpolation compose (secrets Postgres/Redis, ports, domaine).
- **`backend.env`** — configuration de l'API (JWT_SECRET, EID_RP_*, OAUTH_ISSUER,
  SSO_*, …).

!!! warning "Des secrets distincts"
    Chaque déploiement doit avoir ses propres `JWT_SECRET`, `SSO_STATE_KEY` et
    identifiants de partie utilisatrice — jamais partagés entre déploiements.

## Étapes de déploiement

```bash
# 1) récupérer le code
git clone git@github.com:gerege-systems/sso-dgov-mn.git /srv/sso-dgov-mn
cd /srv/sso-dgov-mn

# 2) créer les fichiers d'environnement (.env + backend.env)

# 3) démarrer la pile — migrate applique le schéma automatiquement
docker compose up -d --build

# ou redéployer :
bash deploy/deploy.sh
```

## nginx (exemple)

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

## Nom de projet compose

Vous pouvez faire tourner plusieurs déploiements côte à côte sur un même
serveur. Chacun doit avoir ses propres `COMPOSE_PROJECT_NAME`, ports et volumes
dans son `.env` — sinon les étiquettes d'images et les volumes entrent en
collision.

| Déploiement | Domaine | Ports (exemple) |
|---|---|---|
| `sso-dgov-mn` | sso.gerege.mn | web 3008 |
| `template-dgov-mn` | template.gerege.mn | web 3009 |
