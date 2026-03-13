# DMS Backend Architecture Documentation

This document outlines the architecture, design patterns, and implementation details of the Distributor Management System (DMS) backend.

## Overview
The backend is built using **Spring Boot 3.2.4** with **Java 21/25**. It follows a **Modular Monolith** architecture designed for scalability and multi-tenancy.

## Core Technologies
- **Framework**: Spring Boot
- **Database**: PostgreSQL (Production), H2 (Testing)
- **Security**: Spring Security (JWT + RBAC)
- **Data Access**: Spring Data JPA (Hibernate)
- **Validation**: Jakarta Validation

## Architectural Patterns

### 1. Multi-Tenancy (Discriminator Column)
The system is designed to support multiple distributors (tenants) on a single database.
- Every major entity has a `tenant_id`.
- Data isolation is enforced at the repository or service layer.
- The `Tenant` entity represents the distributor.

### 2. Entity Design (Lombok-Free)
To ensure compatibility with latest JDKs (JDK 25+), the project uses standard Java boilerplate (Getters/Setters/Constructors/Builders) instead of Lombok.
- **Builders**: Manual builder patterns are implemented for all entities to retain the fluent API style.
- **Timestamps**: `@CreationTimestamp` and `@UpdateTimestamp` are used for auditing.

### 3. Modular Monolith
The package structure is organized by domain to allow future transition to microservices if needed:
- `com.dms.backend.models`: Core domain entities.
- `com.dms.backend.repositories`: Data access layer.
- `com.dms.backend.services`: Business logic.
- `com.dms.backend.controllers`: REST APIs.

## Entity Relationship Diagram (Mental Model)
- **Tenant** (1) <-> (N) **User**
- **Tenant** (1) <-> (N) **Product**
- **Tenant** (1) <-> (N) **Retailer**
- **Retailer** (1) <-> (N) **Order**
- **Order** (1) <-> (N) **OrderItem**
- **User** (N) <-> (N) **Role**

## Testing Strategy
- **Unit Tests**: Use `@DataJpaTest` with an embedded **H2** database.
- **API Tests**: Use `@SpringBootTest` with `MockMvc`.
- **Validation**: All entities include constraints (e.g., `@Column(nullable = false)`).

## Development Notes for Future Agents
- **JDK 25 Compatibility**: Do NOT use Lombok. It causes `TypeTag :: UNKNOWN` errors.
- **Database Migrations**: Hibernate is currently set to `update`. In production, move to Flyway or Liquibase.
- **Multi-Tenancy**: Always ensure `tenant_id` is populated for new records.
