# Inicio rápido

> Del clon a un acceso con eID sobre la pila completa en unos cinco minutos.

## Requisitos

| Herramienta | Versión | Nota |
|---|---|---|
| Go | 1.26+ | solo si ejecutas el backend directamente |
| Node.js | 20+ | solo si ejecutas el frontend directamente |
| Docker + Compose | reciente | **recomendado**: toda la pila con un comando |
| PostgreSQL / Redis | 15+ / 7+ | no hace falta si usas Docker |

## 1. La vía más rápida: Docker Compose

```bash
git clone https://github.com/gerege-systems/public-gerege-template.git
cd public-gerege-template
docker compose up -d --build
```

Esto levanta `db` · `redis` · `migrate` (de un solo uso) · `api` · `web`.
Después abre **<http://localhost:3000>**.

!!! note "Las migraciones se aplican solas"
    El servicio `migrate` se ejecuta en cada `up` y omite las migraciones ya
    aplicadas, así que volver a lanzarlo es seguro (idempotente).

## 2. Ejecutarlo a mano (desarrollo)

=== "Backend"

    ```bash
    cd backend
    cp .env.example .env
    # define JWT_SECRET (≥32 caracteres), la BD, Redis y tus credenciales EID_*
    go run ./cmd/api          # → http://localhost:8080
    ```

=== "Frontend"

    ```bash
    cd frontend
    cp .env.example .env.local     # BACKEND_URL=http://localhost:8080
    npm install
    npm run dev                    # → http://localhost:3000
    ```

## 3. Acceder

Elige **Acceder con eID** en la portada y usa cualquiera de las tres vías:

- **Código QR**: escanea con la aplicación móvil eID el QR del escritorio.
- **App2App**: salta directamente a la aplicación eID en el mismo teléfono.
- **Número de registro**: introdúcelo y llegará una notificación a la aplicación.

La vinculación con Google solo aparece cuando sus credenciales están
configuradas.

!!! tip "Probarlo sin credenciales eID"
    El acceso no funcionará mientras `EID_*` esté sin definir. Si solo quieres
    inspeccionar la interfaz y la arquitectura, las pruebas unitarias del backend
    (`go test ./...`) recorren los flujos con un doble FakeEID.

## 4. Verificar

```bash
cd backend && go test ./...     # pruebas unitarias (mocks, rápidas)
cd frontend && npm run build    # build + lint + comprobación de tipos (como en CI)
```

Reproduce localmente todas las barreras de CI:

```bash
cd backend && make pre-push     # lint + pruebas + deriva de swag + build
```

## Siguientes pasos

<div class="grid cards" markdown>

- :material-layers: **[Arquitectura](architecture.md)**: capas y flujo de dependencias
- :material-shield-key: **[Autenticación](authentication.md)**: flujos eID + SSO
- :material-connection: **[Integración de una aplicación](sso-integration.md)**: convierte tu aplicación en RP
- :material-cog: **[Configuración](configuration.md)**: referencia de variables de entorno

</div>
