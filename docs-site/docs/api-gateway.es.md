# Pasarela de API

La pasarela de API es un **catálogo de servicios + telemetría**, gestionado
desde el sistema de administración. Cada servicio expuesto (por ejemplo, el
proxy eID) se registra en el catálogo y se concede a las aplicaciones con
autorización individual.

## Catálogo de servicios

| Servicio | Ruta | Tipo | Autorización |
|---|---|---|---|
| **Acceso SSO** | `/oauth2` | Básico (integrado) | Automático para todas las aplicaciones |
| **`eid-sign`** | `/rp/sign` | Complementario | Concesión por aplicación |
| **`eid-proxy`** | `/rp/eid` | Complementario | Concesión por aplicación |
| **`eid-org-proxy`** | `/rp/eid-org` | Complementario | Concesión por aplicación |

!!! note "El acceso SSO no está en el catálogo"
    El acceso SSO es un servicio **básico**: se sirve automáticamente a toda
    aplicación registrada mediante los ámbitos OIDC básicos, así que no requiere
    concesión ni casilla. Por eso no aparece entre los servicios concedibles de
    la pasarela.

## Gestionar servicios (administración)

En **Administración → Pasarela → Servicios** puedes listar, crear, editar y
**activar o desactivar** servicios. Al crear un servicio se deriva
automáticamente un ámbito `svc:<nombre>` para poder concederlo a las
aplicaciones.

- El indicador **activado** surte efecto en tiempo de ejecución: la ruta del
  proxy eID comprueba si el servicio está activo y devuelve `503` cuando no lo
  está.

## Conceder un servicio a una aplicación

En **Administración → Aplicaciones → la aplicación → SERVICIOS**, concede los
servicios mediante casillas. La concesión añade `svc:<nombre>` a los ámbitos
permitidos del cliente OAuth2 de la aplicación; revocarla los quita. El efecto
es **inmediato**: el proxy comprueba la concesión actual del cliente.

```text
Aplicación «template.gerege.mn»
  ├─ Acceso SSO ............. automático (integrado)
  ├─ [x] eid-sign ........... svc:eid-sign
  ├─ [ ] eid-proxy .......... sin conceder → /rp/eid → 403
  └─ [ ] eid-org-proxy ...... sin conceder → /rp/eid-org → 403
```

## Telemetría

La pasarela registra las peticiones reales a `/api` (método, ruta, estado,
latencia) y las muestra en **Administración → Pasarela → Resumen / Registros**.

## Añadir un nuevo servicio proxy (desarrolladores)

Sigue este patrón para añadir otros servicios internos a la pasarela y
gestionarlos desde la administración:

1. Inserta una fila en `gateway_services` (migración): nombre, ruta, etiquetas.
2. Comprueba el conmutador en la ruta con `gatewayUC.ServiceEnabled(nombre)`.
3. Comprueba la concesión de `svc:<nombre>` en el middleware de OAuth.
4. Añade una ruta pública en nginx (`/rp/<nombre>/` → backend).
