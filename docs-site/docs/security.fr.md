# Sécurité

> La sécurité est intégrée, non rapportée. Cette page résume les contrôles
> **implémentés dans le code**.

## Authentification et sessions

| Contrôle | Détail |
|---|---|
| **eID est la seule connexion** | La seule connexion interactive est eID (QR / App2App / notification par numéro de registre). Il n'existe **aucune surface de mot de passe** |
| JWT d'accès + de rafraîchissement | Les jetons de rafraîchissement **tournent** ; protégés par un claim `kind` |
| Liste de refus à la déconnexion | La déconnexion place le `jti` du jeton d'accès dans Redis pour sa durée restante ; l'intergiciel le vérifie à chaque requête |
| Certificat citoyen (ICP) | La fin de la connexion renvoie le certificat citoyen (DER), analysé avec `crypto/x509` ; numéro de série, fenêtre de validité et émetteur sont conservés |
| Liaison Google | Liaison **uniquement** — indexée sur une colonne de sujet stable |

!!! note "L'absence de mots de passe est délibérée"
    Comme aucun flux de mot de passe n'existe, des contrôles tels que HIBP,
    bcrypt ou la détection de mots de passe fuités sont **sans objet**. Des cas
    d'usage hérités (mot de passe / OTP) subsistent dans l'arborescence mais ne
    sont accessibles depuis aucune route. Si un chemin par mot de passe devait
    être réexposé, branchez la vérification HIBP **avant** de le livrer.

## Couche de données

- **Requêtes paramétrées uniquement** (pgx) — pas de concaténation de chaînes,
  pas d'ORM.
- **Row-Level Security** — `ENABLE` **et `FORCE`** sur chaque table par
  utilisateur : `users`, `organizations`, `organization_memberships`, les tables
  citoyennes `gov_*` et `user_integrations`. Les politiques s'appuient sur les
  GUC `app.user_id` / `app.user_role` définis par transaction avec `SET LOCAL`.
- **Pas d'identité ⇒ zéro ligne** (fail-closed), ce qui prémunit contre les
  divulgations accidentelles.

!!! warning "Garde-fou RLS au démarrage"
    Au démarrage, l'application inspecte son propre rôle de base de données. En
    production, un rôle **superutilisateur** ou `BYPASSRLS` **fait échouer le
    démarrage** — sinon la RLS ne s'appliquerait pas silencieusement. En
    développement, elle se contente d'avertir.

    Chaque nouvelle table par utilisateur a besoin de ses propres politiques.

## Secrets et chiffrement

| Quoi | Comment |
|---|---|
| Jetons OAuth tiers | Scellés en **AES-256-GCM** avant stockage (`INTEGRATION_ENC_KEY`) |
| Identifiants de jeton / session | `crypto/rand` avec échantillonnage par rejet pour éviter le biais de modulo |
| MFA du super-administrateur (TOTP) | Également chiffré avec `INTEGRATION_ENC_KEY` |

!!! danger "Ne jamais faire tourner INTEGRATION_ENC_KEY sur place"
    Modifier une clé déjà en service **casse toutes les valeurs précédemment
    chiffrées**. Le script de déploiement l'écrit une seule fois, uniquement si
    elle est absente (idempotent).

## Couche web et réseau

- **En-têtes de sécurité** — CSP `default-src 'none'`, HSTS (prod), `nosniff`,
  `X-Frame-Options: DENY`, Referrer-Policy, Permissions-Policy, COOP/CORP/COEP.
- **CORS** — liste d'origines strictement autorisées ; jamais `*` combiné à des
  identifiants.
- **Limites de taille de corps** — plafond global plus 4 Kio sur `/auth`.
- **Délais serveur complets** — `ReadHeader` 10 s, `Read` 30 s, `Write` 70 s,
  `Idle` 120 s, `MaxHeaderBytes` 16 Kio (défense slowloris / en-têtes surdimensionnés).
- **Délai par requête** — 30 s en général ; `/ai/*` bénéficie de 50 s (le TTS/STT
  Gemini prend couramment 10 à 20 s, ce qui ne tenait pas dans la limite de 30 s).
- **Limitation de débit** — `/auth` ~5/min, `/ai/*` ~20/min, et le chat anonyme
  d'accueil `/public/ai/chat` ~6/min — par IP.
- **Permissions-Policy** — `camera=(), microphone=(self), geolocation=()`.
  Le microphone n'est autorisé que pour cette origine (le chat vocal IA appelle
  `getUserMedia`) ; avec `microphone=()` le navigateur le refuse d'emblée, sans
  même demander.

### Frontend (modèle BFF)

Le navigateur ne dialogue qu'avec des routes `/api/*` de **même origine**. Les
jetons vivent dans des cookies `httpOnly` et n'atteignent **jamais** le JS
client. Tout appel modifiant l'état porte un en-tête `x-dgov-csrf` que le serveur
valide avec `checkOrigin` — une double défense CSRF.

## Journal d'audit

Chaîné par empreintes et en ajout seul :

```
chain_hash = SHA-256(prev_hash ‖ canonical-json(entrée))
```

Les écritures sont sérialisées par `pg_advisory_xact_lock` ; `VerifyChain` rend
toute altération visible. Lecture réservée à l'administration.

## Autorisation (RBAC)

Un catalogue dynamique de rôles et de permissions sur quatre niveaux :
**superadmin → admin → gestionnaire → utilisateur**. Les routes sont protégées
par les intergiciels `RequirePermission` / `RequireAdmin`. Le super-administrateur
est le seul rôle qui gère les comptes administrateurs, et il n'est jamais créé
via l'API — uniquement par la base de données ou l'environnement.

## Durcissement opérationnel

En production, `/metrics` et `/swagger/doc.json` sont protégés par un jeton
bearer (comparaison à temps constant, **404** en cas d'échec). Les journaux sont
structurés (Zap) avec un identifiant de requête, et aucun secret n'est journalisé.

## Feuille de route ASVS

| Niveau | Statut |
|---|---|
| **L1** | ✅ HTTPS + HSTS, connexion sans mot de passe, requêtes paramétrées, en-têtes, CORS strict, validation des entrées, journalisation structurée, aucun secret versionné. ⏳ analyse de conteneurs / `govulncheck` |
| **L2** | ✅ limitation de débit, rotation des rafraîchissements, liaison d'appareil eID (résistante au hameçonnage), délais de requête, jetons d'intégration chiffrés, audit chaîné. ⏳ WAF, SIEM central, test de restauration, plan de réponse aux incidents |
| **L3** | ◻ chiffrement des données personnelles au niveau du champ (KMS), mTLS, provenance SLSA L3, test d'intrusion externe — *hors périmètre du modèle* |

## Limites connues

- **Interface Swagger interactive** — seule la spécification brute est servie sur
  `/swagger/doc.json` (chargez-la dans Swagger Editor ou Postman).
- La matrice complète des contrôles se trouve dans
  [`backend/docs/SECURITY.md`](https://github.com/gerege-systems/public-gerege-template/blob/main/backend/docs/SECURITY.md).

!!! tip "Signaler une vulnérabilité"
    N'ouvrez pas de ticket public. Suivez la procédure décrite dans
    [SECURITY.md](https://github.com/gerege-systems/public-gerege-template/blob/main/SECURITY.md).
