# Integración de una aplicación (Gerege SSO / RP OIDC)

Conecta tu aplicación como parte confiante de **Gerege SSO (sso.gerege.mn)**.
Cuando la persona usuaria pulsa «Acceder», se la redirige a sso.gerege.mn, se
autentica con eID y vuelve a tu aplicación.

## 1. Registrar tu aplicación como cliente RP

Dos formas:

=== "Interfaz de administración"

    En **Administración → Aplicaciones → Nueva aplicación**, introduce el
    nombre, la URI de redirección y la etiqueta, y guarda. Concede los servicios
    eID que necesites (por ejemplo, eid-proxy) mediante casillas. Recibirás un
    `client_id` / `client_secret`.

=== "Script de consola"

    En el servidor, `register-rp.sh` configura correctamente **tanto** la
    redirección de acceso **como** la URI de redirección tras el cierre de
    sesión (para que el cierre de sesión no falle):

    ```bash
    cd /srv/sso-dgov-mn
    ./scripts/register-rp.sh "Mi aplicación" https://myapp.dgov.mn
    # → imprime client_id + client_secret
    #   redirect_uri            = https://myapp.dgov.mn/sso/callback
    #   post_logout_redirect_uri= https://myapp.dgov.mn/
    ```

## 2. Configuración de la aplicación

Si tu aplicación está construida sobre esta plantilla, define en `backend.env`:

```env
SSO_ISSUER=https://sso.gerege.mn
SSO_CLIENT_ID=<client_id>
SSO_CLIENT_SECRET=<client_secret>
SSO_REDIRECT_URI=https://myapp.dgov.mn/sso/callback
SSO_SCOPE=openid profile email
```

## 3. El flujo de acceso

1. La persona pulsa **«Acceder con Gerege SSO»** → `/api/auth/sso/start`.
2. El backend `/sso/start` crea el estado (Redis) y construye la URL de
   autorización en `sso.gerege.mn/oauth2/auth`; el navegador se redirige allí.
3. La persona se autentica con eID en sso.gerege.mn.
4. sso.gerege.mn redirige de vuelta a
   `https://myapp.dgov.mn/sso/callback?code&state`.
5. El backend `/sso/callback` canjea el código por tokens, inserta o actualiza
   al ciudadano por `sso_sub` y emite la sesión propia de la aplicación (JWT).

## 4. Cierre de sesión

El cierre de sesión iniciado por la parte confiante redirige a
`sso.gerege.mn/oauth2/sessions/logout` con un `id_token_hint` y un
`post_logout_redirect_uri`. Esa URI posterior al cierre de sesión debe estar
**registrada en el cliente** (`register-rp.sh` la configura automáticamente).

!!! warning "Registra la redirección posterior al cierre de sesión"
    Si una aplicación se registra solo con la redirección de acceso, el cierre
    de sesión falla con *«post_logout_redirect_uri is not whitelisted»*.
    `register-rp.sh` y la interfaz de administración configuran ambas URI a la
    vez, así que este error no se produce.

## Conceder servicios complementarios

Más allá del acceso, si tu aplicación necesita los servicios
**complementarios** del SSO (por ejemplo, el proxy eID), el administrador
concede ese servicio a la aplicación. Véase
[Proxy de servicios eID](eid-services.md) y [Pasarela de API](api-gateway.md).
