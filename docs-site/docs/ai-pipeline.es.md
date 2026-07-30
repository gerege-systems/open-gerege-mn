# Canal de IA (Gemini)

> Un canal REST sin SDK: chat, voz y traducción en directo, con herramientas que
> se ejecutan en el servidor (function calling).

## Visión general

```
Navegador (/me/ai, /me/translate)
   │  fetch del mismo origen (cabecera CSRF)
   ▼
BFF de Next.js  /api/ai/{chat,stt,tts,translate}   ← valida la forma, adjunta el JWT
   │  servidor→servidor
   ▼
API Go  /api/v1/ai/*   (JWT + límite ~20/min)
   │
   ▼
usecases/ai ──────────► pkg/gemini ──────► API REST de Gemini
   │   ▲                 (3 reintentos con backoff ante 429/5xx/red)
   │   └─ functionResponse
   ▼
ToolDef.Execute()  ← se ejecuta EN EL BACKEND con el contexto de la petición
   ├─ search_knowledge → tabla ai_knowledge
   └─ get_server_time  → herramienta de demostración
```

!!! note "Principio clave"
    **El modelo decide qué herramienta llamar; el backend la ejecuta.** El modelo
    nunca ejecuta código. Las herramientas corren con el contexto de la petición,
    así que la RLS y los tiempos de espera se aplican a todo lo que tocan.

## Flujo de chat (bucle de function calling)

1. Construir `contents` a partir del historial (≤ 20 turnos) más la nueva
   consigna. Un mensaje de voz llega como parte de audio base64 en línea: Gemini
   lo entiende directamente, así que no hace falta un paso STT aparte.
2. Llamar a Gemini con la instrucción de sistema por capas y las declaraciones de
   herramientas.
3. Si la respuesta contiene **llamadas a función**: ejecutar cada herramienta,
   añadir el turno del modelo más un turno `functionResponse` y repetir (hasta
   `MaxSteps`, 4 por defecto). Cada llamada ejecutada se registra como
   `Step{Tool, Args, Result}` y se devuelve al cliente, de modo que la interfaz
   puede mostrar «qué hizo la IA».
4. Si la respuesta es **texto**: devolverlo.

### Semántica de los fallos

| Caso | Resultado |
|---|---|
| Fallo transitorio de Gemini (tras los 3 reintentos del cliente) | **No es un 5xx**: una respuesta de reserva en el idioma del usuario con `degraded: true` |
| Falta `GEMINI_API_KEY` | Un error real: 500, con la causa registrada |
| Herramienta desconocida o fallida | Se comunica al modelo como `{"error": …}`; nunca llega directamente al cliente |

!!! tip "No cambies este comportamiento"
    El chat debe degradarse con elegancia a la respuesta de reserva ante fallos
    transitorios de Gemini: no lo conviertas en un 5xx.

## Capas de la consigna

La consigna de sistema se ensambla en cada petición a partir de tres capas:

1. **Salvaguardas fijadas en el código**: inmutables, nunca configurables.
2. **Ámbito**: de la tabla `ai_prompts`, editable por los administradores.
3. **Instrucciones**: también configuradas desde la base de datos.

!!! tip "Idioma de respuesta"
    El frontend envía su idioma de interfaz
    (`mn`/`en`/`ar`/`zh`/`fr`/`ru`/`es`) en el campo `lang` y el asistente
    responde **solo** en él: ni el idioma en que escribió la persona, ni el
    historial, ni la base de conocimiento, ni los resultados de las herramientas
    lo anulan (las fuentes en otros idiomas se traducen). La respuesta de reserva
    `degraded` se localiza igual.

!!! warning "Nunca hagas configurable la capa de salvaguardas"
    Esa capa pertenece únicamente al código. Solo `scope` e `instructions` se
    gobiernan desde la base de datos.

## Añadir una herramienta

```go
ai.ToolDef{
    Declaration: gemini.FunctionDeclaration{
        Name:        "my_tool",
        Description: "Cuándo debe llamarla el modelo…",
        Parameters:  map[string]any{ /* JSON Schema */ },
    },
    Execute: func(ctx context.Context, args map[string]any) (map[string]any, error) {
        // se ejecuta en el backend; ctx lleva la identidad de la petición (se aplica RLS)
        return map[string]any{"result": "…"}, nil
    },
}
```

Regístrala en `cmd/api/server/server.go`:

```go
aiTools := append(ai.DefaultTools(), ai.KnowledgeSearchTool(aiRepo), myTool)
```

### Herramientas incluidas

!!! tip "Búsqueda semántica (RAG)"
    El conocimiento de la plataforma vive en `ai_knowledge` como unos 58
    fragmentos. Las preguntas se vectorizan con Gemini y se emparejan por
    similitud del coseno en pgvector, de modo que una pregunta formulada de otra
    manera encuentra igualmente el fragmento correcto. Los vectores se calculan
    automáticamente al arrancar; Administración → Ajustes ofrece un botón de
    reindexación manual.

- **`search_knowledge`**: búsqueda semántica sobre `ai_knowledge`. La pregunta se
  vectoriza, se recuperan los 8 mejores resultados de pgvector y se filtran
  **respecto al mejor** (se descarta todo lo que quede más de 0,03 por debajo;
  quedan de 2 a 4). Aquí un umbral fijo no funciona: incluso fragmentos sin
  relación alcanzan 0,64 de similitud en este corpus. Cuando los vectores no
  están disponibles, recurre a `ILIKE`, divide la pregunta en palabras y busca
  las más largas por raíz. Las salvaguardas de base indican al modelo que la
  llame *antes* de responder preguntas sobre la plataforma y que diga «no lo sé»
  en lugar de adivinar cuando no encuentra nada. Amplía el corpus insertando
  filas: las nuevas se vectorizan automáticamente.
- **`get_server_time`**: una demostración mínima (hora de Ulán Bator), sin
  dependencias.

!!! info "Chat público en la portada (sin acceso)"
    Un widget flotante en la esquina inferior derecha llama a
    `POST /public/ai/chat` sin token. Se ejecuta en una instancia de caso de uso
    aparte, cableada solo con la herramienta de base de conocimiento, así que no
    puede alcanzar datos de usuario. Unas 6 peticiones/min por IP, mensaje ≤ 1000
    caracteres, historial ≤ 6 turnos; la consigna de sistema recibe una
    salvaguarda adicional de «visitante anónimo». El widget habla con
    `POST /public/ai/chat/stream` (SSE), de modo que la respuesta aparece según
    se escribe. Pulsar para hablar (mantener el botón redondo grande) envía un
    clip base64 de unos 250 KB (≈ 15 s) y **una sola** llamada al modelo devuelve
    tanto la transcripción (evento `transcript`) como la respuesta. Las preguntas
    por voz se contestan en voz alta frase a frase mediante
    `POST /public/ai/tts`, así que el habla comienza tras la primera frase.

## Voz

| Capacidad | Endpoint | Cómo funciona |
|---|---|---|
| Mensaje de chat por voz | `POST /ai/chat` con `audio` | El audio entra directamente en el turno del usuario como dato en línea: el modelo de chat es multimodal |
| Voz a texto | `POST /ai/stt` | Llamada única con una instrucción estricta de «transcribe literalmente»; un texto vacío significa que no hubo habla |
| Texto a voz | `POST /ai/tts` | Un modelo TTS aparte con `responseModalities: ["AUDIO"]`; el PCM en bruto (L16/24 kHz) se envuelve en una cabecera WAV para que los navegadores lo reproduzcan |
| Traducción en directo | `POST /ai/translate` | Texto → traducir; audio → **dos pasos**, STT y luego traducción; `speak: true` añade una síntesis TTS (si el TTS falla, se degrada en silencio: el texto igualmente se devuelve) |

La entrada de audio se filtra por tipo MIME
(webm/ogg/wav/mpeg/mp3/mp4/m4a/aac/flac) y se limita a unos 700 KB en base64
(~30 s de opus), tanto en el BFF como en el DTO del backend.

!!! note "Detalle de la traducción en directo"
    El micrófono graba segmentos de unos 7 s usando un **`MediaRecorder` nuevo
    por segmento**: los fragmentos de un timeslice solo llevan la cabecera del
    contenedor en el primero, y eso es lo que hace que cada segmento sea válido
    por separado. Los segmentos en silencio devuelven campos vacíos y se
    descartan en lugar de elevarse como errores.

## Limitación de tasa

`/ai/*` está limitado a unas **20 peticiones por minuto y por IP**. La traducción
en directo emite cerca de 8 fragmentos por minuto, así que baja ese límite con
cuidado.

El detalle completo está en el repositorio:
[`backend/docs/AI_PIPELINE.md`](https://github.com/gerege-systems/public-gerege-template/blob/main/backend/docs/AI_PIPELINE.md).
