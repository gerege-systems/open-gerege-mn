# Chaîne IA (Gemini)

> Une chaîne REST sans SDK : chat, voix et traduction en direct — avec des outils
> exécutés côté serveur (function calling).

## Vue d'ensemble

```
Navigateur (/me/ai, /me/translate)
   │  fetch de même origine (en-tête CSRF)
   ▼
BFF Next.js  /api/ai/{chat,stt,tts,translate}   ← valide la forme, attache le JWT
   │  serveur→serveur
   ▼
API Go  /api/v1/ai/*   (JWT + limite ~20/min)
   │
   ▼
usecases/ai ──────────► pkg/gemini ──────► API REST Gemini
   │   ▲                 (3 tentatives avec backoff sur 429/5xx/réseau)
   │   └─ functionResponse
   ▼
ToolDef.Execute()  ← s'exécute SUR LE BACKEND avec le contexte de la requête
   ├─ search_knowledge → table ai_knowledge
   └─ get_server_time  → outil de démonstration
```

!!! note "Principe clé"
    **Le modèle décide quel outil appeler ; le backend l'exécute.** Le modèle
    n'exécute jamais de code. Les outils tournent avec le contexte de la requête :
    la RLS et les délais d'expiration s'appliquent donc à tout ce qu'ils touchent.

## Flux de chat (boucle de function calling)

1. Constituer `contents` à partir de l'historique (≤ 20 tours) et de la nouvelle
   consigne. Un message vocal arrive comme partie audio base64 en ligne — Gemini
   le comprend directement, aucune étape STT distincte n'est nécessaire.
2. Appeler Gemini avec l'instruction système en couches et les déclarations
   d'outils.
3. Si la réponse contient des **appels de fonction** : exécuter chaque outil,
   ajouter le tour du modèle puis un tour `functionResponse`, et boucler (jusqu'à
   `MaxSteps`, 4 par défaut). Chaque appel exécuté est consigné comme
   `Step{Tool, Args, Result}` et renvoyé au client, afin que l'interface puisse
   montrer « ce qu'a fait l'IA ».
4. Si la réponse est du **texte** : la renvoyer.

### Sémantique des échecs

| Cas | Résultat |
|---|---|
| Défaillance transitoire de Gemini (après les 3 tentatives du client) | **Pas un 5xx** — une réponse de repli dans la langue de l'utilisateur avec `degraded: true` |
| `GEMINI_API_KEY` absente | Une vraie erreur — 500, cause journalisée |
| Outil inconnu ou en échec | Signalé au modèle sous forme `{"error": …}` — jamais exposé directement au client |

!!! tip "Ne modifiez pas ce comportement"
    Le chat doit se dégrader proprement vers la réponse de repli lors des
    défaillances transitoires de Gemini — n'en faites pas un 5xx.

## Couches de consigne

La consigne système est assemblée à chaque requête à partir de trois couches :

1. **Garde-fous inscrits en dur** — figés dans le code, jamais configurables.
2. **Périmètre** — depuis la table `ai_prompts`, modifiable par les
   administrateurs.
3. **Instructions** — également pilotées depuis la base de données.

!!! tip "Langue de réponse"
    Le frontend envoie sa langue d'interface (`mn`/`en`/`ar`/`zh`/`fr`/`ru`/`es`)
    dans le champ `lang` et l'assistant répond **uniquement** dans celle-ci — ni
    la langue saisie par l'utilisateur, ni l'historique, ni la base de
    connaissances, ni les résultats d'outils ne la remplacent (les sources en
    d'autres langues sont traduites). La réponse de repli `degraded` est
    localisée de la même façon.

!!! warning "Ne rendez jamais la couche de garde-fous configurable"
    Cette couche n'a sa place que dans le code. Seuls `scope` et `instructions`
    proviennent de la base de données.

## Ajouter un outil

```go
ai.ToolDef{
    Declaration: gemini.FunctionDeclaration{
        Name:        "my_tool",
        Description: "Quand le modèle doit appeler ceci…",
        Parameters:  map[string]any{ /* JSON Schema */ },
    },
    Execute: func(ctx context.Context, args map[string]any) (map[string]any, error) {
        // s'exécute sur le backend ; ctx porte l'identité de la requête (la RLS s'applique)
        return map[string]any{"result": "…"}, nil
    },
}
```

Enregistrez-le dans `cmd/api/server/server.go` :

```go
aiTools := append(ai.DefaultTools(), ai.KnowledgeSearchTool(aiRepo), myTool)
```

### Outils livrés

!!! tip "Recherche sémantique (RAG)"
    Le savoir de la plateforme vit dans `ai_knowledge` sous forme d'environ 58
    fragments. Les questions sont vectorisées avec Gemini et appariées par
    similarité cosinus dans pgvector : une question formulée autrement retrouve
    donc le bon fragment. Les vecteurs sont calculés automatiquement au
    démarrage ; Administration → Paramètres propose un bouton de réindexation
    manuelle.

- **`search_knowledge`** — recherche sémantique sur `ai_knowledge` : la question
  est vectorisée, les 8 meilleurs résultats pgvector sont récupérés, puis filtrés
  **relativement au meilleur** (tout ce qui se situe plus de 0,03 en dessous est
  écarté ; il en reste 2 à 4). Un seuil fixe ne convient pas ici — même des
  fragments sans rapport atteignent 0,64 de similarité dans ce corpus. Quand les
  vecteurs sont indisponibles, il se rabat sur `ILIKE`, découpe la question en
  mots et cherche les plus longs par racine. Les garde-fous de base indiquent au
  modèle de l'appeler *avant* de répondre aux questions sur la plateforme, et de
  dire « je ne sais pas » plutôt que deviner quand rien n'est trouvé. Étoffez le
  corpus en insérant des lignes — les nouvelles lignes sont vectorisées
  automatiquement.
- **`get_server_time`** — une démonstration minimale (heure d'Oulan-Bator), sans
  aucune dépendance.

!!! info "Chat public sur la page d'accueil (sans connexion)"
    Un widget flottant en bas à droite appelle `POST /public/ai/chat` sans jeton.
    Il tourne sur une instance de cas d'usage distincte, câblée uniquement avec
    l'outil de base de connaissances : il ne peut donc pas atteindre les données
    utilisateur. Environ 6 requêtes/min par IP, message ≤ 1000 caractères,
    historique ≤ 6 tours ; la consigne système reçoit un garde-fou
    « visiteur anonyme » supplémentaire. Le widget dialogue avec
    `POST /public/ai/chat/stream` (SSE), si bien que la réponse apparaît au fil de
    l'écriture. L'appui-pour-parler (maintenir le gros bouton rond) envoie un clip
    base64 d'environ 250 Ko (≈ 15 s) et **un seul** appel au modèle renvoie à la
    fois la transcription (événement `transcript`) et la réponse. Les questions
    vocales reçoivent une réponse lue phrase par phrase via
    `POST /public/ai/tts`, la parole commençant donc dès la première phrase.

## Voix

| Capacité | Point d'accès | Fonctionnement |
|---|---|---|
| Message de chat vocal | `POST /ai/chat` avec `audio` | L'audio entre directement dans le tour utilisateur comme donnée en ligne — le modèle de chat est multimodal |
| Parole vers texte | `POST /ai/stt` | Appel unique avec une consigne stricte de « transcription mot à mot » ; un texte vide signifie l'absence de parole |
| Texte vers parole | `POST /ai/tts` | Un modèle TTS distinct avec `responseModalities: ["AUDIO"]` ; le PCM brut (L16/24 kHz) est enveloppé dans un en-tête WAV pour que les navigateurs le lisent |
| Traduction en direct | `POST /ai/translate` | Texte → traduire ; audio → **deux étapes** STT puis traduction ; `speak: true` ajoute un rendu TTS (un échec TTS se dégrade en silence — le texte est tout de même renvoyé) |

L'entrée audio est filtrée par type MIME
(webm/ogg/wav/mpeg/mp3/mp4/m4a/aac/flac) et plafonnée à environ 700 Ko en base64
(~30 s d'opus), à la fois dans le BFF et dans le DTO du backend.

!!! note "Détail de la traduction en direct"
    Le micro enregistre des segments d'environ 7 s en utilisant un
    **`MediaRecorder` neuf pour chaque segment** — les fragments issus d'un
    timeslice ne portent l'en-tête du conteneur que dans le premier, et c'est ce
    qui rend chaque segment valide indépendamment. Les segments silencieux
    renvoient des champs vides et sont ignorés plutôt que remontés comme erreurs.

## Limitation de débit

`/ai/*` est limité à environ **20 requêtes par minute et par IP**. La traduction
en direct diffuse près de 8 fragments par minute : abaissez cette limite avec
précaution.

Le détail complet vit dans le dépôt :
[`backend/docs/AI_PIPELINE.md`](https://github.com/gerege-systems/public-gerege-template/blob/main/backend/docs/AI_PIPELINE.md).
