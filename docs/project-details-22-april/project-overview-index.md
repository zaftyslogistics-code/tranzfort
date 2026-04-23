---
title: TranZfort Project Overview Index
date: April 22, 2026
version: 1.0
purpose: Master index and navigation hub for all project documentation
---

# TranZfort Project Overview Index

## Quick Stats

| Metric | Count |
|--------|-------|
| **Total Screens** | 40+ (Supplier 15, Trucker 15, Admin 10) |
| **Total Features** | 80+ major features |
| **User Roles** | 4 (Supplier, Trucker, Ops Admin, Super Admin) |
| **Navigation Routes** | 33 (with metadata) |
| **Database Tables** | 40+ |
| **API Endpoints** | 60+ |

---

## Documentation Structure

### This Directory (project-details-22-april/)

| Document | Purpose | Size | Status |
|----------|---------|------|--------|
| [project-overview-index.md](./project-overview-index.md) | This file - master navigation | Medium | Active |
| [trucker-features-microscopic.md](./trucker-features-microscopic.md) | All Trucker screens, features, components | Large | Active |
| [supplier-features-microscopic.md](./supplier-features-microscopic.md) | All Supplier screens, features, components | Large | Active |
| [shared-features-and-contracts.md](./shared-features-and-contracts.md) | Cross-role features, data models, API contracts | Large | Active |
| [ai-voice-assistant-v3-implementation-ready.md](./ai-voice-assistant-v3-implementation-ready.md) | AI assistant implementation plan | Large | Deferred |
| [ai-assistant-brainstorm-revised.md](./ai-assistant-brainstorm-revised.md) | AI assistant brainstorm and design | Medium | Deferred |
| [bot-brainstorm-implementation-plan.md](./bot-brainstorm-implementation-plan.md) | Bot integration plan | Medium | Deferred |

### How to Use This Documentation

1. **New to the project?** Start with this index, then read shared-features-and-contracts.md
2. **Working on Trucker features?** Reference trucker-features-microscopic.md
3. **Working on Supplier features?** Reference supplier-features-microscopic.md
4. **Need data model definitions?** Check shared-features-and-contracts.md Section 2
5. **Need state machine rules?** Check shared-features-and-contracts.md Section 3
6. **Need API endpoint specs?** Check shared-features-and-contracts.md Section 4

---

## Role-Based Feature Map

### Trucker Features (trucker-features-microscopic.md)

| # | Feature Area | Key Screens | Complexity |
|---|-------------|-------------|------------|
| 1 | [Authentication & Onboarding](#1-authentication--onboarding) | Splash, Auth Entry, Role Selection, Profile Completion | Medium |
| 2 | [Home Dashboard](#2-home-dashboard) | Trucker Home | Low |
| 3 | [Load Discovery](#3-load-discovery-find-loads) | Find Loads, Filters, Advanced Search | High |
| 4 | [Load Detail](#4-load-detail--evaluation) | Load Detail, Map Preview, Share | Medium |
| 5 | [Trip Management](#5-trip-management) | Trips List, Trip Detail, Milestone Updates | High |
| 6 | [Communication](#6-communication) | Messages List, Chat Detail | Medium |
| 7 | [Verification & Profile](#7-verification--profile) | Verification Flow, Document Upload | High |
| 8 | [Vehicle Management](#8-vehicle-management) | Vehicle List, Add/Edit Truck | Medium |
| 9 | [Disputes & Support](#9-disputes--support) | Disputes List, Raise Dispute, Support Tickets | Medium |
| 10 | [Account & Settings](#10-account--settings) | Account, Edit Profile, Data Deletion | Low |
| 11 | [Notifications](#11-notifications) | Notifications List, Settings | Low |

### Supplier Features (supplier-features-microscopic.md)

| # | Feature Area | Key Screens | Complexity |
|---|-------------|-------------|------------|
| 1 | [Authentication & Onboarding](#1-authentication--onboarding-1) | Splash, Auth Entry, Role Selection, Business Profile | Medium |
| 2 | [Home Dashboard](#2-home-dashboard-1) | Supplier Home, KPI Cards | Medium |
| 3 | [Load Management](#3-load-management) | Post Load, My Loads, Load Detail | High |
| 4 | [Trip Monitoring](#4-trip-monitoring) | Trips List, Trip Detail, Live Tracking | High |
| 5 | [Booking & Assignment](#5-booking--assignment) | View Requests, Assign Trucker | Medium |
| 6 | [Communication](#6-communication-1) | Inbox, Chat Detail (Grouped by Load) | Medium |
| 7 | [Verification & Profile](#7-verification--profile-1) | Business Verification, Profile Edit | High |
| 8 | [Super Load](#8-super-load) | Request Promotion, Account Details, Status | High |
| 9 | [Documents & Proof](#9-documents--proof) | Document Upload, Viewer | Low |
| 10 | [Disputes & Support](#10-disputes--support-1) | Disputes, Raise Dispute, Support | Medium |
| 11 | [Account & Settings](#11-account--settings-1) | Account, Settings, Deletion | Low |
| 12 | [Notifications](#12-notifications) | Notifications, Preferences | Low |

---

## Cross-Cutting Concerns

### Shared Between All Roles

| Concern | Document | Section |
|---------|----------|---------|
| Data Models (Load, Trip, Message) | shared-features-and-contracts.md | Section 2 |
| State Machines | shared-features-and-contracts.md | Section 3 |
| API Contracts | shared-features-and-contracts.md | Section 4 |
| Permission Matrix | shared-features-and-contracts.md | Section 5 |
| Notification System | shared-features-and-contracts.md | Section 6 |
| UI Component Library | shared-features-and-contracts.md | Section 7 |
| Error Handling | shared-features-and-contracts.md | Section 8 |
| Security & Compliance | shared-features-and-contracts.md | Section 9 |

---

## Implementation Status Reference

### Current Active TODO Files (Latest First)

| File | Date | Focus Area | Status |
|------|------|------------|--------|
| TODO-22-april.md | Apr 22 | AI integration rollback documentation | Complete |
| TODO-21-april.md | Apr 21 | UI/UX Phase 6 - Dark cards + TTS | Complete |
| TODO-20-april.md | Apr 20 | Auth page visual improvements | Complete |
| TODO-17-april.md | Apr 17 | Navigation Plan C | Complete |
| TODO-16-april.md | Apr 16 | Reviews & trust scores | Complete |
| TODO-12-april.md | Apr 12 | Profile location fixes | Complete |
| TODO-11-april.md | Apr 11 | Phase B fixes | Complete |

### Deferred Features

| Feature | Decision Date | Reason | Future Plan |
|---------|---------------|--------|-------------|
| AI Assistant (Nancy Bot) | Apr 22, 2026 | Inference time and quality not meeting expectations | Will be revisited in future version with different approach |
| Bot Integration | Apr 22, 2026 | AI integration deferred | Will be revisited after AI assistant is successfully implemented |

### Historical Documentation Sets

| Directory | Contents | Status |
|-----------|----------|--------|
| docs/trucker/ | Trucker product specs, phases 1-11 | Reference |
| docs/supplier/ | Supplier product specs, phases 1-12 | Reference |
| docs/ops-admin/ | Ops Admin product specs | Reference |
| docs/super-admin/ | Super Admin product specs | Reference |
| docs/TODO&Progress/ | Daily progress tracking | Archive |

---

## Architecture Decision Records

### Locked Decisions (Cannot Change Without Discussion)

| # | Decision | Impact | Date Locked |
|---|----------|--------|-------------|
| 1 | Off-platform settlement for standard loads | No in-app wallet | Mar 2026 |
| 2 | City-level GPS resolution (not village) | Location accuracy | Mar 2026 |
| 3 | Verification required for contact actions | User access gating | Mar 2026 |
| 4 | No hard delete on account deletion | Data retention | Mar 2026 |
| 5 | Compact load cards (not detailed in feed) | Feed design | Mar 2026 |
| 6 | Chat grouped by load (not global) | Conversation architecture | Mar 2026 |
| 7 | Truck edits trigger re-approval | Vehicle workflow | Mar 2026 |
| 8 | Draft loads editable, published loads not | Load lifecycle | Mar 2026 |
| 9 | Super Load is only monetized workflow | Business model | Mar 2026 |
| 10 | 48h auto-complete for trips | Trip closure | Mar 2026 |

---

## Database Schema Quick Reference

### Core Tables

| Table | Domain | Purpose |
|-------|--------|---------|
| profiles | Identity | Base user identity |
| suppliers | Identity | Supplier-specific data |
| truckers | Identity | Trucker-specific data |
| admin_users | Identity | Admin access control |
| loads | Marketplace | Load postings |
| trips | Operations | Trip execution records |
| bookings | Operations | Assignment requests |
| conversations | Communication | Chat threads |
| messages | Communication | Chat messages |
| trucks | Fleet | Vehicle records |
| documents | Verification | Uploaded documents |
| disputes | Support | Dispute records |
| notifications | System | User notifications |
| reviews | Trust | User ratings |

---

## Development Guidelines

### Layering Rules (docs > schema > code)
1. Documentation is source of truth
2. Database schema implements docs
3. Code implements schema
4. No code-first changes without doc updates

### File Size Limits
- Provider files: <300 lines
- Repository files: <400 lines
- UI screen files: <500 lines
- Break into components/widgets if exceeded

### Data Flow Pattern
```
UI → Provider/State → Repository → Backend (Supabase)
 ↑_________________________________________↓
              Realtime Updates
```

---

## Contact & Ownership

| Area | Owner | Documentation |
|------|-------|---------------|
| Trucker Product | Product Team | trucker-features-microscopic.md |
| Supplier Product | Product Team | supplier-features-microscopic.md |
| Shared Contracts | Architecture | shared-features-and-contracts.md |
| Database Schema | Backend Team | docs/20-36-schema-* |
| UI/UX Design | Design Team | docs/37-46-ui-ux-* |
| Navigation | Mobile Team | docs/navigation-architecture.md |

---

## Glossary of Terms

| Term | Definition |
|------|------------|
| **Load** | Shipment demand posted by Supplier |
| **Trip** | Execution instance after trucker assignment |
| **Booking** | Trucker expression of interest |
| **Milestone** | Key trip event (pickup, delivery, etc.) |
| **POD** | Proof of Delivery document |
| **Bilty/LR** | Loading Receipt document |
| **Super Load** | Premium promoted load with guarantee |
| **Shell** | Bottom navigation container |
| **PopScope** | Flutter back button interception |
| **CTA** | Call to Action (button/link) |

---

## Document Maintenance

**Last Updated**: April 22, 2026
**Update Frequency**: After each major feature completion
**Responsible**: Lead Developer / Product Manager
**Review Cycle**: Weekly during active development

**Update Rules**:
- Add new screens to role-specific docs
- Update status tables after feature completion
- Add new decisions to Locked Decisions section
- Version bump on significant changes

---

*End of Project Overview Index*
*TranZfort v1.1 Product Documentation*
