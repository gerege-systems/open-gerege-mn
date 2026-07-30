# Configuración (env)

> Todo se configura mediante variables de entorno. El ejemplo canónico es
> [`backend/.env.example`](https://github.com/gerege-systems/public-gerege-template/blob/main/backend/.env.example).

!!! danger "Nunca subas secretos al repositorio"
    `backend/.env`, el `.env` raíz y `backend.env` están todos **ignorados por
    git**. Cuando añadas una variable, documéntala en los README, nunca su valor.

## Básicos

| Variable | Ejemplo | Función |
|---|---|---|
| `PORT` | `8080` | Puerto de escucha de la API |
| `ENVIRONMENT` | `production` | Activa las comprobaciones estrictas de producción |
| `DEBUG` | `false` | Registro detallado |
| `ALLOWED_ORIGINS` | `https://template.gerege.mn` | Lista de orígenes CORS (separados por comas; `*` prohibido) |
| `TRUSTED_PROXIES` | — | Direcciones de los proxies inversos |

## Base de datos y Redis

| Variable | Función |
|---|---|
| `DB_POSTGRE_DSN` / `DB_POSTGRE_URL` | Cadena de conexión |
| `DB_MAX_OPEN_CONNS`, `DB_MAX_IDLE_CONNS`, `DB_CONN_MAX_LIFE_MINS` | Ajuste del pool |
| `REDIS_HOST`, `REDIS_PASS`, `REDIS_EXPIRED` | Conexión a Redis y TTL |

!!! warning "En producción los DSN deben usar `sslmode=verify-full`"
    La comprobación de producción lo exige. La pila de Docker Compose se ejecuta
    deliberadamente con `ENVIRONMENT=development`, porque su base de datos
    interna no tiene TLS.

!!! danger "La API no debe conectarse como superusuario"
    La RLS solo se aplica si la aplicación se conecta con un rol de mínimo
    privilegio. Un rol superusuario o con `BYPASSRLS` hace fallar el arranque en
    producción.

## JWT y sesiones

| Variable | Función |
|---|---|
| `JWT_SECRET` | **≥32 caracteres.** Cambiarlo invalida todas las sesiones |
| `JWT_EXPIRED`, `JWT_REFRESH_EXPIRED` | Vigencia de acceso / actualización |
| `JWT_ISSUER` | Normalmente el dominio de la aplicación. Cambiarlo invalida todos los tokens existentes |

## eID (parte confiante)

| Variable | Función |
|---|---|
| `EID_BASE_URL` | Base `/v3` de eID Mongolia (o el relé de firma del SSO) |
| `EID_RP_UUID`, `EID_RP_SECRET` | Credenciales de parte confiante |
| `SIGN_RELAY_TOKEN` | Token compartido del relé de firma (vacío lo desactiva) |

## Gerege SSO (lado RP: esta aplicación como cliente)

| Variable | Ejemplo | Función |
|---|---|---|
| `SSO_ISSUER` | `https://sso.gerege.mn` | Valor por defecto si no se define |
| `SSO_CLIENT_ID` / `SSO_CLIENT_SECRET` | — | Vacío deja el flujo SSO inactivo |
| `SSO_REDIRECT_URI` | `https://template.gerege.mn/sso/callback` | Debe estar registrado **exactamente igual** en el cliente SSO |
| `SSO_SCOPE` | `openid profile email nationalid` | `nationalid` añade el número de identidad civil |
| `SSO_NATIVE_CLIENT_ID` | — | Cliente del flujo móvil (PKCE, público) |
| `SSO_EID_PROXY_BASE_URL` | — | Si se define, la superficie PKI de eID pasa por el proxy del SSO |

!!! note "Un cliente sin registrar devuelve `invalid_client`"
    Si `SSO_CLIENT_ID` no consta en el registro de clientes del proveedor, el
    paso de autorización devuelve `{"error":"invalid_client"}`. La URI de
    redirección también debe coincidir exactamente.

## Lado proveedor OIDC (esta aplicación como proveedor)

| Variable | Función |
|---|---|
| `OAUTH_ISSUER` | Por ejemplo `https://template.gerege.mn`. El proveedor se activa **solo** cuando se define |
| `SSO_STATE_KEY` | Clave HMAC del estado transitorio de acceso/consentimiento (**≥32 bytes**) |
| `SSO_FIRSTPARTY_CLIENTS` | Clientes de primera parte que omiten la pantalla de consentimiento |
| `SSO_ADMIN_API_KEYS`, `SSO_ADMIN_SUBS` | Acceso a la API de administración |

## Superficie de acceso (`AUTH_MODE`)

Que la plataforma **autentique ella misma** o **redirija a un SSO superior** no
es una diferencia de código: lo decide esta única variable.

| Valor | En la portada y en `/login` |
|---|---|
| `provider` | La tarjeta de acceso (eID n.º de registro/QR · Google) se muestra aquí |
| `client` | Redirección al SSO superior (`SSO_ISSUER`) |

```bash
AUTH_MODE=client      # despliegue de referencia de esta plantilla — parte confiante del SSO
AUTH_MODE=provider    # un servicio de identidad como sso.dgov.mn / sso.gerege.mn
```

Déjala vacía y se **deduce** de si `SSO_CLIENT_ID` está configurado, de modo que
los despliegues existentes no necesitan cambio alguno.

!!! warning "Una errata NO provoca un repliegue silencioso"
    Con un valor no reconocido, el backend **se niega a arrancar**. De lo
    contrario, la plataforma se levantaría en silencio con una superficie de
    acceso distinta de la prevista.

!!! note "Un eje APARTE de `OAUTH_ISSUER`"
    `OAUTH_ISSUER` responde a «¿es esta plataforma un issuer **para otras
    aplicaciones**?»; `AUTH_MODE` responde a «¿dónde inician sesión **los
    usuarios de esta plataforma**?». Ambos pueden estar activos a la vez: un
    montaje **encadenado**.

El frontend obtiene su modo del endpoint público `GET /api/v1/site/auth` (sin
autenticación ni secretos), así que no hay variables de entorno duplicadas en el
frontend.

## Idiomas de la interfaz

La plataforma incluye traducciones integradas para el **mongol y las seis
lenguas oficiales de la ONU** (árabe · chino · inglés · francés · ruso ·
español). Las siete funcionan de inmediato: con la base de datos vacía y sin
ningún paso de traducción.

El árabe recibe automáticamente `<html dir="rtl">`.

| Variable | Notas |
|---|---|
| — | No hace falta configuración; los idiomas llegan a la tabla `languages` como `is_builtin` |

Si necesitas más idiomas, un superadministrador los añade en **Idiomas** y
rellena las traducciones con Gemini: se guardan como overlay en la base de datos.

## Terceros y almacenamiento

| Variable | Función |
|---|---|
| `GEMINI_API_KEY` | Canal de IA. Sin ella, `/ai/*` devuelve un 500 real |
| `GOOGLE_CLIENT_ID` / `SECRET` | Vinculación con Google (el botón se oculta si está vacío) |
| `VERIFY_API_BASE`, `VERIFY_API_KEY`, `VERIFY_CHANNEL` | Verificación de ciudadanos / organizaciones |
| `XYP_API_BASE`, `XYP_CLIENT_ID`, `XYP_CLIENT_SECRET` | Consultas a los registros públicos |
| `GSPACE_*` | Almacenamiento SFTP propio de la aplicación (cuota por usuario) |
| `INTEGRATION_ENC_KEY` | **≥16 bytes.** Cifra los tokens OAuth y el MFA del superadministrador |

!!! danger "INTEGRATION_ENC_KEY es obligatoria"
    Los despliegues **requieren** esta clave y, una vez definida, **nunca debe
    cambiar**: rotarla rompe todos los valores cifrados previamente.

## Observabilidad

| Variable | Función |
|---|---|
| `OTEL_EXPORTER`, `OTEL_SAMPLE_RATIO` | Trazas de OpenTelemetry |
| `OBSERVABILITY_TOKEN` | Token bearer que protege `/metrics` y `/swagger` en producción |

## Frontend

| Variable | Función |
|---|---|
| `BACKEND_URL` | La dirección **interna** a la que llama el BFF (p. ej. `http://api:8080`) |

!!! warning "El nombre `api` puede colisionar en una red compartida"
    Cuando varias pilas comparten una misma red de Docker, `http://api:8080`
    puede resolverse a otro contenedor y todas las llamadas `/api/v1/*` acaban en
    404. En ese caso, fija `BACKEND_URL` al nombre completo de tu propio
    contenedor api.
