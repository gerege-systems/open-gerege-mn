# Configuration (env)

> Tout se configure par variables d'environnement. L'exemple de référence est
> [`backend/.env.example`](https://github.com/gerege-systems/open-gerege-mn/blob/main/backend/.env.example).

!!! danger "Ne versionnez jamais de secrets"
    `backend/.env`, le `.env` racine et `backend.env` sont tous **ignorés par
    git**. Lorsque vous ajoutez une variable, documentez-la dans les README —
    jamais sa valeur.

## Base

| Variable | Exemple | Rôle |
|---|---|---|
| `PORT` | `8080` | Port d'écoute de l'API |
| `ENVIRONMENT` | `production` | Active les garde-fous stricts de production |
| `DEBUG` | `false` | Journalisation détaillée |
| `ALLOWED_ORIGINS` | `https://public.template.gerege.mn` | Liste d'origines CORS (séparées par des virgules ; `*` interdit) |
| `TRUSTED_PROXIES` | — | Adresses des reverse proxies |

## Base de données et Redis

| Variable | Rôle |
|---|---|
| `DB_POSTGRE_DSN` / `DB_POSTGRE_URL` | Chaîne de connexion |
| `DB_MAX_OPEN_CONNS`, `DB_MAX_IDLE_CONNS`, `DB_CONN_MAX_LIFE_MINS` | Réglage du pool |
| `REDIS_HOST`, `REDIS_PASS`, `REDIS_EXPIRED` | Connexion Redis et TTL |

!!! warning "En production, les DSN doivent utiliser `sslmode=verify-full`"
    Le garde-fou de production l'exige. La pile Docker Compose tourne
    délibérément avec `ENVIRONMENT=development`, car sa base interne n'a pas de
    TLS.

!!! danger "L'API ne doit pas se connecter en superutilisateur"
    La RLS ne s'applique que si l'application se connecte avec un rôle de moindre
    privilège. Un rôle superutilisateur ou `BYPASSRLS` fait échouer le démarrage
    en production.

## JWT et sessions

| Variable | Rôle |
|---|---|
| `JWT_SECRET` | **≥32 caractères.** Le modifier invalide toutes les sessions |
| `JWT_EXPIRED`, `JWT_REFRESH_EXPIRED` | Durées de vie accès / rafraîchissement |
| `JWT_ISSUER` | En général le domaine de l'application. Le modifier invalide tous les jetons existants |

## eID (partie utilisatrice)

| Variable | Rôle |
|---|---|
| `EID_BASE_URL` | Base `/v3` d'eID Mongolia (ou le relais de signature du SSO) |
| `EID_RP_UUID`, `EID_RP_SECRET` | Identifiants de partie utilisatrice |
| `SIGN_RELAY_TOKEN` | Jeton partagé du relais de signature (vide = désactivé) |

## Gerege SSO (côté RP — cette application comme client)

| Variable | Exemple | Rôle |
|---|---|---|
| `SSO_ISSUER` | `https://sso.gerege.mn` | Valeur par défaut si non défini |
| `SSO_CLIENT_ID` / `SSO_CLIENT_SECRET` | — | Vide : le flux SSO reste inerte |
| `SSO_REDIRECT_URI` | `https://public.template.gerege.mn/sso/callback` | Doit être enregistré **à l'identique** sur le client SSO |
| `SSO_SCOPE` | `openid profile email nationalid` | `nationalid` ajoute le numéro de registre |
| `SSO_NATIVE_CLIENT_ID` | — | Client du flux mobile (PKCE, public) |
| `SSO_EID_PROXY_BASE_URL` | — | Si défini, la surface ICP eID passe par le proxy du SSO |

!!! note "Un client non enregistré renvoie `invalid_client`"
    Si `SSO_CLIENT_ID` est absent du registre de clients du fournisseur, l'étape
    d'autorisation renvoie `{"error":"invalid_client"}`. L'URI de redirection
    doit correspondre exactement, elle aussi.

## Côté fournisseur OIDC (cette application comme fournisseur)

| Variable | Rôle |
|---|---|
| `OAUTH_ISSUER` | Par exemple `https://public.template.gerege.mn`. Le fournisseur n'est activé **que** si elle est définie |
| `SSO_STATE_KEY` | Clé HMAC de l'état transitoire de connexion/consentement (**≥32 octets**) |
| `SSO_FIRSTPARTY_CLIENTS` | Clients de première partie qui sautent l'écran de consentement |
| `SSO_ADMIN_API_KEYS`, `SSO_ADMIN_SUBS` | Accès à l'API d'administration |

## Surface de connexion (`AUTH_MODE`)

Que la plateforme **authentifie elle-même** ou **redirige vers un SSO amont**
n'est pas une différence de code : cette seule variable décide.

| Valeur | Sur la page d'accueil et `/login` |
|---|---|
| `provider` | La carte de connexion (eID n° de registre/QR · Google) s'affiche ici |
| `client` | Redirection vers le SSO amont (`SSO_ISSUER`) |

```bash
AUTH_MODE=client      # déploiement de référence de ce modèle — partie utilisatrice SSO
AUTH_MODE=provider    # un service d'identité tel que sso.dgov.mn / sso.gerege.mn
```

Laissez-la vide et elle est **déduite** de la présence de `SSO_CLIENT_ID` — les
déploiements existants n'ont donc rien à changer.

!!! warning "Une faute de frappe n'est PAS un repli silencieux"
    Une valeur non reconnue fait **refuser le démarrage** au backend. Sinon, la
    plateforme s'amorcerait discrètement avec une surface de connexion différente
    de celle prévue.

!!! note "Un axe DISTINCT de `OAUTH_ISSUER`"
    `OAUTH_ISSUER` répond à « cette plateforme est-elle un issuer **pour d'autres
    applications** » ; `AUTH_MODE` répond à « où se connectent **les utilisateurs
    de cette plateforme** ». Les deux peuvent être actifs à la fois — une
    configuration **en chaîne**.

Le frontend lit son mode depuis le point d'accès public `GET /api/v1/site/auth`
(sans authentification ni secret) : aucune variable d'environnement n'est donc
dupliquée côté frontend.

## Langues de l'interface

La plateforme est livrée avec des traductions intégrées pour le **mongol et les
six langues officielles de l'ONU** (arabe · chinois · anglais · français · russe
· espagnol). Les sept fonctionnent immédiatement — base de données vide et sans
aucune étape de traduction.

L'arabe reçoit automatiquement `<html dir="rtl">`.

| Variable | Remarque |
|---|---|
| — | Aucune configuration nécessaire ; les langues arrivent dans la table `languages` avec `is_builtin` |

Si vous avez besoin d'autres langues, un super-administrateur les ajoute sous
**Langues** et remplit les traductions avec Gemini — elles sont stockées comme
overlay en base de données.

## Tiers et stockage

| Variable | Rôle |
|---|---|
| `GEMINI_API_KEY` | Chaîne IA. Sans elle, `/ai/*` renvoie une véritable erreur 500 |
| `GOOGLE_CLIENT_ID` / `SECRET` | Liaison Google (le bouton disparaît si vide) |
| `VERIFY_API_BASE`, `VERIFY_API_KEY`, `VERIFY_CHANNEL` | Vérification des citoyens / organisations |
| `XYP_API_BASE`, `XYP_CLIENT_ID`, `XYP_CLIENT_SECRET` | Consultations des registres publics |
| `GSPACE_*` | Stockage SFTP propre à l'application (quota par utilisateur) |
| `INTEGRATION_ENC_KEY` | **≥16 octets.** Chiffre les jetons OAuth et le MFA du super-administrateur |

!!! danger "INTEGRATION_ENC_KEY est obligatoire"
    Les déploiements **exigent** cette clé, et une fois définie elle ne doit
    **jamais changer** : la faire tourner casse toutes les valeurs déjà
    chiffrées.

## Observabilité

| Variable | Rôle |
|---|---|
| `OTEL_EXPORTER`, `OTEL_SAMPLE_RATIO` | Traçage OpenTelemetry |
| `OBSERVABILITY_TOKEN` | Jeton bearer protégeant `/metrics` et `/swagger` en production |

## Frontend

| Variable | Rôle |
|---|---|
| `BACKEND_URL` | L'adresse **interne** appelée par le BFF (par ex. `http://api:8080`) |

!!! warning "Le nom `api` peut entrer en collision sur un réseau partagé"
    Lorsque plusieurs piles partagent un même réseau Docker, `http://api:8080`
    peut se résoudre vers un autre conteneur et tous les appels `/api/v1/*`
    deviennent des 404. Dans ce cas, fixez `BACKEND_URL` sur le nom complet de
    votre propre conteneur api.
