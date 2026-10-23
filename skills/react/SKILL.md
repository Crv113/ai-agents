---
name: react
description: Conventions React + Vite + TanStack Query + Tailwind + React Router (data fetching, layouts responsive, tests Vitest/RTL). À charger pour écrire ou relire du code frontend React.
---

## Stack
React + Vite + TanStack Query + Tailwind CSS + React Router.

## Versions
Ce skill n'impose aucune version : avant d'écrire du code, déterminer les versions utilisées par le projet.
- Source de vérité : `package.json` et le lockfile (`package-lock.json`, `pnpm-lock.yaml` ou `yarn.lock`)
- Utiliser uniquement les APIs de ces versions (la configuration de Tailwind, l'API de TanStack Query et celle de React Router changent entre versions majeures)

## Conventions
- Toute la donnée serveur via TanStack Query — jamais d'appel direct (axios, fetch) dans un composant
- Responsive : deux layouts distincts via hook dédié — pas de classes breakpoint pour les changements structurels majeurs
- Fonctions fetch définies **avant** la déclaration du composant, jamais à l'intérieur
- `React.Fragment` (pas `<>`) quand la clé `key` est nécessaire
- Pas de composant réutilisable si utilisé à un seul endroit

## UI
- Tailwind uniquement — pas de CSS inline ou fichiers CSS séparés sauf fichier global
- Consulter les instructions du projet pour : langue de l'UI, polices, conventions visuelles spécifiques

## Tests
- Vitest + React Testing Library
- Tester le comportement visible (ce que l'utilisateur voit/fait), pas l'implémentation
- Mocker les appels TanStack Query avec `msw` ou `vi.mock`
- Un test par cas : rendu nominal, état vide, état d'erreur, interaction utilisateur critique
- Consulter les instructions du projet pour la configuration de test existante

## À lire dans les instructions du projet
- Hook d'authentification (nom, champs exposés)
- Variables d'environnement
- Structure des dossiers, routes, navigation
- Conventions UI et composants existants à réutiliser

## Test en conditions réelles
- Lancement : script de dev de `package.json` (`dev` ou `start`), URL affichée au démarrage (ex. `http://localhost:5173`)
- Navigateur : naviguer vers chaque page concernée, agir comme l'utilisateur, lire la page via le snapshot d'accessibilité
- Vérifier : erreurs de console, état de chargement, état vide, état d'erreur (API en échec ou données absentes), affichage mobile (375×812)
- Si le front dépend d'une API : la lancer aussi (voir le skill de la couche backend) ou signaler les critères concernés en « non testé »
- E2E : si `@playwright/test` (ou Cypress) est dans `package.json`, écrire les tests dans le dossier E2E existant

## Points de cohérence
- Chaque champ lu côté front existe dans la réponse de l'API, avec le même nom et le même type (nullabilité comprise)
- Chaque URL appelée correspond à une route existante, avec la bonne méthode HTTP
- Le token ou cookie d'auth est transmis sur les appels protégés, et les erreurs 401/403 sont gérées dans l'UI
- Les états vides et d'erreur prévus par la spec existent dans l'UI
