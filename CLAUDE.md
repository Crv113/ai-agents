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
└── skills/
    ├── laravel.md        — Conventions Laravel + PHP
    ├── react.md          — Conventions React + TanStack Query + Tailwind
    ├── java-spring.md    — Conventions Java + Spring Boot
    ├── java-jda.md       — Conventions JDA (Discord bot)
    └── mysql.md          — Bonnes pratiques SQL
```

## Utilisation

Pour une feature transversale :
```
spec → architect → coder (×N couches) → reviewer → validator
```

L'`architect` identifie les skills requis par couche. Le `coder` les charge avant d'implémenter.

## Ajouter un skill

Créer un fichier dans `.claude/skills/`. L'`architect` et le `coder` le chargeront dès qu'il est listé dans un plan.
