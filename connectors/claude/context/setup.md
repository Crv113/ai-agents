## Étapes propres à Claude Code

- **Fichier d'instructions propre à l'outil** : `CLAUDE.md` à la racine du projet
- **Lien avec `AGENTS.md`** : si le bloc est écrit dans `AGENTS.md`, Claude Code doit le charger. Si `CLAUDE.md` existe sans ligne `@AGENTS.md`, proposer d'ajouter `@AGENTS.md` en première ligne (rien d'autre n'est modifié). S'il n'existe pas, le créer avec cette seule ligne. Toujours après accord
- **Ancienne installation (v1)** : si `.claude` à la racine est un **lien symbolique** vers un dossier `ai-agents/.claude`, le signaler (les agents du projet masquent ceux installés globalement) et proposer de **retirer le lien uniquement** (`rm .claude`, jamais sa cible). Ne le faire qu'après accord explicite
