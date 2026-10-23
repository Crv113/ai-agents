---
name: java-jda
description: Conventions pour un bot Discord JDA intégré à Spring Boot, toutes versions (listeners, slash commands, deferReply, limite 2000 caractères, pattern message → LLM). À charger pour écrire ou relire du code de bot Discord en Java.
---

## Stack
JDA (Java Discord API), intégré dans Spring Boot.

## Versions
Ce skill n'impose aucune version : avant d'écrire du code, déterminer la version de JDA utilisée par le projet.
- Source de vérité : la dépendance `net.dv8tion:JDA` dans le `pom.xml` ou le `build.gradle`
- Utiliser uniquement les APIs disponibles dans cette version (les noms de méthodes et de classes changent entre versions majeures)
- Versions de Java et Spring Boot : voir le skill `java-spring`

## Conventions
- Un `@Component` par listener Discord
- Enregistrer les commandes au démarrage dans un `@EventListener(ReadyEvent.class)`
- Toujours acquitter l'interaction Discord dans les 3 secondes — utiliser `deferReply()` si le LLM peut prendre plus de temps
- Répondre via `event.reply()` pour les réponses courtes, `deferReply()` + `editOriginal()` pour les opérations longues
- Les messages Discord ont une limite de 2000 caractères — tronquer ou paginer si dépassé

## Pattern message → LLM
1. Listener reçoit le message ou slash command
2. Construit le contexte (system prompt avec schéma BDD + règles métier)
3. Appelle le LLM via client configuré
4. Poste la réponse via `event.reply()` ou `channel.sendMessage()`

## Variables d'environnement
- `DISCORD_TOKEN` — token du bot

## Test en conditions réelles
- Par défaut, pas de vrai Discord : appeler les listeners et handlers avec des événements simulés (mocks de `SlashCommandInteractionEvent`, `MessageReceivedEvent`…) et vérifier la réponse produite
- Vrai Discord uniquement si les instructions du projet fournissent un serveur de test et un token de bot de test. Sinon, les critères qui exigent Discord passent en « non testé en réel »
- Ne jamais utiliser le token du bot de production

## Points de cohérence
- Les réponses de plus de 2000 caractères sont tronquées ou paginées
- Les traitements longs (LLM, requêtes lourdes) utilisent `deferReply()`
- Le system prompt du LLM reflète le schéma de base actuel (migrations de la feature comprises) et les règles métier des instructions du projet
- Chaque commande déclarée au démarrage a un handler, et inversement
