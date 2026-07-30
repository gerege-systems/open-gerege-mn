# Démarrage rapide

> Du clone à une connexion eID sur la pile complète en cinq minutes environ.

## Prérequis

| Outil | Version | Remarque |
|---|---|---|
| Go | 1.26+ | uniquement si vous lancez le backend directement |
| Node.js | 20+ | uniquement si vous lancez le frontend directement |
| Docker + Compose | récent | **recommandé** — toute la pile en une commande |
| PostgreSQL / Redis | 15+ / 7+ | inutile avec Docker |

## 1. Le chemin le plus rapide — Docker Compose

```bash
git clone https://github.com/gerege-systems/public-gerege-template.git
cd public-gerege-template
docker compose up -d --build
```

Cela démarre `db` · `redis` · `migrate` (ponctuel) · `api` · `web`.
Ouvrez ensuite **<http://localhost:3000>**.

!!! note "Les migrations s'exécutent automatiquement"
    Le service `migrate` s'exécute à chaque `up` et ignore les migrations déjà
    appliquées : le relancer est donc sans danger (idempotent).

## 2. Lancement manuel (développement)

=== "Backend"

    ```bash
    cd backend
    cp .env.example .env
    # renseignez JWT_SECRET (≥32 caractères), la base, Redis et vos identifiants EID_*
    go run ./cmd/api          # → http://localhost:8080
    ```

=== "Frontend"

    ```bash
    cd frontend
    cp .env.example .env.local     # BACKEND_URL=http://localhost:8080
    npm install
    npm run dev                    # → http://localhost:3000
    ```

## 3. Se connecter

Choisissez **Se connecter avec eID** sur la page d'accueil, puis empruntez l'un
des trois chemins :

- **QR code** — scannez le QR affiché sur l'ordinateur avec l'application eID.
- **App2App** — passez directement dans l'application eID sur le même téléphone.
- **Numéro de registre** — saisissez-le et une notification arrive dans
  l'application.

La liaison Google n'apparaît qu'une fois ses identifiants configurés.

!!! tip "Essayer sans identifiants eID"
    La connexion ne fonctionnera pas tant que `EID_*` n'est pas renseigné. Si
    vous souhaitez seulement examiner l'interface et l'architecture, les tests
    unitaires du backend (`go test ./...`) parcourent les flux avec un bouchon
    FakeEID.

## 4. Vérifier

```bash
cd backend && go test ./...     # tests unitaires (mocks, rapides)
cd frontend && npm run build    # build + lint + vérification de types (comme la CI)
```

Reproduire localement tous les garde-fous de la CI :

```bash
cd backend && make pre-push     # lint + tests + dérive swag + build
```

## Et ensuite

<div class="grid cards" markdown>

- :material-layers: **[Architecture](architecture.md)** — couches et flux de dépendances
- :material-shield-key: **[Authentification](authentication.md)** — flux eID + SSO
- :material-connection: **[Intégration d'une application](sso-integration.md)** — faire de votre application une RP
- :material-cog: **[Configuration](configuration.md)** — référence des variables d'environnement

</div>
