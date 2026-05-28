## Stack
Java 21, Spring Boot 3.3, Maven.

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
- Mockito (`@MockBean`) pour isoler les services dans les tests controller
- Un test par endpoint : cas nominal, cas d'erreur (400, 401, 403, 404), cas limites
- Règles métier critiques définies dans le CLAUDE.md du projet

## Build
```bash
mvn spring-boot:run    # dev
mvn package            # build .jar
mvn test               # tests
```
