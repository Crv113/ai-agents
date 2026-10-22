# Événements ai-agents

Contrat entre les hooks Claude Code (`connectors/claude/hooks/emit.sh`) et le futur dashboard.

## Transport

- `POST` JSON vers `AI_AGENTS_DASHBOARD_URL` (défaut `http://127.0.0.1:7337/events`), un événement par requête
- Le hook teste d'abord si le dashboard écoute (connexion de 0,2 s). S'il est éteint, il s'arrête aussitôt sans rien lire ni envoyer
- Hooks déclarés `async` (sauf `Stop`, voir plus bas) : ils ne bloquent jamais Claude, n'affichent rien et sortent toujours avec le code 0
- `Stop` est synchrone : en async, il pouvait être tué quand la session se termine juste après un tour, et ce tour était perdu. Sans dashboard, il sort en moins de 0,1 s
- Prérequis : `python3` dans le `PATH` (sinon le hook ne fait rien)

## Événements émis

| Événement Claude Code | Quand | Champs spécifiques |
|---|---|---|
| `SubagentStart` | un agent démarre | `agent_id`, `agent_type` |
| `SubagentStop` | un agent se termine | `agent_id`, `agent_type`, `tokens` |
| `PreToolUse` | avant un appel d'outil | `tool.name`, `tool.use_id`, `agent_id`/`agent_type` si dans un agent |
| `PostToolUse` | après un appel d'outil | idem + `tool.duration_ms` |
| `Stop` | fin d'un tour de la session principale | `tokens` du tour (agent_id `null`) |

## Format

```json
{
  "v": 1,
  "ts": "2026-10-22T18:32:45.328991+00:00",
  "event": "SubagentStop",
  "session_id": "…",
  "agent_id": "af5067d6888af88dd",
  "agent_type": "coder",
  "project": { "root": "/chemin/racine/git", "name": "compteur" },
  "branch": "feature/F-20261022-001",
  "feature_id": "F-20261022-001",
  "tool": { "name": "Edit", "use_id": "…", "duration_ms": 12 },
  "tokens": { "input": 4, "output": 679, "cache_creation": 17161, "cache_read": 15899, "model": "claude-haiku-5-5" }
}
```

- `project.root` : racine git du `cwd` de l'événement (sinon le `cwd`)
- `project.name` : ligne `Nom du projet :` du `CLAUDE.md` à la racine (écrite par `/setup`), sinon nom du dossier
- `feature_id` : contenu de `.ai-agents/current` à la racine du projet (écrit par `/feature` au démarrage, supprimé à la fin ou en pause), sinon extrait de la branche (`F-YYYYMMDD-NNN`), sinon `null`. Grâce à ce fichier, tout ce qui se passe pendant `/feature` est rattaché à la feature, y compris la spec (avant la création de la branche) ; ce qui se passe en dehors (`/setup`, discussions) ne l'est pas
- `tool` : seulement sur les événements d'outil. **Jamais** `tool_input` ni `tool_response` (code, secrets)
- `tokens` : sur `SubagentStop`, somme des `usage` du fichier de session de l'agent (`agent_transcript_path`) ; sur `Stop`, somme des `usage` du **dernier tour** de la session principale (`transcript_path`, depuis le dernier message de l'utilisateur). Un message compte une fois (sa dernière `usage`). Jamais demandé aux agents
- `agent_id` / `agent_type` : `null` pour la session principale

## Limites connues

- `.ai-agents/current` est unique par projet : deux `/feature` lancés en même temps dans le même projet se l'écraseraient
- Pas de file d'attente : un événement émis pendant que le dashboard est éteint est perdu
