# Gerege Template Platform V3.0

> **Le socle pour bâtir des services numériques** — une pile complète, prête
> pour la production et durcie sur le plan de la sécurité, sur laquelle
> construire tout service numérique public ou privé.

**Gerege Template Platform V3.0** est le *socle des services numériques des
secteurs public et privé*. Vous construisez la valeur, pas la tuyauterie :
identité, sécurité, IA et ossature de service arrivent déjà résolues.

!!! tip "Open source"
    Cette plateforme est un projet **open source** — lisez l'intégralité du code,
    forkez-le et exécutez-le pour votre propre organisation.
    :material-github: [Voir sur GitHub](https://github.com/gerege-systems/open-gerege-mn)

<div class="grid cards" markdown>

- :material-shield-key: **eID + Gerege SSO**  
  Connexion fondée sur l'identité électronique (eID) + fournisseur SSO OpenID
  Connect (provider Go intégré). Les applications se connectent en un geste.

- :material-layers: **Clean Architecture**  
  Backend Go (chi · net/http · pgx, sans ORM) + frontend Next.js 16 (BFF).
  Couches nettes, faciles à étendre.

- :material-package-variant: **Code partagé**  
  Le noyau backend arrive via `go.mod`, la couche frontend via un paquet npm.
  Ce dépôt ne possède que sa marque, ses textes d'accueil et ses routes.

- :material-translate: **Mongol + les six langues de l'ONU**  
  Arabe · chinois · anglais · français · russe · espagnol — traductions
  entièrement intégrées, avec RTL automatique pour l'arabe.

- :material-account-network: **Proxy des services eID**  
  Les applications enregistrées appellent les services eID du SSO par
  autorisation (proxy) — elles n'ont jamais à détenir d'identifiants eID.

- :material-tune: **Passerelle API pilotée par l'administration**  
  Catalogue de services, autorisation par application, télémétrie — le tout
  depuis le système d'administration.

</div>

## L'écosystème

La plateforme se compose de plusieurs services indépendants :

| Domaine | Rôle |
|---|---|
| **sso.gerege.mn** | Gerege SSO — fournisseur OIDC + partie utilisatrice eID (détient les identifiants eID) |
| **public.template.gerege.mn** | Application d'exemple — partie utilisatrice de Gerege SSO (se connecte via le SSO) |

Les applications (comme `public.template.gerege.mn`) se connectent via
**sso.gerege.mn** et appellent les services eID autorisés par un proxy. Seul le
SSO détient les identifiants de partie utilisatrice qui dialoguent avec eID
Mongolia : les applications sont donc déchargées de cette responsabilité.

## Capacités clés

- **Authentification** — eID (QR / App2App / notification par numéro de registre) + liaison Google + Gerege SSO (OIDC).
- **Fournisseur OIDC** — bâti sur son propre code Go ; les applications proposent « Se connecter avec Gerege SSO ».
- **Profil ICP eID** — organisations, certificats, appareils, activité.
- **Signature de documents (PAdES)** — les applications tierces signent via le relais de signature eID.
- **Proxy des services eID** — personnel (`eid-proxy`) et organisationnel (`eid-org-proxy`), séparément.
- **Passerelle API** — catalogue de services, autorisation par application, télémétrie des requêtes.
- **Assistant IA (Gemini)** — chat, voix, traduction.
- **RBAC & super-administration**, **journal d'audit**, **durcissement** (RLS, CSP, HSTS, CSRF).
- **La surface de connexion est une configuration** — `AUTH_MODE` fait de la
  plateforme soit un service d'identité (`provider`), soit un consommateur d'un
  SSO amont (`client`) ; le code reste identique.
- **Sept langues d'emblée** — l'interface est livrée avec les traductions
  intégrées en mongol et dans les six langues officielles de l'ONU.

!!! tip "Par où commencer ?"
    Pour connecter votre application à Gerege SSO, voir
    [Intégration d'une application](sso-integration.md). Pour récupérer des
    données eID via le proxy, voir [Proxy des services eID](eid-services.md).
