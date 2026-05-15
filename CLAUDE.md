# CLAUDE.md

Ce fichier fournit des instructions à Claude Code (claude.ai/code) pour travailler sur ce dépôt.

## Rôle

Ce projet contient les agents Claude Code qui assistent le développement de mxbtiming.com. Ce ne sont pas des agents IA à déployer — ce sont des fichiers de configuration pour Claude Code.

## Structure

```
.claude/agents/
├── orchestrator.md   — Coordonne le cycle complet d'une feature
├── spec.md           — Transforme une demande en specs techniques
├── architect.md      — Analyse l'existant et produit le plan d'implémentation
├── coder-back.md     — Implémente sur seek-and-stock (Laravel)
├── coder-front.md    — Implémente sur mxb-timing (React)
├── reviewer.md       — Relit le code produit
└── validator.md      — Vérifie la cohérence front/back
```

## Utilisation

Pour une feature transversale, invoquer l'orchestrateur qui coordonne les autres agents dans l'ordre :
```
spec → architect → coder-back + coder-front → reviewer → validator
```

## Modifier un agent

Chaque fichier `.md` contient un frontmatter (`name`, `description`) suivi du prompt système de l'agent. Modifier le prompt directement pour affiner le comportement.
