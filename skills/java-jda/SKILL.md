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
