# Passerelle API

La passerelle API est un **catalogue de services + télémétrie**, piloté depuis
le système d'administration. Chaque service exposé (par exemple le proxy eID)
est enregistré au catalogue et accordé aux applications par autorisation
individuelle.

## Catalogue de services

| Service | Chemin | Type | Autorisation |
|---|---|---|---|
| **Connexion SSO** | `/oauth2` | De base (intégré) | Automatique pour toutes les applications |
| **`eid-sign`** | `/rp/sign` | Complémentaire | Octroi par application |
| **`eid-proxy`** | `/rp/eid` | Complémentaire | Octroi par application |
| **`eid-org-proxy`** | `/rp/eid-org` | Complémentaire | Octroi par application |

!!! note "La connexion SSO ne figure pas au catalogue"
    La connexion SSO est un service **de base** — fourni automatiquement à toute
    application enregistrée via les portées OIDC de base, sans octroi ni case à
    cocher. Elle n'apparaît donc pas parmi les services de passerelle
    attribuables.

## Gérer les services (administration)

Dans **Administration → Passerelle → Services**, vous listez, créez, modifiez et
**activez ou désactivez** les services. La création d'un service dérive
automatiquement une portée `svc:<nom>` afin de pouvoir l'accorder aux
applications.

- L'indicateur **activé** prend effet à chaud : la route du proxy eID vérifie si
  le service est activé et renvoie `503` lorsqu'il ne l'est pas.

## Accorder un service à une application

Dans **Administration → Applications → l'application → SERVICES**, accordez les
services via les cases à cocher. L'octroi ajoute `svc:<nom>` aux portées
autorisées du client OAuth2 de l'application ; la révocation les retire. L'effet
est **immédiat** — le proxy vérifie l'autorisation courante du client.

```text
Application « template.gerege.mn »
  ├─ Connexion SSO .......... automatique (intégrée)
  ├─ [x] eid-sign ........... svc:eid-sign
  ├─ [ ] eid-proxy .......... non accordé → /rp/eid → 403
  └─ [ ] eid-org-proxy ...... non accordé → /rp/eid-org → 403
```

## Télémétrie

La passerelle enregistre les requêtes réelles vers `/api` (méthode, chemin,
statut, latence) et les affiche sous **Administration → Passerelle → Vue
d'ensemble / Journaux**.

## Ajouter un nouveau service proxy (développeurs)

Suivez ce schéma pour ajouter d'autres services internes à la passerelle et les
gérer depuis l'administration :

1. Insérez une ligne `gateway_services` (migration) — nom, chemin, étiquettes.
2. Vérifiez l'interrupteur à chaud sur la route via `gatewayUC.ServiceEnabled(nom)`.
3. Vérifiez l'octroi de `svc:<nom>` dans l'intergiciel OAuth.
4. Ajoutez un chemin public dans nginx (`/rp/<nom>/` → backend).
