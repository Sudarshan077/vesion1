# Distributor Management System (DMS)

## Project Overview
A Distributor Management System (DMS) designed to digitize the distribution supply chain in India, handling inventory, orders, billing (GST compliance), payments, and analytics.

**Current Working Directory:** `c:\Users\srgow\OneDrive\Documents\version1`

## Tech Stack
*   **Frontend (Mobile & Web Admin Dashboard):** Flutter (Dart) - Single Codebase
*   **Backend:** Java Spring Boot
*   **Database:** PostgreSQL (Primary Transactional Data) & Redis (Caching/Sessions)
*   **Infrastructure / Hosting:** Google Cloud Platform (GCP) - Cloud Run, Cloud SQL, Cloud Storage

## Architecture Strategy
*   **Backend Style:** Modular Monolith (to ensure fast development speed initially, while keeping domain logic decoupled for future microservice extraction).
*   **Multi-tenancy:** Shared database with `tenant_id` for data isolation across different distributors.
*   **API Design:** RESTful APIs with OpenAPI/Swagger specifications. Versioned (`/api/v1/`).
*   **Authentication & Security:** JWT-based stateless auth, Role-Based Access Control (RBAC).
*   **Offline Sync (Mobile):** Local SQLite storage with a synchronization queue for offline order capture.

## Current Progress & Status
*   **Last Update:** Core JPA architecture verified and unit tested (without Lombok for JDK 25 compatibility). See `backend/docs/architecture.md`.
*   **Status:** Backend entities and DB schema verified.
*   **Next Step:** Implement JWT-based Authentication and Role-Based Access Control (RBAC).

## Phase 1 Implementation Plan (MVP)

**Phase 1 Goal:** Core order, inventory, and billing workflows for Admin and Salesman roles.

1.  **Database Schema Setup (PostgreSQL)**
    *   Auth & RBAC, Multi-tenancy
    *   Catalog & Stock, Order Management
    *   Customer Management, Basic Billing
2.  **Backend Scaffolding (Spring Boot)**
    *   Initialize Spring Boot + JPA + Spring Security.
    *   Implement basic CRUD APIs.
3.  **Frontend Scaffolding (Flutter)**
    *   Initialize Web and Mobile apps.
    *   Connect to Backend APIs.

---
*Note for AI Assistants: When resuming work in a new chat, read this README first, then proceed to the "Next Step" listed in the Current Progress & Status section.*
