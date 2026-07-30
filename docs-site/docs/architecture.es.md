# Arquitectura

La plataforma sigue la **arquitectura limpia**: `handler → usecase → repository →
domain`. El núcleo de negocio nunca importa el framework web.

## Componentes

```
Internet ──► nginx (TLS)
   │
   ├─ /oauth2/*, /.well-known/*, /userinfo ─► API Go — emisor OIDC integrado
   ├─ /rp/sign/*   ─► relé de firma eID (backend)
   ├─ /rp/eid/*     ─► proxy de servicio eID — personal (backend)
   ├─ /rp/eid-org/* ─► proxy de servicio eID — organizaciones (backend)
   └─ todo lo demás ─► BFF de Next.js (web) ──► API backend (:8080)
                                                   │
   red interna:  db (PostgreSQL) · redis
```

## Capas

| Capa | Tecnología | Notas |
|---|---|---|
| **Backend** | Go · chi (net/http) · pgx (sin ORM) | Arquitectura limpia, RLS, SQL escrito a mano |
| **Frontend** | Next.js 16 (BFF) | El navegador solo habla con rutas del mismo origen; los tokens nunca llegan al JS cliente |
| **Proveedor OIDC** | Integrado (Go, usecases/oidc) | la plataforma dirige por sí misma acceso/consentimiento/cierre de sesión |
| **Identidad** | Parte confiante de eID Mongolia | verificación con identidad electrónica |
| **Caché/cola** | Redis | lista de denegación de sesión, estado transitorio |
| **IA** | Gemini (REST sin SDK) | chat, voz, traducción |

## Seguridad

- **Row-Level Security (RLS)**: cada usuario solo ve sus propias filas; una
  comprobación al arranque verifica que sea aplicable (en producción exige un rol
  sin privilegios de superusuario).
- **Patrón BFF**: los tokens viven en cookies httpOnly, nunca en el JS del
  navegador.
- **CSRF doble**: cabecera propia + comprobación de origen.
- **Cabeceras de seguridad**: CSP, HSTS, COOP/COEP/CORP; limitación por IP.
- **Auditoría**: registro encadenado por hash y de solo anexado.

## Código compartido: lo que NO está en este repositorio

Ninguna de las capacidades anteriores está escrita aquí. Llegan desde dos capas
compartidas versionadas, para que ninguna plataforma tenga que repetir una
corrección a mano:

| Capa | Procedencia | Mecanismo |
|---|---|---|
| Núcleo del backend: autenticación, RBAC, pasarela, auditoría, proveedor OIDC, eID/SSO, IA | `public-gerege-core` (módulo Go) | dependencia en `go.mod` |
| Capa de frontend: `lib/**`, `components/**`, la lógica de **158 rutas BFF** | `@gerege/ui-core` (paquete npm) | dependencia en `package.json` |

Por eso el directorio `backend/` de este repositorio contiene **exactamente un
archivo Go**:

```
backend/
├── cmd/api/main.go        # ~30 líneas: arrancar el núcleo y añadir tus rutas
├── deploy/                # Dockerfile, inicialización de la BD
└── .env.example           # plantilla de configuración
```

```go
func main() {
    server.ServiceName = "gerege-template"
    app, err := server.NewApp()          // ← todas las capacidades del núcleo
    // Añade aquí las rutas propias de esta aplicación:
    //   app.Router().Route("/api/xxx", xxx.Routes(app.Pool()))
    app.Run()
}
```

El frontend sigue la misma forma: `app/**/page.tsx` son **envoltorios finos**
sobre las vistas del paquete, y `app/api/**` es una reexportación de una línea
por ruta:

```ts
// src/app/api/org/[id]/route.ts
export { GET, PUT, DELETE } from '@gerege/ui-core/api/org/[id]';
export const dynamic = 'force-dynamic';
```

!!! note "Por qué se mantienen los envoltorios de ruta"
    Los 158 archivos podrían reducirse a un único `[...path]`. Pero el listado de
    rutas es una **lista de permitidos de seguridad**: define a qué rutas del
    backend puede llegar el navegador. Un catch-all lo destruiría y abriría un
    proxy a todas las rutas. El envoltorio es un precio deliberado.

Lo que sí posee la plataforma: `brand.config.ts` (nombre · dominio · colores ·
URL de documentación), `components/landing/**` (texto de marketing),
`app/globals.css` (tokens de color de marca), `deploy/**` y `.github/**`.

Dos barreras de CI impiden que la duplicación regrese: `check-brand` (la
compilación falla si aparece un nombre de plataforma fuera de
`brand.config.ts`) y `check-routes` (toda ruta del paquete necesita un
envoltorio; sin él, un endpoint nuevo **desaparecería en silencio**).
