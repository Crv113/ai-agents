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

{projet}/CLAUDE.md  → règles du projet (quoi respecter)
  - liste des sous-projets et leur stack (avec versions)
  - règles métier spécifiques au domaine
  - conventions de code propres au projet
  - index BDD, middlewares custom, composants existants
  - autorisations SDK externes (si applicable)
```

Les agents lisent le `CLAUDE.md` du projet pour tout ce qui est propre au projet. Aucune règle de domaine ni aucun chemin propre à un projet dans les agents ou les skills.

### Ce que le workflow lit dans le CLAUDE.md du projet

```markdown
Branche cible des PR : main          # défaut main si absent
Build : <commande>                   # par sous-projet si besoin
Tests : <commande>
```

Ces lignes seront générées par `/setup` (phase 4). En leur absence, les agents utilisent la section Build des skills ou déduisent les commandes des fichiers du projet.

## Utilisation

```
/feature <demande>     → lance le cycle complet d'une feature transversale
/feature <ID>          → reprend une feature en cours (ex. F-20261022-001)
```

Cycle : spec → **validation utilisateur** → architect (crée la branche) → **validation utilisateur** → coder (×N couches, build + tests) → commit → reviewer (build + tests + note ≥ 7, 3 tours max) → validator → synthèse → PR vers la branche cible après accord.

`/feature` tourne dans la session principale : c'est la seule qui peut poser des questions à l'utilisateur (un subagent n'y a pas accès). Il ne code jamais.

Les documents de la feature sont dans le projet, sous `.ai-agents/features/<ID>/` (`status.md`, `spec.md`, `plan.md`, `review.md`), exclus de git localement via `.git/info/exclude`.

Pour une modification isolée, lancer directement `coder` ou `architect`.

## Structure

```
agents/<nom>.md           — un agent : frontmatter neutre (name, description) + instructions
skills/<nom>/SKILL.md     — un skill au format standard Agent Skills (name, description)
connectors/claude/
  agents.conf             — champs propres à Claude Code par agent (model, disallowedTools…)
  skills.conf             — champs propres à Claude Code par skill (disable-model-invocation…)
  build/                  — généré par install.sh (ignoré par git)
install.sh / uninstall.sh — connecteur Claude Code
docs/REFONTE.md           — feuille de route
```

## Règles de format

- **Agents** : le frontmatter ne contient que `name` et `description`. Tout champ propre à un outil (ex. `model`) va dans le connecteur (`connectors/claude/agents.conf`, une ligne `agent.champ=valeur`).
- **Skills** : frontmatter `name` + `description` uniquement. La `description` dit quand charger le skill. Les champs propres à Claude Code (`disable-model-invocation`, `argument-hint`…) vont dans `connectors/claude/skills.conf` : hors de Claude Code, une clé inconnue fait échouer le chargement du skill.
- **Modèles** : uniquement des alias (`sonnet`, `opus`, `haiku`…), jamais un ID daté. Choisir le modèle le moins cher qui fait correctement le travail de l'agent.

## Versions

Aucun agent ni skill n'impose de version de langage, framework ou outil.

- **Projet existant** : les versions sont lues dans les fichiers du projet (`pom.xml`, `composer.json`, `package.json`, lockfiles…). On écrit du code compatible avec ces versions. Jamais d'upgrade sans le demander à l'utilisateur.
- **Nouveau projet** : dernière version stable (LTS si elle existe), vérifiée en ligne au moment du choix, proposée par l'architect, validée par l'utilisateur, puis notée dans le `CLAUDE.md` du projet.

Chaque skill indique où trouver la version dans un projet (section « Versions »).

## Installation (Claude Code)

Un seul clone, où l'on veut. Depuis le clone :

```bash
./install.sh            # crée les liens dans ~/.claude/agents et ~/.claude/skills
./install.sh --dry-run  # montre ce qui serait fait
./uninstall.sh          # retire tout et restaure l'état précédent
```

`install.sh` génère les agents au format Claude Code dans `connectors/claude/build/agents/`, puis crée un lien par agent (`~/.claude/agents/<nom>.md`) et par skill (`~/.claude/skills/<nom>`). Il sauvegarde ce qu'il remplace, demande avant toute suppression, et peut être relancé sans risque, y compris après un déplacement du clone. Les skills qui ont des champs dans `skills.conf` sont générés dans `connectors/claude/build/skills/`, les autres sont liés directement. **Relancer `install.sh` après avoir modifié un agent, `agents.conf`, `skills.conf` ou un skill listé dans `skills.conf`** (pas besoin pour les autres skills). Redémarrer Claude Code ensuite.

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
