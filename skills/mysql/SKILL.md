---
name: mysql
description: Bonnes pratiques SQL / MySQL (pas de N+1, requêtes bulk, CTEs, vérification des index sur les grandes tables). À charger pour écrire ou relire des requêtes SQL ou de l'accès base de données.
---

## Versions
Ce skill n'impose aucune version : avant d'écrire du SQL, déterminer la version du serveur utilisée par le projet.
- Source de vérité : image Docker (`docker-compose.yml`), configuration du projet, ou `SELECT VERSION()`
- N'utiliser que la syntaxe disponible dans cette version (ex. CTEs et fonctions de fenêtrage à partir de MySQL 8)

## Bonnes pratiques
- Requêtes bulk pour les listes — pas de N+1
- Utiliser sous-requêtes ou CTEs pour les classements et agrégats complexes
- Vérifier l'existence d'un index avant de filtrer ou joindre sur une colonne d'une grande table

## À lire dans le CLAUDE.md du projet
- Index existants sur les tables principales
- Règles métier SQL spécifiques au domaine
