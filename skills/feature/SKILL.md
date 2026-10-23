---
name: feature
description: Cycle complet d'une feature transversale (spec → architect → coder → reviewer + tester → validator → PR) avec validation humaine de la spec et du plan. Lancé par l'utilisateur avec /feature <demande>, ou /feature <ID> pour reprendre une feature.
---

Tu orchestres le cycle d'une feature dans la session principale. Tu délègues tout aux agents, tu ne codes jamais. Les seules actions que tu fais toi-même : lire les instructions du projet, gérer le dossier de la feature, committer, et créer la PR après accord.

Demande de l'utilisateur : $ARGUMENTS

## Règles

- **Deux arrêts obligatoires** : après la spec et après le plan. Présente, puis attends une validation explicite de l'utilisateur. Ne jamais enchaîner sans réponse.
- Les agents se passent leurs documents par fichier, dans le dossier de la feature. Transmets à chaque agent le chemin des fichiers et le strict nécessaire, pas leur contenu.
- Usage réservé aux features transversales. Pour une modification isolée, lancer directement `coder` ou `architect`.
- Aucun push, aucune PR sans accord explicite de l'utilisateur.

## 0. Préparation

1. Lire les instructions du projet : sous-projets, stack, **branche cible des PR** (ligne `Branche cible des PR : …`, défaut `main`), commandes build/test.
2. **Reprise** : si la demande est un ID existant (`F-YYYYMMDD-NNN`) et que `.ai-agents/features/<ID>/` existe, lire `status.md` et reprendre à l'étape indiquée.
3. Sinon, générer l'ID `F-YYYYMMDD-NNN` (date du jour, `NNN` = prochain numéro libre d'après `git branch -a --list 'feature/F-<date>-*'` sur les repos impactés). Annoncer l'ID.
4. Créer `.ai-agents/features/<ID>/` à la racine du projet. Si `.ai-agents/` n'est pas déjà ignoré, ajouter la ligne `.ai-agents/` à `.git/info/exclude` (exclusion locale : ne pas modifier le `.gitignore` du projet).
5. Écrire `status.md` (ID, demande, branche cible, étape courante) et le tenir à jour à chaque étape.
6. Écrire l'ID seul dans `.ai-agents/current` (y compris lors d'une reprise) : il marque la feature en cours, pour que la consommation de la session et des agents lui soit rattachée.

## 1. Spec

1. Lancer l'agent `spec` avec la demande brute et le chemin de sortie `.ai-agents/features/<ID>/spec.md`.
2. Présenter à l'utilisateur : objectif, périmètre, critères d'acceptation résumés, et **toutes les questions ouvertes**.
3. **Stop** : attendre les réponses et la validation.
   - Corrections ou réponses → relancer `spec` avec ces retours (reprendre le même agent si possible), puis re-présenter.
   - Validation → noter les réponses aux questions ouvertes dans `spec.md` (section « Décisions »), passer au plan.

## 2. Plan

1. Lancer l'agent `architect` avec : chemin de `spec.md`, ID, branche cible, chemin de sortie `.ai-agents/features/<ID>/plan.md`.
2. Présenter : branche(s) créée(s), versions relevées, skills requis, fichiers à créer/modifier, découpage par couche et parallélisme, points d'attention.
3. **Stop** : attendre la validation. Corrections → relancer `architect`, re-présenter.

## 3. Implémentation

1. Lancer un `coder` par couche du plan, **en parallèle** si le plan les déclare indépendantes, sinon dans l'ordre indiqué. Chacun reçoit : chemin de `plan.md` + la couche à traiter, skills requis, ID.
2. Chaque coder rend : fichiers modifiés, commandes build/test lancées, résultat (vert / bloqué).
3. Un coder bloqué → présenter le blocage à l'utilisateur et attendre sa décision.

## 4. Commit

Sur la branche de feature de chaque repo impacté : `git add` **uniquement des fichiers listés par les coders** (jamais `-A`), puis `git commit -m "<ID>: <résumé court>"`.

## 5. Review

Lancer **en parallèle** :
- l'agent `reviewer` avec : skills utilisés, branche cible, chemin de sortie `.ai-agents/features/<ID>/review.md`
- l'agent `tester` avec : chemins de `spec.md` et `plan.md`, skills utilisés, chemin de sortie `.ai-agents/features/<ID>/test-report.md`

Puis :
1. **Infos manquantes du tester** (identifiants de test, variables d'env…) → les demander à l'utilisateur, les écrire dans les instructions du projet, relancer le tester.
2. **Fichiers modifiés par le tester** (tests E2E, ligne `Lancement :` des instructions du projet) → les committer, puis faire relire **uniquement ces fichiers** par le reviewer.
3. **Passage** = reviewer OK (build OK + tests verts + note ≥ 7/10) **et** aucun critère « échoué » dans `test-report.md`. Les critères « non testé » ne bloquent pas mais figurent dans la synthèse.
4. Pas de passage → renvoyer les bloquants du reviewer et les critères échoués du tester aux coders concernés, committer, relancer reviewer et tester.
5. **Au bout de 3 tours sans passage** (reviewer et tester confondus) : s'arrêter, présenter les derniers rapports et demander à l'utilisateur comment continuer.

## 6. Validation de cohérence

Lancer l'agent `validator` avec : chemins de `spec.md`, `plan.md` et `test-report.md`, skills utilisés, branche cible. Incohérences bloquantes → retour aux coders, commit, puis review, tester et validator à nouveau.

## 7. Synthèse et PR

1. Présenter : ce qui a été implémenté, la note et les avertissements du reviewer, **le tableau des critères du tester** (passés, échoués, non testés), les incohérences relevées, **les actions manuelles** (migrations, variables d'env…).
2. Demander si l'utilisateur valide la feature et la création de la PR.
   - Oui → push de la branche, puis `gh pr create --base <branche cible>` (titre `<ID>: <résumé>`, corps = synthèse), une PR par repo impacté. Donner les URLs.
   - Non → appliquer les retours (coders, commit, review), puis reproposer.
3. Mettre `status.md` à « terminé » et supprimer `.ai-agents/current`.

Si l'utilisateur abandonne ou met la feature en pause : supprimer `.ai-agents/current` (une reprise le réécrira).
