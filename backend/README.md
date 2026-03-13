# DMS Backend

Spring Boot backend for the Distributor Management System.

## Architecture
See [Architecture Documentation](docs/architecture.md) for details.

## Build Requirements
- **JDK**: 21 or 25 (LTS recommended)
- **Database**: PostgreSQL 15+

## How to Run
1.  Configure `src/main/resources/application.yml` with your PostgreSQL credentials.
2.  Run `./mvnw spring-boot:run`.

## How to Test
Run `./mvnw test`. 
Note: Unit tests use the embedded H2 database and do not require a local PostgreSQL instance.

## Modules (Phase 1)
- `com.dms.backend.models`: JPA Entities (Multi-tenant)
- `com.dms.backend.repositories`: Spring Data Repositories
- `com.dms.backend.services`: Business Logic
- `com.dms.backend.controllers`: REST Controllers
- `com.dms.backend.security`: JWT and Security Configuration
