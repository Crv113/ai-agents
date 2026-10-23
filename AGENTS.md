# AGENTS.md

Règles pour travailler **sur** ce dépôt (modifier ou ajouter des agents, des skills, le connecteur). Présentation, installation et utilisation : [README.md](README.md).

## Rôle

Workflow d'agents générique pour projets multi-couches (spec → architect → coder → reviewer + tester → validator) et skills de conventions par techno. Ce sont des fichiers de configuration pour un assistant de code, pas des agents à déployer.

Le cœur (`agents/`, `skills/`) est **neutre** : aucun format ni nom propre à un outil. Un connecteur par outil produit ce que l'outil attend. Seul le connecteur Claude Code existe (`connectors/claude/` + `install.sh`).

## Structure

```
agents/<nom>.md           — un agent : frontmatter neutre (name, description) + instructions
skills/<nom>/SKILL.md     — un skill au format standard Agent Skills (name, description)
connectors/claude/
  agents.conf             — champs propres à Claude Code par agent (model, disallowedTools, mcpServers…)
  skills.conf             — champs propres à Claude Code par skill (disable-model-invocation…)
  context.md              — traduction des termes neutres pour Claude Code, ajoutée aux fichiers générés
  context/<nom>.md        — complément pour un agent ou skill précis (ex. setup.md)
  prereqs.sh              — détection de Node ≥ 20 et du navigateur, bilan des prérequis
  hooks/                  — emit.sh/emit.py (événements) et settings_merge.py (fusion dans settings.json)
  build/                  — généré par install.sh (ignoré par git)
install.sh / uninstall.sh — connecteur Claude Code
docs/EVENTS.md            — contrat des événements envoyés au dashboard
docs/REFONTE.md           — historique de la refonte v1 → v2
```

## Principe de séparation

- **ai-agents** dit **comment** travailler : agents (comportement) et skills (conventions par techno).
- **Les instructions du projet** disent **quoi** respecter : sous-projets et stack, règles métier, conventions propres, index BDD, middlewares, comptes de test, SDK autorisés.

Aucune règle de domaine, aucun chemin ni nom propre à un projet dans les agents ou les skills.

## Termes neutres

Dans `agents/` et `skills/`, n'employer aucun nom propre à un outil :

| Écrire | Pas |
|---|---|
| les instructions du projet | `CLAUDE.md` |
| charger le skill `X` | l'outil `Skill` |
| lancer l'agent `X` | l'outil `Agent` |
| poser une question à l'utilisateur | `AskUserQuestion` |

La traduction se fait dans `connectors/claude/context.md`, ajouté par `install.sh` à la fin de chaque agent et skill généré, et dans `connectors/claude/context/<nom>.md` pour un élément précis. Vérification :

```bash
grep -rniE "claude|outil \`(Skill|Agent)\`|AskUserQuestion" agents skills   # doit être vide
```

**Instructions du projet** : `AGENTS.md` à la racine du projet (format cible). Pour la compatibilité v1, un projet qui n'a qu'un `CLAUDE.md` garde son bloc dans `CLAUDE.md`. Cette compatibilité est provisoire et sera retirée plus tard.

## Contrat avec les instructions du projet

Les agents, `/feature` et les hooks lisent ce bloc, écrit par `/setup`. Toute évolution du format doit être reportée dans `/setup`, les agents qui le lisent, `emit.py` et le README.

```markdown
<!-- ai-agents:start -->
## Workflow (ai-agents)
Nom du projet : <nom>                    # aussi lu par les hooks
Branche cible des PR : main              # défaut main si absent
SDK payants autorisés : aucun
Comptes de test : <identifiants de test uniquement>
| Sous-projet | Chemin | Stack | Versions | Skills |
Build (<sous-projet>) : <commande>       # « (<sous-projet>) » omis s'il n'y en a qu'un
Tests (<sous-projet>) : <commande>
Lancement (<sous-projet>) : <commande> → <URL ou port>
<!-- ai-agents:end -->
```

- Seul le contenu entre les marqueurs est modifié, jamais le reste du fichier. Le tester peut y ajouter une ligne `Lancement :` qu'il a déduite.
- En cas de doublon avec une ligne hors bloc, **le bloc fait foi**. Si le bloc existe à la fois dans `AGENTS.md` et dans `CLAUDE.md`, c'est celui d'`AGENTS.md` qui fait foi.
- En l'absence de ces lignes, les agents utilisent la section Build des skills ou déduisent les commandes des fichiers du projet.

Les documents d'une feature vont dans `.ai-agents/features/<ID>/` du projet (`status.md`, `spec.md`, `plan.md`, `review.md`, `test-report.md`). `.ai-agents/current` contient l'ID de la feature en cours (lu par les hooks).

## Règles de format

- **Agents** : le frontmatter ne contient que `name` et `description`. Tout champ propre à un outil va dans `connectors/claude/agents.conf`, à raison d'une ligne `agent.champ=valeur`. Pour une valeur structurée, utiliser du JSON sur une ligne, qui est aussi du YAML valide (voir `tester.mcpServers`).
- **Skills** : le frontmatter ne contient que `name` et `description`. La `description` dit quand charger le skill. Les champs propres à Claude Code vont dans `connectors/claude/skills.conf` : hors de Claude Code, une clé inconnue fait échouer le chargement du skill.
- **Modèles** : uniquement des alias (`sonnet`, `opus`, `haiku`…), jamais un ID daté. Prendre le modèle le moins cher qui fait correctement le travail de l'agent.
- **Sorties des agents** : chaque agent décrit ses entrées et sa sortie (fichier à écrire, puis résumé court rendu à `/feature`). Un agent ne peut pas poser de question à l'utilisateur : il rend ses questions dans son rapport.

## Versions

Aucun agent ni skill n'impose de version de langage, framework ou outil.

- **Projet existant** : les versions sont lues dans les fichiers du projet (`pom.xml`, `composer.json`, `package.json`, lockfiles…). Jamais d'upgrade sans le demander à l'utilisateur.
- **Nouveau projet** : la dernière version stable (LTS si elle existe), vérifiée en ligne, est proposée par l'architect, validée par l'utilisateur, puis notée dans les instructions du projet.

Chaque skill de techno a une section « Versions » qui dit où lire la version dans un projet, une section « Test en conditions réelles » (pour le tester) et une section « Points de cohérence » (pour le validator).

## Ajouter un agent ou un skill

- **Agent** : créer `agents/<nom>.md` avec `name` et `description`, ajouter si besoin ses champs dans `connectors/claude/agents.conf`, puis lancer `./install.sh` et redémarrer Claude Code.
- **Skill de techno** : créer `skills/<nom>/SKILL.md` avec `name`, `description` et les trois sections ci-dessus, puis lancer `./install.sh` et redémarrer Claude Code. L'architect peut le lister dans un plan pour que coder, reviewer et tester le chargent.
- **Après toute modification** d'un agent, de `agents.conf`, de `skills.conf`, de `context*.md` ou d'un skill listé dans `skills.conf` : relancer `./install.sh`.

## Connecteur Claude : règles

- `install.sh` doit rester relançable sans risque. Il sauvegarde avant de remplacer, ne supprime rien sans demander, suit un déplacement du repo, et propose `--dry-run`.
- Les hooks sont silencieux, ne bloquent jamais (sortie toujours avec le code 0) et ne font rien si le dashboard est éteint. Ils n'envoient jamais `tool_input` ni `tool_response`. Le contrat est dans `docs/EVENTS.md`.
- Tester les scripts dans une config isolée (`CLAUDE_CONFIG_DIR=<dossier jetable> ./install.sh`) avant de toucher au vrai `~/.claude`.
