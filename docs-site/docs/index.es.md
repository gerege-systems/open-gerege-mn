# Gerege Template Platform V3.0

> **La base para construir servicios digitales**: una pila completa, lista para
> producción y endurecida en seguridad, sobre la que levantar cualquier servicio
> digital del sector público o privado.

**Gerege Template Platform V3.0** es la *base para los servicios digitales
públicos y privados*. Tú construyes el valor, no la fontanería: identidad,
seguridad, IA y andamiaje de servicio vienen resueltos desde el primer día.

!!! tip "Código abierto"
    Esta plataforma es un proyecto de **código abierto**: lee el código completo,
    haz un fork y ejecútalo en tu propia organización.
    :material-github: [Ver en GitHub](https://github.com/gerege-systems/open-gerege-mn)

<div class="grid cards" markdown>

- :material-shield-key: **eID + Gerege SSO**  
  Acceso basado en la identidad electrónica (eID) + proveedor SSO OpenID Connect
  (provider en Go integrado). Las aplicaciones se conectan con un solo toque.

- :material-layers: **Arquitectura limpia**  
  Backend en Go (chi · net/http · pgx, sin ORM) + frontend Next.js 16 (BFF).
  Capas nítidas, fáciles de extender.

- :material-package-variant: **Código compartido**  
  El núcleo del backend llega vía `go.mod` y la capa de frontend vía un paquete
  npm. Este repositorio solo posee su marca, sus textos de portada y sus rutas.

- :material-translate: **Mongol + las seis lenguas de la ONU**  
  Árabe · chino · inglés · francés · ruso · español: traducciones totalmente
  integradas, con RTL automático para el árabe.

- :material-account-network: **Proxy de servicios eID**  
  Las aplicaciones registradas llaman a los servicios eID del SSO mediante
  autorización (proxy): nunca necesitan custodiar credenciales eID.

- :material-tune: **Pasarela de API gestionada por administración**  
  Catálogo de servicios, autorización por aplicación y telemetría, todo desde el
  sistema de administración.

</div>

## El ecosistema

La plataforma se compone de varios servicios independientes:

| Dominio | Función |
|---|---|
| **sso.gerege.mn** | Gerege SSO — proveedor OIDC + parte confiante de eID (custodia las credenciales eID) |
| **open.gerege.mn** | Aplicación de ejemplo: parte confiante de Gerege SSO (accede a través del SSO) |

Las aplicaciones (como `open.gerege.mn`) acceden a través de
**sso.gerege.mn** y llaman a los servicios eID autorizados mediante un proxy.
Solo el SSO custodia las credenciales de parte confiante que dialogan con eID
Mongolia, de modo que las aplicaciones quedan libres de esa carga de seguridad.

## Capacidades clave

- **Autenticación** — eID (QR / App2App / notificación por número de registro) + vinculación con Google + Gerege SSO (OIDC).
- **Proveedor OIDC** — construido sobre su propio código Go; las aplicaciones ofrecen «Acceder con Gerege SSO».
- **Perfil PKI de eID** — organizaciones, certificados, dispositivos, actividad.
- **Firma de documentos (PAdES)** — las aplicaciones de terceros firman mediante el relé de firma eID.
- **Proxy de servicios eID** — personal (`eid-proxy`) y de organización (`eid-org-proxy`), por separado.
- **Pasarela de API** — catálogo de servicios, autorización por aplicación, telemetría de peticiones.
- **Asistente de IA (Gemini)** — chat, voz, traducción.
- **RBAC y superadministración**, **registro de auditoría**, **endurecimiento** (RLS, CSP, HSTS, CSRF).
- **La superficie de acceso es configuración**: `AUTH_MODE` convierte la
  plataforma en un servicio de identidad (`provider`) o en consumidora de un SSO
  superior (`client`); el código no cambia.
- **Siete idiomas de serie**: la interfaz se entrega con traducciones integradas
  en mongol y en las seis lenguas oficiales de la ONU.

!!! tip "¿Por dónde empezar?"
    Para conectar tu aplicación a Gerege SSO, véase
    [Integración de una aplicación](sso-integration.md). Para obtener datos eID
    mediante el proxy, véase [Proxy de servicios eID](eid-services.md).
