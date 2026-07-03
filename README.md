# Space Mission Management System (SMMS) Database

## Overview
A highly normalized relational database built in **SQL Server (T-SQL)** to manage complex space mission logistics, crew assignments, dynamic telemetry data tracking, and resource allocation. 

## Technical Architecture
The database enforces strict data integrity and eliminates redundant storage by decomposing multivalued attributes into dependent tables, achieving a 1NF-compliant schema across all core entities.

### Core Entities & Relationships
* **Mission Logistics:** Tracks missions, trajectories, and launch events with exact date validations.
* **Personnel Management:** Manages control room staff and astronauts, resolving the M:N relationship for mission-specific duty shifts and roles.
* **Fleet & Inventory:** Manages spacecraft allocations and dynamic resource deductions.
* **Telemetry:** A polymorphic-style telemetry tracking system that logs real-time sensor readings tied to either specific spacecraft or celestial bodies.

### Advanced SQL Implementations
* **Stored Procedures:** Engineered procedures for automated mission briefings (`GetMissionBriefing`), trajectory fuel analysis (`GetHighFuelTrajectories`), and dynamic fleet management (`ReleaseSpacecraftToFleet`).
* **Automated Triggers:** Implemented `AFTER INSERT` triggers for automated resource stock deductions (`AutoDeductResourceStock`) and real-time crew status updates (`AutoActivateAstronaut`). Added database-level security triggers to restrict unauthorized schema modifications (`RestrictTableDropping`).
* **Complex Views:** Developed optimized views for rapid dashboard querying, including `CriticalCommandApprovals`, `FlightDetails`, and `AssignedSupplies`.

## Database Schema Highlights
The architecture successfully handles multiple edge cases, including resolving weak entities (e.g., `HealthRecord` tied to astronauts) and managing complex M:N associative entities for command approval hierarchies.
