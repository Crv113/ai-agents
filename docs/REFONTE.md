# Refonte d'ai-agents — feuille de route

Refonte du workflow d'agents pour Claude Code (spec → architect → coder → reviewer → validator + skills par techno).

État de départ (tag `v1`) : intégration dans chaque projet via un clone imbriqué + symlink `.claude → ai-agents/.claude`.

## Méthode de travail

- Une phase à la fois : plan (plan mode) → validation → implémentation → vérification → commit. Jamais plusieurs phases d'un coup.
- Les formats exacts (agents, skills, hooks, settings) sont vérifiés dans la doc officielle Claude Code avant d'écrire.
- Rien de destructif sans confirmation explicite.

## Principes

- **Cœur LLM-agnostique** : `AGENTS.md` neutre (`CLAUDE.md` contient juste `@AGENTS.md`), skills au format standard `SKILL.md`, corps des agents sans frontmatter spécifique. Un « connecteur Claude » produit ce que Claude Code attend. Seul le connecteur Claude est codé pour l'instant.
- **Rien de spécifique à un projet** dans les agents et skills. Le « comment » vient des skills ; les règles du projet viennent du `CLAUDE.md` du projet.
- **Versions** : aucun agent ni skill n'impose de version (retirer « JDA 5 » de java-jda, généraliser l'approche de java-spring).
  - Projet existant → versions lues dans les fichiers du projet, jamais d'upgrade sans demander.
  - Nouveau projet → dernière version stable (LTS si elle existe), vérifiée en ligne, proposée par l'architect, validée par l'utilisateur, notée dans le `CLAUDE.md` du projet.

## Rôles

- **`/feature`** (skill, remplace l'agent orchestrator ; tourne dans la session principale car un subagent ne peut pas poser de questions à l'utilisateur — `AskUserQuestion` lui est retiré ; il peut en revanche lancer d'autres subagents depuis peu, ce n'est donc plus une raison) : ID de feature, enchaîne les agents, s'arrête pour faire valider la spec puis le plan, gère les allers-retours, propose la PR vers la branche définie dans le `CLAUDE.md` du projet (défaut `main` ; aujourd'hui `orchestrator.md` dit `--base dev` alors que les PR vont vers `main`). Ne code jamais.
- **spec** : objectif, périmètre, données, interfaces, règles métier, critères d'acceptation, questions ouvertes auxquelles l'utilisateur répond avant la suite.
- **architect** : explore l'existant, plan fichier par fichier, ordre et parallélisme, skills requis, relève les versions, crée la branche de feature.
- **coder** : implémente sa partie dans le périmètre, écrit les tests, lance build + tests et corrige jusqu'au vert.
- **reviewer** : modèle fort (alias, pas d'ID figé ; actuellement Haiku 4.5, obsolète). Note sur 10 conservée, avec grille explicite (conventions, nommage, structure, tests, perf, sécurité, debug oublié). Diff sur la même branche cible que les PR. Passage : build OK + tests verts + note ≥ 7.
- **tester** (nouveau) : après le coder, en parallèle du reviewer. Démarre l'appli, déroule les critères d'acceptation en conditions réelles (navigateur via un MCP type Playwright pour un front ; autre stratégie selon le skill, ex. handlers pour un bot), vérifie console / états vides / erreurs / mobile, écrit ou complète des tests E2E, rapport par critère. Privilégie la lecture de page aux captures (tokens). Détecte seul comment lancer l'appli, ne demande que l'indevinable, l'écrit dans le `CLAUDE.md` du projet, signale « non testé » au lieu de bloquer.
- **validator** : générique, déduit ses vérifications du `CLAUDE.md` du projet et des skills chargés. Liste les actions manuelles (env, migrations…).
- **`/setup`** (nouveau skill) : lancé une fois par projet. Analyse stack, versions, commandes build/test/lancement ; demande le reste (branche cible des PR, comptes de test, SDK payants autorisés, nom du projet) ; génère ou complète le `CLAUDE.md` du projet.

## Distribution

- Un seul clone d'ai-agents, où l'utilisateur veut (aucun chemin en dur). Plus de clone dans les projets.
- **`./install.sh`** (= connecteur Claude) : détecte son propre emplacement, crée les symlinks `~/.claude/agents` et `~/.claude/skills` vers le repo, fusionne les hooks dans `~/.claude/settings.json` sans l'écraser, vérifie l'existant, sauvegarde avant modification, ne supprime rien sans demander, relançable sans risque (détecte un déplacement du dossier).
- **`./uninstall.sh`** : retire tout, restaure l'état précédent.
- Passage en plugin Claude Code : option pour plus tard.

## Observabilité (prépare le futur dashboard)

- Hooks async et silencieux (`SubagentStart`, `SubagentStop`, `PreToolUse`, `PostToolUse` : ils fournissent `agent_id` et `agent_type`) : n'affichent rien, n'échouent jamais, ne font rien si le dashboard est éteint.
- Chaque événement porte : projet (racine git du cwd, nom depuis le `CLAUDE.md` du projet, sinon nom du dossier), `session_id`, `agent_id` / `agent_type`, branche / feature. Tokens lus dans les fichiers de session (`agent_transcript_path`), jamais demandés aux agents.
- Dashboard (projet ultérieur, dans `dashboard/` du repo, lancé par `./dashboard.sh`) : Three.js, agents en 3D (salle de pause → bureau quand actifs, tokens affichés sur le bureau), un univers par projet, tokens / durée / agents par feature.

## Phases

- [x] **Phase 0** : tag `v1`, branche `refonte`, ce document.
- [x] **Phase 1** : structure neutre (`AGENTS.md`, agents, skills, règle des versions) + `install.sh` / `uninstall.sh`.
- [x] **Phase 2** : flow (`/feature`, validations humaines, coder build + tests, reviewer grille + modèle, branche des PR).
- [x] **Phase 3** : tester + validator générique.
- [ ] **Phase 4** : `/setup`.
- [ ] **Phase 5** : hooks d'événements.
- [ ] **Plus tard** : dashboard.
