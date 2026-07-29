# Deployment

Deploy the platform to a single VPS with **Docker Compose + nginx**. The stack is
PostgreSQL + Redis + Go API (also the OIDC issuer) + Next.js BFF.

## Prerequisites

- Docker + the compose plugin
- nginx + certbot (TLS)
- A DNS record pointing at the server

## Topology

```
Internet ──► nginx (80/443, Let's Encrypt)
   ├─ /oauth2/*, /.well-known/*, /userinfo ─► api (OIDC issuer)
   ├─ /rp/sign/*      ─► api relay
   ├─ /rp/eid/*, /rp/eid-org/* ─► api (eID proxy)
   └─ everything else  ─► web (Next.js BFF) ──► api
   internal: db (Postgres 16) · redis (7)
```

## Env files (gitignored)

- **`.env`** — compose interpolation (Postgres/Redis secrets, ports, domain).
- **`backend.env`** — API config (JWT_SECRET, EID_RP_*, OAUTH_ISSUER, SSO_*, …).

!!! warning "Separate secrets"
    Every deployment must have its own `JWT_SECRET`, `SSO_STATE_KEY` and RP
    credentials — never shared across deployments.

## Deploy steps

```bash
# 1) get the code
git clone git@github.com:gerege-systems/public-gerege-template.git /srv/public-gerege-template
cd /srv/public-gerege-template

# 2) create the env files (.env + backend.env)

# 3) bring the stack up — migrate applies the schema automatically
docker compose up -d --build

# or re-deploy:
bash deploy/deploy.sh
```

## nginx (example)

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

## Compose project name

You can run several deployments side by side on one server. Each must have its own
`COMPOSE_PROJECT_NAME`, ports and volumes in its `.env` — otherwise image tags /
volumes collide.

| Deployment | Domain | Ports (example) |
|---|---|---|
| `sso-dgov-mn` | sso.gerege.mn | web 3008 |
| `template-dgov-mn` | template.gerege.mn | web 3009 |
| `public-template` | public.template.gerege.mn | web 3010, api relay 8094 |

The reference deployment of this repository is `public-template`; host-level notes
(edge nginx, SSO client, first-install steps) live in `deploy/HOST.md`.

## Documentation site

This site is built from `docs-site/` with
[MkDocs Material](https://squidfunk.github.io/mkdocs-material/) and published at:

<https://gerege-systems.github.io/public-gerege-template/>

- Every push to `main` that touches `docs-site/**` makes
  `.github/workflows/docs.yml` build and publish to **GitHub Pages** (Pages
  source = GitHub Actions).
- Pull requests only run `mkdocs build --strict` — it turns broken internal links
  and missing nav entries into errors. No deploy.
- Languages: Mongolian at the root, the rest behind a prefix — `/en/`, `/ru/`,
  `/zh/`. Keep that list in sync with `docsLangs` in
  `frontend/src/brand.config.ts` (the “Documentation” item in the user menu
  builds its URL from it).

Check it locally:

```bash
cd docs-site
python3 -m venv .venv && .venv/bin/pip install -r requirements.txt
.venv/bin/mkdocs serve        # http://127.0.0.1:8000
.venv/bin/mkdocs build --strict
```

To host it yourself, `docs-site/deploy-docs.sh` builds and copies the site to
`DOCS_SERVER`:`DOCS_TARGET`.
