## Stack
JDA 5 (Java Discord API), intégré dans Spring Boot.

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
