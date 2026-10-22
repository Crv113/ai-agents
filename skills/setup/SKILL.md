---
name: setup
description: Prépare un projet pour le workflow ai-agents (à lancer une fois par projet, ou après un changement de stack) en détectant stack, versions et commandes build/test/lancement, en posant les questions restantes et en écrivant le bloc ai-agents du CLAUDE.md du projet. Lancé par l'utilisateur avec /setup.
---

Tu prépares le projet courant pour le workflow ai-agents. Tu tournes dans la session principale : tu peux poser des questions à l'utilisateur. Tu ne lances aucun agent et tu ne modifies aucun fichier de code.

But : un bloc à jour dans le `CLAUDE.md` du projet, que les agents lisent (branche cible des PR, commandes, comptes de test, SDK autorisés, versions).

## Règles

- **Déduire d'abord, demander ensuite** : ne poser que ce qui ne peut pas se lire dans le projet, en une seule série de questions, chacune avec une proposition par défaut
- **Ne jamais modifier le reste du `CLAUDE.md`** : seul le bloc entre `<!-- ai-agents:start -->` et `<!-- ai-agents:end -->` est écrit
- Montrer le bloc et attendre la confirmation avant d'écrire. Ne pas committer
- Aucune version imposée : les versions sont lues dans le projet (sections « Versions » des skills)

## 1. Racine et ancien lien v1

1. Racine du projet : `git rev-parse --show-toplevel` (sinon le dossier courant)
2. Si `.claude` à la racine est un **lien symbolique** vers un dossier `ai-agents/.claude` : le signaler (les agents du projet masquent ceux installés globalement) et proposer de **retirer le lien uniquement** (`rm .claude`, jamais sa cible). Ne le faire qu'après accord explicite

## 2. Sous-projets et stack

1. Repérer les sous-projets : dossiers contenant `package.json`, `composer.json`, `pom.xml`, `build.gradle*`, `go.mod`, `pyproject.toml`, `Cargo.toml`, ou dépôts git imbriqués. Ignorer `node_modules`, `vendor`, `target`, `dist`, `build`, `.git`
2. Pour chacun :
   - **Stack** et **skills** correspondants (parmi les skills disponibles : `react`, `laravel`, `java-spring`, `java-jda`, `mysql`…)
   - **Versions** : lues aux sources indiquées dans la section « Versions » de chaque skill (lockfiles compris)
   - **Commandes** : build, tests, lancement (scripts de `package.json`, wrappers `./mvnw` / `./gradlew`, `php artisan`, `Makefile`, `docker-compose.yml`), avec l'URL ou le port de lancement
3. Si un bloc ai-agents existe déjà : partir de ses valeurs et signaler ce qui a changé

## 3. Nouveau projet (dossier vide ou sans stack)

1. Demander la stack souhaitée
2. Pour chaque techno : **vérifier en ligne la dernière version stable** (LTS si elle existe), la proposer avec sa source
3. Noter dans le bloc les versions validées par l'utilisateur

## 4. Questions à l'utilisateur

En une seule fois, avec une proposition pour chaque point :
- **Nom du projet** — défaut : nom du dossier racine
- **Branche cible des PR** — défaut : branche par défaut du remote (`git symbolic-ref --short refs/remotes/origin/HEAD`), sinon `main`
- **Comptes de test** — identifiants de test uniquement, ou « aucun ». Ne jamais demander ni écrire de vrai mot de passe ou de secret de production : si l'appli a besoin d'un secret, indiquer la variable d'environnement qui le contient
- **SDK externes payants autorisés** — défaut : aucun (préciser par sous-projet si autorisé)
- **Commandes détectées** — à confirmer ou corriger, en particulier celles qui n'ont pas pu être déduites

## 5. Écriture du bloc

Format (omettre `(<sous-projet>)` s'il n'y a qu'un sous-projet) :

```markdown
<!-- ai-agents:start -->
## Workflow (ai-agents)

Nom du projet : <nom>
Branche cible des PR : <branche>
SDK payants autorisés : <aucun | liste par sous-projet>
Comptes de test : <identifiants de test | aucun>

| Sous-projet | Chemin | Stack | Versions | Skills |
|---|---|---|---|---|
| <nom> | <chemin> | <stack> | <versions> | <skills> |

Build (<sous-projet>) : <commande | aucun>
Tests (<sous-projet>) : <commande | aucun>
Lancement (<sous-projet>) : <commande> → <URL ou port>
<!-- ai-agents:end -->
```

1. Montrer le bloc complet à l'utilisateur et attendre sa confirmation
2. `CLAUDE.md` absent → le créer avec un titre (`# <nom>`) puis le bloc
3. Bloc présent → remplacer **uniquement** le contenu entre les deux marqueurs
4. Bloc absent → l'ajouter à la fin du fichier, séparé par une ligne vide
5. Les lignes déjà présentes **hors bloc** qui ont le même rôle (ex. une ancienne ligne `Branche cible des PR :`) : les signaler à l'utilisateur, ne pas les supprimer soi-même

## 6. Fin

Résumer : ce qui a été détecté, ce qui a été demandé, le fichier écrit. Rappeler que `CLAUDE.md` n'est pas committé et que `/feature` peut maintenant être utilisé.
