# AGENTS.md

Instructions pour travailler sur ce dépôt.

## Rôle

Workflow d'agents générique pour projets multi-couches (spec → architect → coder → reviewer → validator) et skills de conventions par techno. Ce ne sont pas des agents à déployer : ce sont des fichiers de configuration pour un assistant de code.

Le cœur est neutre (aucun format propre à un outil). Un connecteur par outil produit ce que l'outil attend. Seul le connecteur Claude Code existe (`install.sh`).

Feuille de route de la refonte : `docs/REFONTE.md`.

## Principe de séparation

```
ai-agents/          → workflow (comment travailler)
  agents/           → comportement des agents
  skills/           → conventions par langage/framework

{projet}/AGENTS.md  → instructions du projet (quoi respecter)
  - liste des sous-projets et leur stack (avec versions)
  - règles métier spécifiques au domaine
  - conventions de code propres au projet
  - index BDD, middlewares custom, composants existants
  - autorisations SDK externes (si applicable)
```

Les agents lisent les **instructions du projet** pour tout ce qui est propre au projet. Aucune règle de domaine ni aucun chemin propre à un projet dans les agents ou les skills.

### Termes neutres

Les agents et skills n'emploient aucun nom propre à un outil. Ils disent « les instructions du projet », « charger le skill X », « lancer l'agent X », « poser une question à l'utilisateur ». Le connecteur traduit ces termes pour l'outil : `connectors/claude/context.md` est ajouté par `install.sh` à la fin de chaque agent et skill généré (`connectors/claude/context/<nom>.md` en complément pour un élément précis, ex. `/setup`).

Instructions du projet :
- **Format cible** : `AGENTS.md` à la racine du projet (standard lu par la plupart des outils). Côté Claude Code, `CLAUDE.md` contient `@AGENTS.md` (ajouté par `/setup` après accord)
- **Compatibilité v1 (provisoire)** : un projet qui n'a qu'un `CLAUDE.md` garde son bloc dans `CLAUDE.md`. À retirer plus tard, quand tous les projets seront passés à `AGENTS.md`

### Ce que le workflow lit dans les instructions du projet

```markdown
<!-- ai-agents:start -->
## Workflow (ai-agents)
Nom du projet : <nom>                    # utilisé aussi par les hooks d'événements
Branche cible des PR : main              # défaut main si absent
SDK payants autorisés : aucun
Comptes de test : <identifiants de test uniquement>
| Sous-projet | Chemin | Stack | Versions | Skills |
Build (<sous-projet>) : <commande>       # « (<sous-projet>) » omis s'il n'y en a qu'un
Tests (<sous-projet>) : <commande>
Lancement (<sous-projet>) : <commande> → <URL ou port>
<!-- ai-agents:end -->
```

Ce bloc est écrit par `/setup` (une fois par projet, relançable) : seul le contenu entre les marqueurs est modifié, le reste du fichier n'est jamais touché. Le tester peut y ajouter une ligne `Lancement :` qu'il a déduite. **En cas de doublon avec une ligne hors bloc, le bloc fait foi.** En l'absence de ces lignes, les agents utilisent la section Build des skills ou déduisent les commandes des fichiers du projet.

```
/setup                 → détecte stack, versions, commandes ; pose les questions restantes ; écrit le bloc
```

## Utilisation

```
/feature <demande>     → lance le cycle complet d'une feature transversale
/feature <ID>          → reprend une feature en cours (ex. F-20261022-001)
```

Cycle : spec → **validation utilisateur** → architect (crée la branche) → **validation utilisateur** → coder (×N couches, build + tests) → commit → reviewer (build + tests + note ≥ 7) **en parallèle de** tester (appli lancée, critères d'acceptation vérifiés en vrai), 3 tours max → validator → synthèse → PR vers la branche cible après accord.

Le tester lance son propre navigateur (Playwright MCP, via `npx`, défini dans `connectors/claude/agents.conf`). Il lui faut Node ≥ 20 et un navigateur : `install.sh` les trouve tout seul (voir « Prérequis »). Sans navigateur, les critères d'interface passent en « non testé ».

`/feature` tourne dans la session principale : c'est la seule qui peut poser des questions à l'utilisateur (un subagent n'y a pas accès). Il ne code jamais.

Les documents de la feature sont dans le projet, sous `.ai-agents/features/<ID>/` (`status.md`, `spec.md`, `plan.md`, `review.md`, `test-report.md`), exclus de git localement via `.git/info/exclude`.

Pour une modification isolée, lancer directement `coder` ou `architect`.

## Structure

```
agents/<nom>.md           — un agent : frontmatter neutre (name, description) + instructions
skills/<nom>/SKILL.md     — un skill au format standard Agent Skills (name, description)
connectors/claude/
  agents.conf             — champs propres à Claude Code par agent (model, disallowedTools…)
  skills.conf             — champs propres à Claude Code par skill (disable-model-invocation…)
  context.md              — traduction des termes neutres pour Claude Code, ajoutée aux fichiers générés
  context/<nom>.md        — complément pour un agent ou skill précis (ex. setup.md)
  build/                  — généré par install.sh (ignoré par git)
  hooks/                  — emit.sh/emit.py (événements) et settings_merge.py (fusion dans settings.json)
  prereqs.sh              — détection de Node ≥ 20 et du navigateur, bilan des prérequis
install.sh / uninstall.sh — connecteur Claude Code
docs/REFONTE.md           — feuille de route
docs/EVENTS.md            — format des événements envoyés au dashboard
```

## Règles de format

- **Agents** : le frontmatter ne contient que `name` et `description`. Tout champ propre à un outil (ex. `model`) va dans le connecteur (`connectors/claude/agents.conf`, une ligne `agent.champ=valeur`).
- **Skills** : frontmatter `name` + `description` uniquement. La `description` dit quand charger le skill. Les champs propres à Claude Code (`disable-model-invocation`, `argument-hint`…) vont dans `connectors/claude/skills.conf` : hors de Claude Code, une clé inconnue fait échouer le chargement du skill.
- **Modèles** : uniquement des alias (`sonnet`, `opus`, `haiku`…), jamais un ID daté. Choisir le modèle le moins cher qui fait correctement le travail de l'agent.

## Versions

Aucun agent ni skill n'impose de version de langage, framework ou outil.

- **Projet existant** : les versions sont lues dans les fichiers du projet (`pom.xml`, `composer.json`, `package.json`, lockfiles…). On écrit du code compatible avec ces versions. Jamais d'upgrade sans le demander à l'utilisateur.
- **Nouveau projet** : dernière version stable (LTS si elle existe), vérifiée en ligne au moment du choix, proposée par l'architect, validée par l'utilisateur, puis notée dans les instructions du projet.

Chaque skill indique où trouver la version dans un projet (section « Versions »).

## Installation (Claude Code)

Un seul clone, où l'on veut. Depuis le clone :

```bash
./install.sh            # crée les liens dans ~/.claude/agents et ~/.claude/skills
./install.sh --dry-run  # montre ce qui serait fait
./uninstall.sh          # retire tout et restaure l'état précédent
```

`install.sh` génère les agents au format Claude Code dans `connectors/claude/build/agents/`, puis crée un lien par agent (`~/.claude/agents/<nom>.md`) et par skill (`~/.claude/skills/<nom>`). Il sauvegarde ce qu'il remplace, demande avant toute suppression, et peut être relancé sans risque, y compris après un déplacement du clone. Il ajoute aussi dans `~/.claude/settings.json` des **hooks d'événements** (`SubagentStart`, `SubagentStop`, `PreToolUse`, `PostToolUse`, `Stop`) pour le futur dashboard : asynchrones, silencieux, sans effet si le dashboard est éteint (format : `docs/EVENTS.md`). Le fichier est sauvegardé avant modification, seules nos entrées sont ajoutées, et `uninstall.sh` ne retire qu'elles. `./install.sh --no-hooks` saute cette étape ; sans `python3`, elle est ignorée.

Les skills qui ont des champs dans `skills.conf` sont générés dans `connectors/claude/build/skills/`, les autres sont liés directement. **Relancer `install.sh` après avoir modifié un agent, `agents.conf`, `skills.conf` ou un skill listé dans `skills.conf`** (pas besoin pour les autres skills). Redémarrer Claude Code ensuite.

## Prérequis

Seul **Mac, Linux ou WSL avec git** est indispensable. Le reste active une fonction précise ; s'il manque, le workflow tourne quand même. `install.sh` affiche un bilan à la fin.

| Prérequis | Sert à | Sans lui | Détection par `install.sh` |
|---|---|---|---|
| Node ≥ 20 | navigateur du tester | critères d'interface « non testé » | Node du `PATH`, sinon le plus récent de nvm, fnm, volta, asdf ou Homebrew, utilisé pour le tester uniquement (le Node par défaut n'est pas modifié) |
| Google Chrome | navigateur du tester | Chromium de Playwright | propose de télécharger Chromium (~150 Mo, après accord) |
| python3 | hooks du dashboard | hooks inactifs | — |
| `gh` connecté | PR créée par `/feature` | PR à créer à la main | — |

Après l'installation ou la mise à jour de Node ou de Chrome : relancer `./install.sh`.

## Migration depuis la v1

Avant, chaque projet contenait un clone d'ai-agents et un lien `.claude → ai-agents/.claude`. Les agents d'un projet passent avant ceux de `~/.claude` : il faut donc retirer cet ancien lien, à la main, dans chaque projet :

```bash
ls -la {projet}/.claude        # vérifier que c'est bien le lien vers ai-agents/.claude
rm {projet}/.claude            # supprime le lien seulement, pas sa cible
```

Le clone imbriqué `{projet}/ai-agents` peut ensuite être supprimé s'il n'est plus utilisé.

## Ajouter un agent ou un skill

- Agent : créer `agents/<nom>.md` avec `name` et `description`, ajouter si besoin ses champs Claude dans `connectors/claude/agents.conf`, relancer `./install.sh`.
- Skill : créer `skills/<nom>/SKILL.md` avec `name` et `description` (dire quand le charger), relancer `./install.sh`. L'architect peut le lister dans un plan pour que coder et reviewer le chargent.
