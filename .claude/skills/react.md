## Stack
React + Vite + TanStack Query + Tailwind CSS + React Router.

## Conventions
- Toute la donnée serveur via TanStack Query — jamais d'appel direct (axios, fetch) dans un composant
- Responsive : deux layouts distincts via hook dédié — pas de classes breakpoint pour les changements structurels majeurs
- Fonctions fetch définies **avant** la déclaration du composant, jamais à l'intérieur
- `React.Fragment` (pas `<>`) quand la clé `key` est nécessaire
- Pas de composant réutilisable si utilisé à un seul endroit

## UI
- Tailwind uniquement — pas de CSS inline ou fichiers CSS séparés sauf fichier global
- Consulter le CLAUDE.md du projet pour : langue de l'UI, polices, conventions visuelles spécifiques

## Tests
- Vitest + React Testing Library
- Tester le comportement visible (ce que l'utilisateur voit/fait), pas l'implémentation
- Mocker les appels TanStack Query avec `msw` ou `vi.mock`
- Un test par cas : rendu nominal, état vide, état d'erreur, interaction utilisateur critique
- Consulter le CLAUDE.md du projet pour la configuration de test existante

## À lire dans le CLAUDE.md du projet
- Hook d'authentification (nom, champs exposés)
- Variables d'environnement
- Structure des dossiers, routes, navigation
- Conventions UI et composants existants à réutiliser
