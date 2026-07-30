# Architecture

La plateforme suit la **Clean Architecture** : `handler → usecase → repository →
domain`. Le cœur métier n'importe jamais le framework web.

## Composants

```
Internet ──► nginx (TLS)
   │
   ├─ /oauth2/*, /.well-known/*, /userinfo ─► API Go — émetteur OIDC intégré
   ├─ /rp/sign/*   ─► relais de signature eID (backend)
   ├─ /rp/eid/*     ─► proxy de service eID — personnel (backend)
   ├─ /rp/eid-org/* ─► proxy de service eID — organisations (backend)
   └─ tout le reste ─► BFF Next.js (web) ──► API backend (:8080)
                                                   │
   réseau interne :  db (PostgreSQL) · redis
```

## Couches

| Couche | Technologie | Remarques |
|---|---|---|
| **Backend** | Go · chi (net/http) · pgx (sans ORM) | Clean Architecture, RLS, SQL écrit à la main |
| **Frontend** | Next.js 16 (BFF) | Le navigateur ne parle qu'à des routes de même origine ; les jetons n'atteignent jamais le JS client |
| **Fournisseur OIDC** | Intégré (Go, usecases/oidc) | la plateforme pilote elle-même connexion/consentement/déconnexion |
| **Identité** | Partie utilisatrice eID Mongolia | vérification par identité électronique |
| **Cache/file** | Redis | liste de refus de session, état transitoire |
| **IA** | Gemini (REST sans SDK) | chat, voix, traduction |

## Sécurité

- **Row-Level Security (RLS)** — chaque utilisateur ne voit que ses propres
  lignes ; un garde-fou au démarrage vérifie l'applicabilité (rôle non
  superutilisateur exigé en production).
- **Modèle BFF** — les jetons vivent dans des cookies httpOnly, jamais dans le JS
  du navigateur.
- **Double CSRF** — en-tête personnalisé + contrôle d'origine.
- **En-têtes de sécurité** — CSP, HSTS, COOP/COEP/CORP ; limitation par IP.
- **Audit** — journal chaîné par empreintes, en ajout seul.

## Code partagé — ce qui n'est PAS dans ce dépôt

Aucune des capacités ci-dessus n'est écrite ici. Elles proviennent de deux
couches partagées versionnées, afin qu'aucune plateforme n'ait à répéter une
correction à la main :

| Couche | Provenance | Mécanisme |
|---|---|---|
| Noyau backend — authentification, RBAC, passerelle, audit, fournisseur OIDC, eID/SSO, IA | `public-gerege-core` (module Go) | dépendance `go.mod` |
| Couche frontend — `lib/**`, `components/**`, la logique de **158 routes BFF** | `@gerege/ui-core` (paquet npm) | dépendance `package.json` |

Résultat : le répertoire `backend/` de ce dépôt ne contient **qu'un seul fichier
Go** :

```
backend/
├── cmd/api/main.go        # ~30 lignes : démarrer le noyau, ajouter ses routes
├── deploy/                # Dockerfile, init de la base
└── .env.example           # modèle de configuration
```

```go
func main() {
    server.ServiceName = "gerege-template"
    app, err := server.NewApp()          // ← toutes les capacités du noyau
    // Ajoutez ici les routes propres à cette application :
    //   app.Router().Route("/api/xxx", xxx.Routes(app.Pool()))
    app.Run()
}
```

Le frontend suit la même forme — `app/**/page.tsx` sont de **fines enveloppes**
autour des vues du paquet, et `app/api/**` est une réexportation d'une ligne par
chemin :

```ts
// src/app/api/org/[id]/route.ts
export { GET, PUT, DELETE } from '@gerege/ui-core/api/org/[id]';
export const dynamic = 'force-dynamic';
```

!!! note "Pourquoi les enveloppes de routes restent"
    Les 158 fichiers pourraient se réduire à un unique `[...path]`. Mais la liste
    des routes est une **liste d'autorisation de sécurité** — elle définit quels
    chemins du backend le navigateur peut atteindre. Un catch-all la détruirait
    et ouvrirait un proxy vers tous les chemins. L'enveloppe est un prix
    délibéré.

Ce que la plateforme possède : `brand.config.ts` (nom · domaine · couleurs ·
URL de documentation), `components/landing/**` (texte marketing),
`app/globals.css` (jetons de couleur de marque), `deploy/**` et `.github/**`.

Deux garde-fous CI empêchent la duplication de revenir — `check-brand` (la
construction échoue si un nom de plateforme apparaît hors de `brand.config.ts`)
et `check-routes` (chaque route du paquet exige une enveloppe ; sans elle, un
nouvel endpoint **disparaîtrait silencieusement**).
