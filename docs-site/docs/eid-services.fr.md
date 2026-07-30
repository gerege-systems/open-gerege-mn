# Proxy des services eID

Les applications enregistrées appellent les services eID de **Gerege SSO** au
nom de leurs utilisateurs via un **proxy**. Le SSO identifie l'utilisateur à
partir du sujet du jeton et récupère les données avec **ses propres**
identifiants de partie utilisatrice eidmongolia.mn — les applications n'ont donc
jamais besoin de détenir des identifiants eID.

## Deux services

| Service | Chemin public | Points d'accès |
|---|---|---|
| **`eid-proxy`** (personnel) | `https://sso.gerege.mn/rp/eid/*` | `summary` · `certificates` · `devices` · `activity` |
| **`eid-org-proxy`** (organisations) | `https://sso.gerege.mn/rp/eid-org/*` | `organizations` · `organizations/{regNo}/signers` |

Tous sont en **lecture seule** (GET). Les services personnels et organisationnels
sont regroupés séparément afin que l'administrateur puisse les gérer
indépendamment.

## Appeler le proxy

```bash
GET https://sso.gerege.mn/rp/eid/summary
Authorization: Bearer <jeton d'accès SSO de l'utilisateur>
```

La réponse contient les données eID de cet utilisateur (récupérées avec les
identifiants de partie utilisatrice du SSO).

## Autorisation

Le service doit être **accordé** à l'application. L'autorisation s'exprime par
la **portée de service** (`svc:eid-proxy` / `svc:eid-org-proxy`) dans les
portées OAuth2 autorisées du client — accorder le service à l'application depuis
l'administration ajoute cette portée.

À chaque requête, le SSO :

1. Inspecte le jeton (RFC 7662) → `active` + `sub`.
2. Recherche le client par le `client_id` du jeton et vérifie si la portée de
   service est accordée (il vérifie l'autorisation **courante**, l'octroi et la
   révocation sont donc immédiats).
3. Résout l'utilisateur depuis `sub` et récupère les données auprès d'eID Mongolia.

| Condition | Réponse |
|---|---|
| Pas de jeton / jeton expiré | `401` |
| Service non accordé à l'application | `403` |
| Service désactivé dans la passerelle | `503` |
| Succès | `200` + données |

!!! tip "Comment accorder l'accès ?"
    Administration → Applications → l'application → cocher **eid-proxy** /
    **eid-org-proxy** → Enregistrer. Une application sans autorisation reçoit un
    403. Voir [Passerelle API](api-gateway.md) pour le détail.

## Interrupteur à chaud

Les deux services sont enregistrés dans le **catalogue de la passerelle API** et
peuvent être **activés ou désactivés** depuis l'interface d'administration en
cours d'exécution (désactivé → `503`). L'eID personnel peut être coupé pendant
que l'eID organisationnel continue de fonctionner (ils sont indépendants).
