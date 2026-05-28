## Stack
Laravel, PHP, MySQL, Sanctum, Spatie Permission.

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
