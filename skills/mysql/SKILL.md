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

## Test en conditions réelles
- Pas de lancement propre : vérifier les données à travers la couche applicative (API, handlers)
- Requêtes SQL directes uniquement en lecture (`SELECT`) et uniquement sur la base de test

## Points de cohérence
- Chaque filtre, tri ou jointure ajouté sur une grande table s'appuie sur un index existant ou créé par une migration de la feature
- Les colonnes utilisées dans les requêtes existent dans le schéma (migrations comprises)
