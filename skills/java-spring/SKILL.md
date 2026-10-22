---
name: java-spring
description: Conventions Java / Spring Boot, toutes versions (structure des packages, controllers fins, services, JPA, tests MockMvc/DataJpaTest, build Maven). À charger pour écrire ou relire du code backend Java Spring Boot.
---

## Stack
Java + Spring Boot + Maven.

## Versions
Ce skill n'impose aucune version : avant d'écrire du code, déterminer les versions utilisées par le projet.
- Source de vérité : le `pom.xml` (version du parent `spring-boot-starter-parent`, propriété `java.version`)
- Le `CLAUDE.md` du projet peut aussi les mentionner — en cas d'écart, le `pom.xml` fait foi
- Utiliser les APIs, annotations et dépendances disponibles dans ces versions — ne pas introduire de pattern déprécié ou supprimé dans la version du projet

## Structure des packages
```
com.{groupid}.{module}/
├── config/     # Configuration Spring (beans, propriétés)
├── controller/ # @RestController — fins, délèguent au service
├── service/    # @Service — logique métier
├── repository/ # @Repository, JpaRepository
└── entity/     # @Entity — entités JPA
```

## Conventions
- Controllers fins : reçoivent les Services injectés, retournent `ResponseEntity`
- Toute valeur sensible via variables d'environnement — jamais hardcodée
- `spring.jpa.hibernate.ddl-auto=validate` — Hibernate ne modifie jamais le schéma
- Pas de logique métier dans les controllers
- Accès base de données : lecture seule par défaut — pas d'INSERT/UPDATE/DELETE sauf besoin explicite dans la spec

## Tests
- `@SpringBootTest` + `MockMvc` pour les tests d'intégration controller
- `@DataJpaTest` pour les repositories — base H2 en mémoire ou base de test dédiée
- Mockito pour isoler les services dans les tests controller — `@MockitoBean` à partir de Spring Boot 3.4 (`@MockBean` est déprécié puis supprimé), `@MockBean` pour les versions antérieures
- Un test par endpoint : cas nominal, cas d'erreur (400, 401, 403, 404), cas limites
- Règles métier critiques définies dans le CLAUDE.md du projet

## Build
Utiliser le wrapper `./mvnw` s'il est présent dans le projet (version de Maven fixée par le dépôt) — sinon `mvn`.
```bash
./mvnw spring-boot:run    # dev
./mvnw package            # build .jar
./mvnw test               # tests
```

## Test en conditions réelles
- Lancement : `./mvnw spring-boot:run` (ou `mvn`), avec le profil de dev/test indiqué dans le `CLAUDE.md` du projet. Port : `server.port`, défaut 8080
- Attendre que l'application réponde (endpoint de santé s'il existe, sinon un endpoint de la feature)
- Requêtes HTTP (`curl`) sur chaque endpoint de la feature : cas nominal, erreurs (400, 401, 403, 404)
- Base : uniquement la base de test ou la base en mémoire du profil de test

## Points de cohérence
- `ddl-auto=validate` : chaque changement d'entité a son script de migration (Flyway/Liquibase) ou son changement de schéma documenté
- Les DTO renvoyés correspondent au contrat attendu par les autres couches (noms, types, nullabilité, format des dates)
- Les endpoints protégés ont la règle de sécurité attendue
