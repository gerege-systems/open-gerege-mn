# Seguridad

> La seguridad viene incorporada, no añadida después. Esta página resume los
> controles **implementados en el código**.

## Autenticación y sesiones

| Control | Detalle |
|---|---|
| **eID es el único acceso** | El único inicio de sesión interactivo es eID (QR / App2App / notificación por número de registro). **No existe ninguna superficie de contraseña** |
| JWT de acceso + de actualización | Los tokens de actualización **rotan**; protegidos por un claim `kind` |
| Lista de denegación al cerrar sesión | El cierre de sesión coloca el `jti` del token de acceso en Redis durante su TTL restante; el middleware lo comprueba en cada petición |
| Certificado ciudadano (PKI) | Al completar el acceso se devuelve el certificado ciudadano (DER), analizado con `crypto/x509`; se conservan número de serie, ventana de validez y emisor |
| Vinculación con Google | **Solo** vinculación, indexada por una columna de sujeto estable |

!!! note "La ausencia de contraseñas es deliberada"
    Como no existe ningún flujo de contraseña, controles como HIBP, bcrypt o la
    detección de contraseñas filtradas **no son aplicables**. En el árbol quedan
    casos de uso heredados de contraseña/OTP, pero no son alcanzables desde
    ninguna ruta. Si alguna vez se vuelve a exponer una vía por contraseña,
    conecta la comprobación HIBP **antes** de publicarla.

## Capa de datos

- **Solo consultas parametrizadas** (pgx): sin concatenación de cadenas y sin ORM.
- **Row-Level Security**: `ENABLE` **y `FORCE`** en cada tabla por usuario:
  `users`, `organizations`, `organization_memberships`, las tablas ciudadanas
  `gov_*` y `user_integrations`. Las políticas se rigen por las GUC
  `app.user_id` / `app.user_role`, definidas por transacción con `SET LOCAL`.
- **Sin identidad ⇒ cero filas** (fail-closed), lo que protege frente a
  divulgaciones accidentales.

!!! warning "Guarda de RLS al arranque"
    Al iniciarse, la aplicación inspecciona su propio rol de base de datos. En
    producción, un rol **superusuario** o con `BYPASSRLS` **hace fallar el
    arranque**; de lo contrario la RLS no se aplicaría en silencio. En desarrollo
    solo advierte.

    Cada tabla nueva por usuario necesita sus propias políticas.

## Secretos y cifrado

| Qué | Cómo |
|---|---|
| Tokens OAuth de terceros | Sellados con **AES-256-GCM** antes de almacenarse (`INTEGRATION_ENC_KEY`) |
| Identificadores de token / sesión | `crypto/rand` con muestreo por rechazo para evitar el sesgo de módulo |
| MFA del superadministrador (TOTP) | También cifrado con `INTEGRATION_ENC_KEY` |

!!! danger "Nunca rotes INTEGRATION_ENC_KEY sobre la marcha"
    Cambiar una clave ya establecida **rompe todos los valores cifrados
    anteriormente**. El script de despliegue la escribe una sola vez, solo cuando
    falta (idempotente).

## Capa web y de red

- **Cabeceras de seguridad**: CSP `default-src 'none'`, HSTS (producción),
  `nosniff`, `X-Frame-Options: DENY`, Referrer-Policy, Permissions-Policy,
  COOP/CORP/COEP.
- **CORS**: lista estricta de orígenes permitidos; nunca `*` junto con
  credenciales.
- **Límites de tamaño del cuerpo**: tope global más 4 KiB en `/auth`.
- **Tiempos de espera completos del servidor**: `ReadHeader` 10 s, `Read` 30 s,
  `Write` 70 s, `Idle` 120 s, `MaxHeaderBytes` 16 KiB (defensa frente a slowloris
  y cabeceras desmesuradas).
- **Tiempo de espera por petición**: 30 s en general; `/ai/*` dispone de 50 s (el
  TTS/STT de Gemini tarda habitualmente entre 10 y 20 s, lo que no cabía en el
  límite de 30 s).
- **Limitación de tasa**: `/auth` ~5/min, `/ai/*` ~20/min y el chat anónimo de la
  portada `/public/ai/chat` ~6/min, por IP.
- **Permissions-Policy**: `camera=(), microphone=(self), geolocation=()`.
  El micrófono se permite solo para este origen (el chat de voz con IA llama a
  `getUserMedia`); con `microphone=()` el navegador lo rechaza de plano, sin
  siquiera preguntar.

### Frontend (modelo BFF)

El navegador solo habla con rutas `/api/*` del **mismo origen**. Los tokens viven
en cookies `httpOnly` y **nunca** llegan al JS cliente. Toda llamada que modifica
estado lleva una cabecera `x-dgov-csrf` que el servidor valida con `checkOrigin`:
una doble defensa CSRF.

## Registro de auditoría

Encadenado por hash y de solo anexado:

```
chain_hash = SHA-256(prev_hash ‖ canonical-json(entrada))
```

Las escrituras se serializan con `pg_advisory_xact_lock`; `VerifyChain` deja en
evidencia cualquier manipulación. Solo lo lee la administración.

## Autorización (RBAC)

Un catálogo dinámico de roles y permisos en cuatro niveles: **superadmin →
admin → gestor → usuario**. Las rutas están protegidas por los middleware
`RequirePermission` / `RequireAdmin`. El superadministrador es el único rol que
gestiona cuentas de administrador, y nunca se crea a través de la API: solo desde
la base de datos o el entorno.

## Endurecimiento operativo

En producción, `/metrics` y `/swagger/doc.json` quedan tras un token bearer
(comparación en tiempo constante, **404** si no coincide). Los registros son
estructurados con Zap e incluyen un identificador de petición; los secretos nunca
se registran.

## Hoja de ruta ASVS

| Nivel | Estado |
|---|---|
| **L1** | ✅ HTTPS + HSTS, acceso sin contraseña, consultas parametrizadas, cabeceras, CORS estricto, validación de entrada, registro estructurado, sin secretos versionados. ⏳ análisis de contenedores / `govulncheck` |
| **L2** | ✅ limitación de tasa, rotación de refresco, vinculación de dispositivo eID (resistente al phishing), tiempos de espera, tokens de integración cifrados, auditoría encadenada. ⏳ WAF, SIEM central, prueba de restauración de copias, plan de respuesta a incidentes |
| **L3** | ◻ cifrado de datos personales a nivel de campo (KMS), mTLS, procedencia SLSA L3, pentest externo — *fuera del alcance de la plantilla* |

## Carencias conocidas

- **Interfaz interactiva de Swagger**: solo se sirve la especificación en bruto
  en `/swagger/doc.json` (cárgala en Swagger Editor o Postman).
- La matriz completa de controles está en
  [`backend/docs/SECURITY.md`](https://github.com/gerege-systems/open-gerege-mn/blob/main/backend/docs/SECURITY.md).

!!! tip "Comunicar una vulnerabilidad"
    No abras una incidencia pública. Sigue el proceso descrito en
    [SECURITY.md](https://github.com/gerege-systems/open-gerege-mn/blob/main/SECURITY.md).
