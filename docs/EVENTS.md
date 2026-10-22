# Événements ai-agents

Contrat entre les hooks Claude Code (`connectors/claude/hooks/emit.sh`) et le futur dashboard.

## Transport

- `POST` JSON vers `AI_AGENTS_DASHBOARD_URL` (défaut `http://127.0.0.1:7337/events`), un événement par requête
- Le hook teste d'abord si le dashboard écoute (connexion de 0,2 s). S'il est éteint, il s'arrête aussitôt sans rien lire ni envoyer
- Hooks déclarés `async` : ils ne bloquent jamais Claude, n'affichent rien et sortent toujours avec le code 0
- Prérequis : `python3` dans le `PATH` (sinon le hook ne fait rien)

## Événements émis

| Événement Claude Code | Quand | Champs spécifiques |
|---|---|---|
| `SubagentStart` | un agent démarre | `agent_id`, `agent_type` |
| `SubagentStop` | un agent se termine | `agent_id`, `agent_type`, `tokens` |
| `PreToolUse` | avant un appel d'outil | `tool.name`, `tool.use_id`, `agent_id`/`agent_type` si dans un agent |
| `PostToolUse` | après un appel d'outil | idem + `tool.duration_ms` |

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
- `feature_id` : extrait de la branche (`F-YYYYMMDD-NNN`), sinon `null`
- `tool` : seulement sur les événements d'outil. **Jamais** `tool_input` ni `tool_response` (code, secrets)
- `tokens` : seulement sur `SubagentStop`, somme des `usage` du fichier de session de l'agent (`agent_transcript_path`), une fois par message. Jamais demandé aux agents
- `agent_id` / `agent_type` : `null` pour la session principale

## Limites connues

- Les tokens de la session principale (dont `/feature` et `/setup`) ne sont pas encore émis : ajouter `Stop` / `SessionEnd` avec `transcript_path` quand le dashboard en aura besoin
- Pas de file d'attente : un événement émis pendant que le dashboard est éteint est perdu
