# Intégration d'une application (Gerege SSO / RP OIDC)

Connectez votre application comme partie utilisatrice de **Gerege SSO
(sso.gerege.mn)**. Lorsque l'utilisateur clique sur « Se connecter », il est
redirigé vers sso.gerege.mn, s'authentifie avec eID, puis revient dans votre
application.

## 1. Enregistrer votre application comme client RP

Deux possibilités :

=== "Interface d'administration"

    Dans **Administration → Applications → Nouvelle application**, saisissez le
    nom, l'URI de redirection et l'étiquette, puis enregistrez. Accordez les
    services eID nécessaires (par exemple eid-proxy) via les cases à cocher.
    Vous recevez un `client_id` / `client_secret`.

=== "Script CLI"

    Sur le serveur, `register-rp.sh` renseigne correctement **à la fois** la
    redirection de connexion et l'URI de redirection après déconnexion (afin que
    la déconnexion n'échoue pas) :

    ```bash
    cd /srv/sso-dgov-mn
    ./scripts/register-rp.sh "Mon application" https://myapp.dgov.mn
    # → affiche client_id + client_secret
    #   redirect_uri            = https://myapp.dgov.mn/sso/callback
    #   post_logout_redirect_uri= https://myapp.dgov.mn/
    ```

## 2. Configuration de l'application

Si votre application est bâtie sur ce modèle, renseignez dans `backend.env` :

```env
SSO_ISSUER=https://sso.gerege.mn
SSO_CLIENT_ID=<client_id>
SSO_CLIENT_SECRET=<client_secret>
SSO_REDIRECT_URI=https://myapp.dgov.mn/sso/callback
SSO_SCOPE=openid profile email
```

## 3. Le flux de connexion

1. L'utilisateur clique sur **« Se connecter avec Gerege SSO »** → `/api/auth/sso/start`.
2. Le backend `/sso/start` crée un état (Redis) et construit l'URL d'autorisation
   `sso.gerege.mn/oauth2/auth` ; le navigateur y est redirigé.
3. L'utilisateur s'authentifie avec eID sur sso.gerege.mn.
4. sso.gerege.mn redirige vers `https://myapp.dgov.mn/sso/callback?code&state`.
5. Le backend `/sso/callback` échange le code contre des jetons, met à jour le
   citoyen par `sso_sub`, puis émet la session propre à l'application (JWT).

## 4. Déconnexion

La déconnexion initiée par la partie utilisatrice redirige vers
`sso.gerege.mn/oauth2/sessions/logout` avec un `id_token_hint` et un
`post_logout_redirect_uri`. Cette URI de post-déconnexion doit être
**enregistrée sur le client** (`register-rp.sh` s'en charge automatiquement).

!!! warning "Enregistrez la redirection post-déconnexion"
    Si une application n'est enregistrée qu'avec une redirection de connexion, la
    déconnexion échoue avec *« post_logout_redirect_uri is not whitelisted »*.
    `register-rp.sh` et l'interface d'administration renseignent les deux URI
    ensemble, ce qui évite cette erreur.

## Accorder des services complémentaires

Au-delà de la connexion, si votre application a besoin des services
**complémentaires** du SSO (par exemple le proxy eID), l'administrateur accorde
ce service à l'application. Voir [Proxy des services eID](eid-services.md) et
[Passerelle API](api-gateway.md).
