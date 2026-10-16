# CLAUDE.md

Ce fichier fournit des instructions à Claude Code (claude.ai/code) pour travailler sur ce dépôt.

## Rôle

Workflow agent générique pour projets multi-couches. Ce ne sont pas des agents IA à déployer — ce sont des fichiers de configuration pour Claude Code.

Destiné à être intégré comme sous-répertoire d'un projet parent via un symlink `.claude → ai-agents/.claude`.

## Principe de séparation

```
ai-agents/          → workflow (comment travailler)
  .claude/skills/   → conventions par langage/framework
  .claude/agents/   → comportement des agents

{projet}/CLAUDE.md  → règles du projet (quoi respecter)
  - liste des sous-projets et leur stack
  - règles métier spécifiques au domaine
  - conventions de code propres au projet
  - index BDD, middlewares custom, composants existants
  - autorisations SDK externes (si applicable)
```

Les agents lisent le `CLAUDE.md` du projet racine pour tout ce qui est project-specific. Aucune règle de domaine ne doit être hardcodée dans les agents ou skills.

## Structure

```
.claude/
├── agents/
│   ├── orchestrator.md   — Coordonne le cycle complet d'une feature
│   ├── spec.md           — Transforme une demande en specs techniques
│   ├── architect.md      — Analyse l'existant, produit le plan + liste les skills requis
│   ├── coder.md          — Implémente une couche (charge les skills requis)
│   ├── reviewer.md       — Relit le git diff (Haiku)
│   └── validator.md      — Vérifie la cohérence entre couches (Haiku)
└── skills/             — skills natifs Claude Code (un dossier par skill)
    ├── laravel/SKILL.md      — Conventions Laravel + PHP
    ├── react/SKILL.md        — Conventions React + TanStack Query + Tailwind
    ├── java-spring/SKILL.md  — Conventions Java + Spring Boot
    ├── java-jda/SKILL.md     — Conventions JDA (Discord bot)
    └── mysql/SKILL.md        — Bonnes pratiques SQL
```

## Prérequis avant utilisation

Les agents ne sont visibles par Claude Code que s'ils sont exposés à la racine du projet parent. Vérifier qu'un symlink `.claude` existe à la racine du projet parent et pointe vers `ai-agents/.claude` :

```bash
ls -la {projet}/.claude
```

Si absent, le créer depuis la racine du projet parent :

```bash
ln -s ai-agents/.claude .claude
```

Sans ce symlink, les agents (`orchestrator`, `spec`, `architect`, `coder`, `reviewer`, `validator`) ne sont pas invocables depuis le projet.

## Utilisation

Pour une feature transversale :
```
spec → architect → coder (×N couches) → reviewer → validator
```

L'`architect` identifie les skills requis par couche. Le `coder` les charge avant d'implémenter.

## Ajouter un skill

Créer un dossier `.claude/skills/<nom>/` contenant un `SKILL.md` qui commence par un frontmatter :

```markdown
---
name: <nom>
description: <ce que couvre le skill et quand le charger>
---
```

La `description` est ce que Claude Code utilise pour charger le skill automatiquement — elle doit dire quand l'utiliser. Le skill est aussi invocable via `/<nom>`, et l'`architect` peut le lister dans un plan pour que `coder` et `reviewer` le chargent.
