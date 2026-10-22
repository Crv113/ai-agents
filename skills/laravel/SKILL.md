---
name: laravel
description: Conventions Laravel / PHP (Actions avec handle(), Form Requests, Sanctum, Spatie Permission, tests Feature avec RefreshDatabase). À charger pour écrire ou relire du code backend Laravel.
---

## Stack
Laravel, PHP, MySQL, Sanctum, Spatie Permission.

## Versions
Ce skill n'impose aucune version : avant d'écrire du code, déterminer les versions utilisées par le projet.
- Source de vérité : `composer.json` (contrainte `php`, `laravel/framework`, paquets) et `composer.lock` (versions installées)
- Utiliser uniquement les APIs et la structure de projet de la version installée (la structure de `bootstrap/` et `routes/` varie selon la version de Laravel)

## Architecture
- Business logic dans `app/Actions/` — classe avec méthode `handle()`, injectée via le Service Container
- Controllers fins : reçoivent les Actions injectées, appellent `handle()`, retournent une Resource
- Validation via Form Request (`php artisan make:request`) — pas de `Validator::make` dans les controllers

## Auth
- Deux types classiques : `auth:sanctum` (utilisateurs) et service-to-service via API key
- Rôles admin imbriqués dans l'auth utilisateur
- Consulter le CLAUDE.md du projet pour les noms exacts des middlewares custom

## Conventions
- Requêtes bulk obligatoires pour les listes — pas de N+1
- Pas de `dd()`, `dump()`, `var_dump()` dans le code rendu

## Tests
- Un test Feature par endpoint dans `tests/Feature/`
- `RefreshDatabase` + factories pour les données de test
- Tester : cas nominal, 401/403/422, règles métier critiques définies dans le CLAUDE.md du projet
- Avant d'écrire ou de lancer des tests : vérifier que `phpunit.xml` définit un `DB_DATABASE` distinct de la base principale (ex: `myapp_test`). Bloquer et alerter si ce n'est pas le cas.

## À lire dans le CLAUDE.md du projet
- Resources existantes à réutiliser
- Middlewares custom et leurs noms
- Règles métier à appliquer dans les requêtes

## Test en conditions réelles
- Lancement : `php artisan serve` (défaut `http://127.0.0.1:8000`), ou le service web du `docker-compose.yml` s'il existe
- Requêtes HTTP (`curl`) sur chaque endpoint de la feature : cas nominal, 401 sans token, 403 avec un compte sans droit, 422 avec un payload invalide
- Auth : uniquement les comptes de test du `CLAUDE.md` du projet (token Sanctum obtenu via la route de login de test)
- Base : uniquement la base de test. Vérifier dans `.env` / `phpunit.xml` que ce n'est pas la base principale avant toute requête qui écrit
- Ne jamais lancer `migrate:fresh`, `migrate:refresh`, `db:wipe` ni de seed non idempotent

## Points de cohérence
- Chaque nouveau champ ou table utilisé dans le code a une migration
- Chaque route protégée a le middleware attendu (`auth:sanctum`, rôle, middleware custom du `CLAUDE.md` du projet)
- Les Resources renvoient tous les champs consommés par les autres couches, avec les mêmes noms
- Les Form Requests valident les champs envoyés par le front
