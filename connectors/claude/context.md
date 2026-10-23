## Correspondances avec Claude Code

Ces instructions sont écrites en termes neutres. Dans Claude Code :

- **Instructions du projet** : `AGENTS.md` à la racine du projet **et** `CLAUDE.md` (et ses imports `@…`), déjà chargé automatiquement. Si `AGENTS.md` existe et n'est pas importé par `CLAUDE.md`, le lire explicitement. Le bloc `<!-- ai-agents:start -->` / `<!-- ai-agents:end -->` peut se trouver dans l'un ou l'autre ; s'il est dans les deux, celui d'`AGENTS.md` fait foi
- **Charger un skill** : outil `Skill` avec son nom (ex. `java-spring`)
- **Lancer un agent** : outil `Agent` avec le nom de l'agent comme type (ex. `coder`) ; plusieurs appels dans un même message pour les lancer en parallèle
- **Poser une question à l'utilisateur** : outil `AskUserQuestion`, uniquement depuis la session principale (un agent lancé ne peut pas : il rend ses questions dans son rapport)
