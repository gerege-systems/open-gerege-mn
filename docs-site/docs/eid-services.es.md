# Proxy de servicios eID

Las aplicaciones registradas llaman a los servicios eID de **Gerege SSO** en
nombre de sus usuarios mediante un **proxy**. El SSO identifica al usuario a
partir del sujeto del token y obtiene los datos con **sus propias** credenciales
de parte confiante de eidmongolia.mn, de modo que las aplicaciones nunca
necesitan custodiar credenciales eID.

## Dos servicios

| Servicio | Ruta pública | Endpoints |
|---|---|---|
| **`eid-proxy`** (personal) | `https://sso.gerege.mn/rp/eid/*` | `summary` · `certificates` · `devices` · `activity` |
| **`eid-org-proxy`** (organizaciones) | `https://sso.gerege.mn/rp/eid-org/*` | `organizations` · `organizations/{regNo}/signers` |

Todos son de **solo lectura** (GET). Los servicios personales y los de
organización se agrupan por separado para que el administrador pueda
gestionarlos de forma independiente.

## Llamar al proxy

```bash
GET https://sso.gerege.mn/rp/eid/summary
Authorization: Bearer <token de acceso SSO del usuario>
```

La respuesta contiene los datos eID de ese usuario (obtenidos con las
credenciales de parte confiante del SSO).

## Autorización

El servicio debe estar **concedido** a la aplicación. La concesión se expresa
como el **ámbito de servicio** (`svc:eid-proxy` / `svc:eid-org-proxy`) dentro de
los ámbitos OAuth2 permitidos del cliente: conceder el servicio a la aplicación
desde la administración añade ese ámbito.

En cada petición el SSO:

1. Inspecciona el token (RFC 7662) → `active` + `sub`.
2. Busca el cliente por el `client_id` del token y comprueba si el ámbito de
   servicio está concedido (comprueba la concesión **actual**, por lo que
   conceder o revocar surte efecto de inmediato).
3. Resuelve el usuario a partir de `sub` y obtiene los datos de eID Mongolia.

| Condición | Respuesta |
|---|---|
| Sin token / token caducado | `401` |
| Servicio no concedido a la aplicación | `403` |
| Servicio desactivado en la pasarela | `503` |
| Éxito | `200` + datos |

!!! tip "¿Cómo se concede?"
    Administración → Aplicaciones → la aplicación → marcar **eid-proxy** /
    **eid-org-proxy** → Guardar. Una aplicación sin concesión recibe un 403.
    Véase [Pasarela de API](api-gateway.md) para el detalle.

## Conmutador en caliente

Ambos servicios están registrados en el **catálogo de la pasarela de API** y
pueden **activarse o desactivarse** desde la interfaz de administración en
tiempo de ejecución (desactivado → `503`). El eID personal puede apagarse
mientras el eID de organización sigue funcionando (son independientes).
