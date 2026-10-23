# ai-agents

Une équipe d'agents pour développer une feature de bout en bout avec un assistant de code (Claude Code aujourd'hui) : de la spécification à la pull request, avec ta validation aux moments clés.

Tu décris ce que tu veux, les agents rédigent la spec, planifient, codent, testent l'appli en vrai, relisent le code et vérifient la cohérence. Toi, tu valides la spec, le plan et la PR.

---

## Comment ça marche

```
/feature « ajouter l'export CSV des tours »
   │
   ├─ spec        → objectif, périmètre, critères d'acceptation, questions ouvertes
   │                ⏸ tu réponds aux questions et tu valides
   ├─ architect   → plan fichier par fichier, versions, skills ; crée la branche
   │                ⏸ tu valides le plan
   ├─ coder ×N    → une instance par couche (back, front, bot…), en parallèle si possible
   │                code + tests, build et tests jusqu'au vert
   ├─ commit
   ├─ reviewer ┐  → relit le diff, relance build + tests, note sur 10 (passage ≥ 7)
   ├─ tester   ┘  → lance l'appli, vérifie chaque critère en vrai (navigateur, HTTP…)
   │                échec → retour aux coders, 3 tours au maximum
   ├─ validator   → cohérence entre couches, actions manuelles à faire
   └─ synthèse    ⏸ tu valides → PR vers ta branche cible
```

### Les agents

| Agent | Rôle | Modèle |
|---|---|---|
| `spec` | transforme ta demande en spécification, liste les questions ouvertes | sonnet |
| `architect` | explore le code, produit le plan, relève les versions, crée la branche | sonnet |
| `coder` | implémente une couche, écrit les tests, fait passer build et tests | sonnet |
| `reviewer` | relit le diff avec une grille (bugs, conventions, tests, sécurité…), note sur 10 | sonnet |
| `tester` | démarre l'appli et vérifie les critères d'acceptation en conditions réelles | sonnet |
| `validator` | vérifie la cohérence entre couches, liste les actions manuelles | haiku |

### Les skills

Deux skills que tu lances toi-même :

| Commande | Rôle |
|---|---|
| `/setup` | prépare un projet : détecte stack, versions et commandes, pose les questions restantes, écrit la config du workflow |
| `/feature <demande>` | lance le cycle complet d'une feature (`/feature <ID>` pour la reprendre) |

Et des skills de conventions, chargés automatiquement par les agents selon la stack : `laravel`, `react`, `java-spring`, `java-jda`, `mysql`. Ils n'imposent aucune version : les versions sont lues dans ton projet.

---

## Prérequis

Seul **Mac, Linux ou WSL (Windows) avec git** est indispensable, plus [Claude Code](https://claude.com/claude-code). Le reste active une fonction précise ; s'il manque, le workflow tourne quand même.

| Prérequis | Sert à | S'il manque |
|---|---|---|
| Node ≥ 20 | le navigateur du tester | les critères d'interface sont marqués « non testé » |
| Google Chrome | le navigateur du tester | `install.sh` propose de télécharger Chromium (~150 Mo) |
| python3 | les statistiques pour le futur dashboard | rien n'est collecté, le reste fonctionne |
| `gh` connecté à GitHub | la création de la PR à la fin | tu crées la PR toi-même |

Pas besoin que Node 20 soit ta version par défaut : `install.sh` trouve un Node récent installé via nvm, fnm, volta, asdf ou Homebrew, et l'utilise pour le tester uniquement. `install.sh` affiche un bilan de tous ces prérequis à la fin.

---

## Installation

```bash
git clone git@github.com:Crv113/ai-agents.git   # où tu veux
cd ai-agents
./install.sh --dry-run    # facultatif : montre ce qui serait fait, sans rien modifier
./install.sh
```

Puis **redémarre Claude Code**. Les agents et les skills sont disponibles dans tous tes projets.

### Ce que l'installation modifie sur ta machine

| Où | Quoi | Pourquoi |
|---|---|---|
| `~/.claude/agents/<nom>.md` | un lien par agent | Claude Code y cherche les agents |
| `~/.claude/skills/<nom>` | un lien par skill | Claude Code y cherche les skills |
| `~/.claude/settings.json` | 5 hooks ajoutés, le reste n'est pas touché | statistiques pour le dashboard (`--no-hooks` pour s'en passer) |
| `~/.claude/ai-agents/state` | la liste de ce qui a été installé | permet de tout retirer proprement et de suivre un déplacement du repo |
| `~/.claude/ai-agents/backups/<date>/` | une copie de ce qui a été remplacé ou modifié | filet de sécurité |
| `connectors/claude/build/` (dans le repo) | les agents au format Claude Code | générés à partir des agents neutres |

Ce sont des **liens**, pas des copies : les agents restent dans le repo, à un seul endroit.

**Sans risque à relancer** : `install.sh` ne refait que ce qui manque, suit le repo si tu le déplaces, et ne supprime jamais rien sans te demander. S'il tombe sur un fichier qui n'est pas à lui, il le sauvegarde et te demande avant de le remplacer.

### Les sauvegardes

À chaque fois qu'`install.sh` modifie ou remplace quelque chose, il en garde une copie datée dans `~/.claude/ai-agents/backups/<date>/` : ton `settings.json` d'avant l'ajout des hooks, ou un agent/skill du même nom qui existait déjà.

`./uninstall.sh` les remet en place automatiquement quand il le peut. Pour revenir manuellement à ton `settings.json` d'origine (en dernier recours, car tu perdrais les réglages changés depuis) :

```bash
cp ~/.claude/ai-agents/backups/<date>/settings.json ~/.claude/settings.json
```

---

## Préparer un projet : `/setup`

Une fois par projet, ouvre Claude Code dans le projet et lance :

```
/setup
```

Il détecte les sous-projets, la stack, les versions et les commandes de build, de test et de lancement. Il te pose ensuite les questions qu'il ne peut pas deviner : nom du projet, branche cible des PR, comptes de test, SDK payants autorisés. Il te montre le résultat avant d'écrire.

Il écrit un bloc délimité dans le fichier d'instructions du projet, que les agents lisent :

```markdown
<!-- ai-agents:start -->
## Workflow (ai-agents)

Nom du projet : mon-projet
Branche cible des PR : main
SDK payants autorisés : aucun
Comptes de test : aucun

| Sous-projet | Chemin | Stack | Versions | Skills |
|---|---|---|---|---|
| api   | api/   | Laravel | PHP 8.3, Laravel 11 | laravel, mysql |
| front | front/ | React   | React 19, Vite 6    | react |

Build (front) : npm run build
Tests (api) : php artisan test
Lancement (front) : npm run dev → http://localhost:5173
<!-- ai-agents:end -->
```

- **Où** : dans `AGENTS.md`, le fichier d'instructions standard lu par la plupart des assistants de code. `/setup` ajoute `@AGENTS.md` à ton `CLAUDE.md` pour que Claude Code le lise aussi. Un projet qui n'a qu'un `CLAUDE.md` (ancienne version du workflow) garde le bloc dans `CLAUDE.md`.
- **Le reste du fichier n'est jamais modifié**, seulement ce qui est entre les deux marqueurs.
- **Relançable** : après un changement de stack, relance `/setup`, le bloc est remplacé.

Le fichier n'est pas committé à ta place.

---

## Développer une feature : `/feature`

```
/feature ajouter l'export CSV des tours, depuis la page de détail d'une session
```

Le déroulé :

1. **Spec** : tu reçois l'objectif, le périmètre, les critères d'acceptation et les **questions ouvertes**. Tu réponds et tu valides, ou tu demandes des corrections.
2. **Plan** : tu reçois les fichiers à créer et à modifier, les versions relevées, le découpage par couche et la branche créée (`feature/F-20261023-001-export-csv`). Tu valides.
3. **Implémentation, review, tests en vrai, cohérence** : tout se fait sans toi, sauf si quelque chose bloque ou s'il manque une info (par exemple un compte de test).
4. **Synthèse** : ce qui a été fait, la note du reviewer, le tableau des critères (passés, échoués, non testés), les actions manuelles (migration à lancer, variable d'env…). Tu valides, et la PR est créée vers ta branche cible.

Rien n'est poussé et aucune PR n'est créée sans ton accord.

**Reprendre une feature** : `/feature F-20261023-001` reprend là où elle s'était arrêtée, même dans une autre session.

**Les documents de la feature** sont dans le projet, sous `.ai-agents/features/<ID>/` : `spec.md`, `plan.md`, `review.md`, `test-report.md` et `status.md`. Ce dossier est exclu de git localement, il n'apparaît ni dans tes commits ni dans tes PR.

**Une petite modification isolée** ne justifie pas tout le cycle. Demande directement à Claude d'utiliser l'agent `coder` ou `architect`.

---

## Modifier ou ajouter un agent ou un skill

Tout se passe dans le repo :
- `agents/<nom>.md` pour un agent ;
- `skills/<nom>/SKILL.md` pour un skill ;
- `connectors/claude/agents.conf` pour les réglages propres à Claude Code, comme le modèle de chaque agent.

| Ce que tu changes | À faire ensuite |
|---|---|
| un nouvel agent ou un nouveau skill | `./install.sh`, puis redémarrer Claude Code |
| un agent existant, `agents.conf`, `skills.conf`, `/feature` ou `/setup` | `./install.sh`, puis ouvrir une nouvelle session |
| un skill de conventions (`react`, `laravel`…) | rien : il est lié directement (au pire, nouvelle session) |

Les règles d'écriture (format, termes neutres, versions) sont dans [AGENTS.md](AGENTS.md).

---

## Mettre à jour

```bash
cd ai-agents
git pull
./install.sh
```

Puis redémarre Claude Code.

## Désinstaller

```bash
./uninstall.sh --dry-run   # facultatif : montre ce qui serait retiré
./uninstall.sh
```

Il retire les liens et les hooks qu'il a installés, puis remet en place les fichiers qu'`install.sh` avait remplacés. Il retire les hooks de ton `settings.json` actuel plutôt que de restaurer l'ancienne copie, ce qui conserve les réglages changés depuis. Il ne touche à rien d'autre. Tes projets ne sont pas modifiés : les blocs écrits par `/setup` et les dossiers `.ai-agents/` restent.

---

## Dépannage

| Problème | Cause probable | Solution |
|---|---|---|
| Les agents ou `/feature` n'apparaissent pas | Claude Code n'a pas été redémarré | redémarrer Claude Code |
| Dans un projet, ce sont d'anciens agents qui répondent | ancien lien `.claude` de la v1 dans le projet | `ls -la .claude` : si c'est un lien vers `ai-agents/.claude`, `rm .claude` (supprime le lien seulement). `/setup` le détecte aussi |
| Le tester marque tout « non testé » | Node ≥ 20 ou navigateur introuvable, ou appli qui ne démarre pas | regarder le bilan de `./install.sh` et la raison donnée dans `test-report.md` |
| Claude demande l'autorisation d'écrire dans `.git/info/exclude` | c'est ainsi que `.ai-agents/` est exclu de git | accepter une fois par projet |
| La PR n'est pas créée | `gh` absent ou non connecté | `gh auth login`, ou créer la PR à la main depuis la branche |
| Un agent modifié ne change pas de comportement | `install.sh` pas relancé | `./install.sh`, puis nouvelle session |

---

## Pour aller plus loin

- [AGENTS.md](AGENTS.md) : les règles pour modifier ai-agents (destinées à l'assistant qui travaille sur ce repo, et aux contributeurs).
- [docs/EVENTS.md](docs/EVENTS.md) : le format des statistiques envoyées par les hooks.
- [docs/REFONTE.md](docs/REFONTE.md) : l'historique de la refonte v1 → v2.

**À venir** : un dashboard 3D pour voir les agents travailler en direct, avec les tokens, la durée et les agents de chaque feature, projet par projet.
