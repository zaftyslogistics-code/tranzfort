---
title: Shared Features & Cross-Role Contracts
date: April 22, 2026
version: 1.1
purpose: Cross-role features, shared contracts, and system-wide specifications
---

# Shared Features & Cross-Role Contracts

## Document Overview
This document defines features, data structures, and contracts shared between Supplier, Trucker, and Admin roles. It establishes the source of truth for cross-role interactions.

---

## Table of Contents
1. [Shared Objects](#1-shared-objects)
2. [Core Data Models](#2-core-data-models)
3. [State Machines](#3-state-machines)
4. [API Contracts](#4-api-contracts)
5. [Permission Matrix](#5-permission-matrix)
6. [Notification Contracts](#6-notification-contracts)
7. [Common UI Components](#7-common-ui-components)
8. [Error Handling Standards](#8-error-handling-standards)

---

# 1. SHARED OBJECTS

## 1.1 Load Object

### Purpose
Central entity representing shipment demand from Supplier, visible to Truckers.

### Ownership
- **Authoritative Owner**: Supplier domain
- **Read-Only For**: Trucker domain, Admin domains
- **Created By**: Supplier
- **Modified By**: Supplier, System (state transitions)

### Core Fields

```dart
class Load {
  // Identity
  final String id;                    // UUID
  final String loadNumber;            // Human-readable (e.g., "L12345")
  final String supplierId;            // FK to suppliers table
  final String? truckerId;              // FK (null until assigned)
  
  // Route
  final Place origin;                 // Structured place object
  final Place destination;              // Structured place object
  final String? pickupAddress;          // Exact address (optional)
  final String? dropAddress;            // Exact address (optional)
  
  // Timing
  final DateTime pickupDate;
  final String pickupTimeWindow;        // "any", "morning", "afternoon", etc.
  final DateTime createdAt;
  final DateTime? publishedAt;
  final DateTime? closedAt;
  
  // Shipment Details
  final String materialType;
  final double minWeight;               // Tonnes
  final double maxWeight;               // Tonnes
  final int trucksRequired;
  final String loadType;                // "full", "partial"
  final String? packagingType;
  
  // Vehicle Requirements
  final String truckTypePreference;       // "any", "open", "closed", etc.
  final String tyrePreference;          // "any", "6", "10", etc.
  final String bodyPreference;          // "any", "standard", etc.
  final String? specialRequirements;
  
  // Pricing
  final String priceType;               // "fixed", "negotiable"
  final double? rateAmount;             // INR (null if negotiable)
  final int advancePercentage;          // 0-100
  
  // Instructions
  final String? loadingInstructions;
  final String? unloadingInstructions;
  final String? contactNotes;
  final List<String> requiredDocuments; // ["bilty", "pod", "eway"]
  
  // Status
  final LoadStatus status;
  final bool isSuperLoad;
  final bool isPaused;                  // Visibility paused
  
  // Metadata
  final double? estimatedDistance;      // KM
  final double? estimatedDuration;      // Hours
  final String? routePolyline;          // Encoded polyline for map
}
```

### Place Sub-Object

```dart
class Place {
  final String placeId;                 // Google Places ID
  final String name;                    // Display name (e.g., "Mumbai")
  final String? subLocality;            // Area/neighborhood
  final String city;                    // City level
  final String state;                   // State
  final String country;                 // Country ("India")
  final String? pincode;
  final double latitude;
  final double longitude;
  final String formattedAddress;        // Full address string
}
```

### Load Status Enum

```dart
enum LoadStatus {
  draft,                // Saved, not published
  active,               // Published, visible
  assignedPartial,      // Some trucks assigned
  assignedFull,         // All trucks assigned
  inTransit,            // At least one trip started
  completed,            // All trips completed
  filledOutsideApp,     // Supplier closed without in-app execution
  cancelled,            // Cancelled by supplier or admin
  expired,              // Lifecycle ended without fulfillment
  deactivated,          // Removed by admin
}
```

### State Transitions

```
draft → active (Publish)
active → assignedPartial (First assignment)
active → assignedFull (All slots filled)
active → cancelled (Cancel)
active → expired (Auto after 30 days)
active → filledOutsideApp (Manual close)
assignedPartial → assignedFull (More assignments)
assignedPartial → inTransit (Trip started)
assignedFull → inTransit (Trip started)
inTransit → completed (All trips done)
any → deactivated (Admin action)
```

---

## 1.2 Trip Object

### Purpose
Execution record created after load assignment, tracks shipment from pickup to delivery.

### Ownership
- **Authoritative Owner**: Trip domain (shared)
- **Created By**: System (on assignment approval)
- **Modified By**: Trucker (milestones), Supplier (confirmation), System (auto-transitions)

### Core Fields

```dart
class Trip {
  // Identity
  final String id;
  final String tripNumber;              // Human-readable (e.g., "T789")
  final String loadId;                  // FK to loads
  final String supplierId;              // FK to suppliers
  final String truckerId;               // FK to truckers
  
  // Route (Snapshot from load at creation)
  final Place origin;
  final Place destination;
  final double? distanceKm;
  
  // Load Details (Snapshot)
  final String materialType;
  final double tonnage;
  final String truckType;
  
  // Assigned Vehicle
  final String truckId;                 // FK to trucker's truck
  final String truckNumber;
  final String? driverName;
  final String? driverPhone;
  
  // Status
  final TripStatus status;
  final DateTime createdAt;             // Assignment time
  
  // Milestones
  final Milestone? assigned;              // Created
  final Milestone? pickupPending;         // Awaiting pickup
  final Milestone? pickedUp;              // Cargo loaded
  final Milestone? inTransit;             // Departed
  final Milestone? delivered;             // At destination
  final Milestone? proofSubmitted;        // POD uploaded
  final Milestone? completed;             // Confirmed/Auto-completed
  
  // Proof Documents
  final List<Document> documents;         // Bilty, POD, etc.
  
  // Dispute
  final String? disputeId;                // FK if disputed
  final bool hasDispute;
  
  // Timestamps
  final DateTime? estimatedPickup;
  final DateTime? estimatedDelivery;
  final DateTime? actualPickup;
  final DateTime? actualDelivery;
  
  // Tracking
  final Location? lastKnownLocation;
  final DateTime? lastLocationUpdate;
}
```

### Milestone Sub-Object

```dart
class Milestone {
  final DateTime timestamp;
  final Location? location;             // GPS capture
  final String? notes;
  final String capturedBy;              // "trucker", "supplier", "system"
  final List<String>? photoUrls;
}
```

### Trip Status Enum

```dart
enum TripStatus {
  assigned,             // Created, awaiting pickup
  pickupPending,        // Near/at pickup location
  pickedUp,             // Cargo loaded
  inTransit,            // Moving to destination
  delivered,            // Arrived, awaiting proof
  proofSubmitted,       // POD uploaded by trucker
  completed,            // Confirmed by supplier or auto
  disputed,             // Active dispute
  cancelled,            // Cancelled before completion
}
```

### Milestone Flow

```
assigned → pickupPending → pickedUp → inTransit → delivered → proofSubmitted → completed
```

---

## 1.3 Conversation Object

### Purpose
Chat communication linked to load or trip context.

### Ownership
- **Authoritative Owner**: Communication domain (shared)
- **Created By**: System (on first message)
- **Modified By**: Both parties (messages)

### Core Fields

```dart
class Conversation {
  final String id;
  final String? loadId;                 // Context: which load
  final String? tripId;                 // Context: which trip (if assigned)
  final String supplierId;              // Participant 1
  final String truckerId;               // Participant 2
  
  // Metadata
  final DateTime createdAt;
  final DateTime lastMessageAt;
  final String lastMessagePreview;
  final int supplierUnreadCount;
  final int truckerUnreadCount;
  
  // Status
  final bool isActive;                  // Closed if trip completed
  final bool supplierCanChat;           // Permission check
  final bool truckerCanChat;            // Permission check
}
```

### Message Sub-Object

```dart
class Message {
  final String id;
  final String conversationId;
  final String senderId;                // supplierId or truckerId
  final String senderRole;              // "supplier", "trucker"
  
  // Content
  final String type;                    // "text", "image", "location", "system"
  final String? text;
  final String? imageUrl;
  final Location? location;
  final String? systemEvent;            // "trip_assigned", "milestone", etc.
  
  // Metadata
  final DateTime sentAt;
  final DateTime? readAt;               // Null if unread
  final bool isDeleted;
}
```

### Chat Rules

1. **Context Required**: Every conversation linked to a load
2. **Verification Gate**: Trucker must be verified to send messages
3. **Retention**: 90 days, accessible for disputes
4. **No Deletion**: Messages cannot be deleted by users
5. **Auto-Close**: Conversation locked after trip completion (read-only)

---

## 1.4 Profile Object (Trucker/Supplier)

### Purpose
Shared identity structure for both roles.

### Core Fields

```dart
class Profile {
  // Identity
  final String id;                      // Same as auth user ID
  final String userRole;                // "supplier", "trucker"
  final String mobile;                  // Primary identifier
  final String? email;
  
  // Personal Info
  final String fullName;
  final String? profilePhotoUrl;
  
  // Location
  final Place? homeLocation;
  final List<String> operatingRegions;  // State codes
  
  // Verification
  final VerificationStatus verificationStatus;
  final DateTime? verifiedAt;
  final List<VerificationDocument> documents;
  
  // Status
  final TrustSafetyStatus trustSafetyStatus;
  final bool isBanned;
  final String? banReason;
  
  // Metadata
  final DateTime createdAt;
  final DateTime lastLoginAt;
  final String? pushToken;
}
```

### Verification Status Enum

```dart
enum VerificationStatus {
  unverified,
  pending,
  verified,
  rejected,
}
```

### Trust & Safety Status Enum

```dart
enum TrustSafetyStatus {
  normal,
  warned,
  restricted,
  suspended,
  banned,
}
```

---

# 2. CORE DATA MODELS

## 2.1 Document Model

```dart
class Document {
  final String id;
  final String ownerId;                 // uploader user ID
  final String ownerRole;               // "supplier", "trucker"
  final String documentType;            // "aadhaar", "pan", "bilty", "pod", etc.
  
  // File
  final String fileUrl;
  final String fileName;
  final String mimeType;
  final int fileSizeBytes;
  
  // Verification (for identity docs)
  final DocumentStatus status;
  final String? rejectionReason;
  final DateTime? verifiedAt;
  
  // Metadata
  final DateTime uploadedAt;
  final String? ocrExtractedData;       // JSON string
}

enum DocumentStatus {
  pending,
  verified,
  rejected,
}
```

## 2.2 Dispute Model

```dart
class Dispute {
  final String id;
  final String disputeNumber;           // Human-readable
  final String loadId;
  final String? tripId;
  
  // Participants
  final String raisedBy;                // User ID
  final String raisedByRole;            // "supplier", "trucker"
  final String againstUserId;           // Other party
  
  // Details
  final String category;                // "quantity", "payment", "fake_proof", etc.
  final String description;
  final List<Document> evidence;
  
  // Specifics
  final double? expectedTonnage;        // For quantity disputes
  final double? actualTonnage;
  final double? expectedAmount;         // For payment disputes
  final double? paidAmount;
  
  // Status
  final DisputeStatus status;
  final String? resolution;
  final String? resolutionNotes;
  final DateTime? resolvedAt;
  final String? resolvedBy;               // Admin ID
  
  // Metadata
  final DateTime createdAt;
  final List<DisputeEvent> timeline;
}

enum DisputeStatus {
  draft,
  submitted,
  underReview,
  needsMoreProof,
  resolved,
  rejected,
  enforcementApplied,
}
```

## 2.3 Notification Model

```dart
class Notification {
  final String id;
  final String userId;                  // Recipient
  final String userRole;                // "supplier", "trucker"
  
  // Content
  final String title;
  final String body;
  final String? imageUrl;
  
  // Type & Priority
  final NotificationType type;
  final NotificationPriority priority;  // low, normal, high, urgent
  
  // Linking
  final String? deepLink;               // app://load/123
  final String? relatedObjectType;      // "load", "trip", "conversation"
  final String? relatedObjectId;
  
  // Status
  final bool isRead;
  final DateTime? readAt;
  final bool isDelivered;               // Push delivery status
  
  // Metadata
  final DateTime createdAt;
  final DateTime? expiresAt;            // Auto-delete after
}

enum NotificationType {
  // Operational
  loadPublished,
  truckerInterested,
  assignmentCreated,
  milestoneUpdate,
  proofUploaded,
  tripCompleted,
  
  // Communication
  newMessage,
  missedCall,
  
  // Verification
  verificationApproved,
  verificationRejected,
  documentVerified,
  
  // System
  appUpdate,
  policyChange,
  maintenanceAlert,
  
  // Disputes
  disputeSubmitted,
  disputeResolved,
  
  // Super Load
  superLoadApproved,
  superLoadPaymentDue,
}
```

---

# 3. STATE MACHINES

## 3.1 Load Lifecycle State Machine

```
┌──────────────────────────────────────────────────────────────┐
│                         LOAD LIFECYCLE                       │
└──────────────────────────────────────────────────────────────┘

[draft]
   │
   │ POST
   ▼
[active] ←──────────────────────────┐
   │                                  │
   │ ASSIGN (partial)                 │ PAUSE
   ▼                                  │
[assignedPartial]                    ▼
   │                             [paused]
   │ ASSIGN (complete)                  │
   ▼                                  │ RESUME
[assignedFull] ──────────────────────┘
   │
   │ TRIP START
   ▼
[inTransit]
   │
   │ ALL TRIPS COMPLETE
   ▼
[completed]

Alternative paths:
[active] ──CANCEL──→ [cancelled]
[active] ──EXPIRE──→ [expired]
[active] ──FILLED_OUTSIDE──→ [filledOutsideApp]
[any] ──ADMIN──→ [deactivated]
```

### Transition Triggers

| From | To | Trigger | Actor |
|------|-----|---------|-------|
| draft | active | Publish | Supplier |
| active | paused | Pause Visibility | Supplier |
| paused | active | Resume Visibility | Supplier |
| active | assignedPartial | Assign First Trucker | System |
| assignedPartial | assignedFull | Assign All Trucks | System |
| assignedFull | inTransit | First Milestone Update | Trucker |
| inTransit | completed | All Trips Complete | System/Supplier |
| active | cancelled | Cancel Load | Supplier |
| active | expired | 30-day Auto-expire | System |

## 3.2 Trip Lifecycle State Machine

```
┌──────────────────────────────────────────────────────────────┐
│                         TRIP LIFECYCLE                       │
└──────────────────────────────────────────────────────────────┘

[assigned]
   │
   │ NEAR PICKUP / AT LOCATION
   ▼
[pickupPending]
   │
   │ CARGO LOADED
   ▼
[pickedUp]
   │
   │ DEPARTED
   ▼
[inTransit]
   │
   │ ARRIVED DESTINATION
   ▼
[delivered]
   │
   │ PROOF UPLOADED
   ▼
[proofSubmitted]
   │
   │ CONFIRMED / 48H AUTO
   ▼
[completed]

Alternative paths:
[any before completed] ──CANCEL──→ [cancelled]
[any] ──DISPUTE_RAISED──→ [disputed]
```

### Transition Triggers

| From | To | Trigger | Actor |
|------|-----|---------|-------|
| assigned | pickupPending | GPS near pickup / Manual | Trucker/System |
| pickupPending | pickedUp | Mark Picked Up | Trucker |
| pickedUp | inTransit | Mark In Transit | Trucker |
| inTransit | delivered | Mark Delivered | Trucker |
| delivered | proofSubmitted | Upload POD | Trucker |
| proofSubmitted | completed | Supplier Confirm / 48h Auto | Supplier/System |

## 3.3 Booking State Machine

```
┌──────────────────────────────────────────────────────────────┐
│                       BOOKING REQUEST                        │
└──────────────────────────────────────────────────────────────┘

[submitted]
   │
   ├───APPROVE──┐
   │              ▼
   │         [approved] ──→ Trip Created
   │
   ├───REJECT───→ [rejected]
   │
   └───WITHDRAW─→ [withdrawn] (by trucker)
```

---

# 4. API CONTRACTS

## 4.1 REST API Standards

### Base URL
```
Production: https://api.tranzfort.com/v1
Staging: https://staging-api.tranzfort.com/v1
```

### Authentication
```
Header: Authorization: Bearer <JWT_TOKEN>
```

### Response Format

```json
{
  "success": true,
  "data": { ... },
  "meta": {
    "page": 1,
    "perPage": 20,
    "total": 150,
    "totalPages": 8
  },
  "error": null
}
```

### Error Format

```json
{
  "success": false,
  "data": null,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Invalid input data",
    "details": {
      "origin": ["Origin city is required"]
    }
  }
}
```

### Error Codes

| Code | HTTP Status | Description |
|------|-------------|-------------|
| UNAUTHORIZED | 401 | Invalid or expired token |
| FORBIDDEN | 403 | Insufficient permissions |
| NOT_FOUND | 404 | Resource not found |
| VALIDATION_ERROR | 422 | Input validation failed |
| RATE_LIMITED | 429 | Too many requests |
| SERVER_ERROR | 500 | Internal server error |

## 4.2 Key Endpoints

### Loads

```
GET    /loads                    # List loads (with filters)
POST   /loads                    # Create load
GET    /loads/:id                # Get load details
PATCH  /loads/:id                # Update load (draft only)
POST   /loads/:id/publish        # Publish draft
POST   /loads/:id/pause          # Pause visibility
POST   /loads/:id/resume         # Resume visibility
POST   /loads/:id/cancel         # Cancel load
DELETE /loads/:id                # Delete draft
```

### Trips

```
GET    /trips                    # List trips
GET    /trips/:id                # Get trip details
POST   /trips/:id/milestones     # Update milestone
GET    /trips/:id/tracking       # Get live location
POST   /trips/:id/proof          # Upload proof document
```

### Bookings

```
GET    /loads/:id/requests        # List trucker interest
POST   /loads/:id/assign         # Assign trucker
POST   /bookings/:id/approve     # Approve booking
POST   /bookings/:id/reject      # Reject booking
```

### Conversations

```
GET    /conversations            # List conversations
GET    /conversations/:id        # Get conversation
POST   /conversations            # Create (if not exists)
GET    /conversations/:id/messages
POST   /conversations/:id/messages
POST   /messages/:id/read        # Mark as read
```

### Documents

```
POST   /uploads/presigned        # Get presigned URL
POST   /documents               # Register uploaded doc
GET    /documents/:id           # Get document
DELETE /documents/:id           # Delete document
```

## 4.3 Supabase RPC Catalog

### Load Operations

```sql
-- Create load with validation
CREATE OR REPLACE FUNCTION create_load(load_data JSONB)

-- Get loads for trucker feed (with filters)
CREATE OR REPLACE FUNCTION get_trucker_loads(
  p_trucker_id UUID,
  p_filters JSONB,
  p_page INT,
  p_per_page INT
)

-- Get supplier loads by status
CREATE OR REPLACE FUNCTION get_supplier_loads(
  p_supplier_id UUID,
  p_status TEXT[]
)

-- Search loads with full-text
CREATE OR REPLACE FUNCTION search_loads(
  p_query TEXT,
  p_filters JSONB
)
```

### Trip Operations

```sql
-- Create trip from assignment
CREATE OR REPLACE FUNCTION create_trip_from_booking(
  p_booking_id UUID
)

-- Update trip milestone
CREATE OR REPLACE FUNCTION update_trip_milestone(
  p_trip_id UUID,
  p_milestone TEXT,
  p_location JSONB,
  p_photos TEXT[]
)

-- Get trip with all details
CREATE OR REPLACE FUNCTION get_trip_detail(
  p_trip_id UUID
)

-- Get trucker active trips
CREATE OR REPLACE FUNCTION get_trucker_active_trips(
  p_trucker_id UUID
)
```

### Verification

```sql
-- Submit verification documents
CREATE OR REPLACE FUNCTION submit_verification(
  p_user_id UUID,
  p_documents JSONB[]
)

-- Check verification status
CREATE OR REPLACE FUNCTION get_verification_status(
  p_user_id UUID
)

-- Admin: Approve verification
CREATE OR REPLACE FUNCTION approve_verification(
  p_user_id UUID,
  p_admin_id UUID
)
```

---

# 5. PERMISSION MATRIX

## 5.1 Feature Access by Role and Verification

| Feature | Supplier Unverified | Supplier Verified | Trucker Unverified | Trucker Verified |
|---------|---------------------|-------------------|-------------------|------------------|
| **Loads** |
| Create Load | ❌ | ✅ | N/A | N/A |
| View Own Loads | ❌ | ✅ | N/A | N/A |
| Browse Marketplace | N/A | N/A | ✅ | ✅ |
| View Load Detail | N/A | N/A | ✅ | ✅ |
| Contact on Load | N/A | N/A | ❌ | ✅ |
| **Trips** |
| Create/Manage | ❌ | ✅ | N/A | N/A |
| Execute (Update Milestones) | N/A | N/A | ❌ | ✅ |
| View Assigned | ❌ | ✅ | ❌ | ✅ |
| Upload Proof | N/A | N/A | ❌ | ✅ |
| **Communication** |
| Initiate Chat | ❌ | ✅ | ❌ | ✅ |
| Reply to Chat | ✅ | ✅ | ✅ | ✅ |
| Voice Call | ❌ | ✅ | ❌ | ✅ |
| **Verification** |
| Submit Documents | ✅ | ✅ | ✅ | ✅ |
| View Status | ✅ | ✅ | ✅ | ✅ |
| **Account** |
| Edit Profile | ✅ | ✅ | ✅ | ✅ |
| Add Vehicles | N/A | N/A | ✅ | ✅ |
| **Disputes** |
| Raise Dispute | ❌ | ✅ | ❌ | ✅ |
| View Own Disputes | ❌ | ✅ | ❌ | ✅ |

## 5.2 Object-Level Permissions

### Load Permissions

| Action | Owner (Supplier) | Assigned Trucker | Other Truckers | Admin |
|--------|------------------|------------------|----------------|-------|
| View | ✅ | ✅ | ✅ (list only) | ✅ |
| Edit | ✅ (draft only) | ❌ | ❌ | ✅ |
| Publish | ✅ | N/A | N/A | ✅ |
| Cancel | ✅ | ❌ | ❌ | ✅ |
| Assign | ✅ | ❌ | N/A | ✅ |
| Pause/Resume | ✅ | ❌ | ❌ | ✅ |

### Trip Permissions

| Action | Supplier | Assigned Trucker | Admin |
|--------|----------|------------------|-------|
| View | ✅ | ✅ | ✅ |
| Update Milestone | ❌ | ✅ | ✅ |
| Upload Proof | ❌ | ✅ | ✅ |
| Confirm Complete | ✅ | ❌ | ✅ |
| Cancel | ✅ (early) | ❌ | ✅ |

### Conversation Permissions

| Action | Supplier | Trucker | Admin |
|--------|----------|---------|-------|
| View Messages | ✅ | ✅ | ✅ (if reported) |
| Send Message | ✅ | ✅ (if verified) | ❌ |
| Delete | ❌ | ❌ | ❌ |
| Export | ✅ (own) | ✅ (own) | ✅ |

---

# 6. NOTIFICATION CONTRACTS

## 6.1 Notification Triggers

| Event | Recipients | Deep Link |
|-------|-----------|-----------|
| Load Published | Matching truckers | `/find-loads` |
| Trucker Interested | Supplier | `/load/:id/requests` |
| Assignment Approved | Trucker | `/trip/:id` |
| Trip Milestone Update | Supplier | `/trip/:id` |
| Proof Uploaded | Supplier | `/trip/:id` |
| New Message | Counterparty | `/chat/:id` |
| Verification Approved | User | `/verification` |
| Verification Rejected | User | `/verification` |
| Dispute Resolved | Both parties | `/dispute/:id` |

## 6.2 Notification Priority Rules

**Urgent (Push + SMS + Email)**:
- Assignment approved
- Milestone delay detected
- Dispute resolution
- Security alert

**High (Push + Email)**:
- New message
- Trucker interested
- Proof uploaded
- Verification status change

**Normal (Push only)**:
- Load published (trucker feed)
- General updates
- System announcements

**Low (In-app only)**:
- Daily summaries
- Tips/suggestions

## 6.3 Quiet Hours

**Configurable**: 10 PM - 7 AM (default)

**Override**: Urgent notifications always delivered

---

# 7. COMMON UI COMPONENTS

## 7.1 Shared Component Library

### StatusBadge

```dart
StatusBadge(
  status: LoadStatus.active,
  size: StatusBadgeSize.small, // small, medium, large
)
```

**Variants**:
- Green: Active, Verified, Completed, Approved
- Blue: Assigned, In Transit
- Orange: Pending, Pickup Pending
- Red: Rejected, Cancelled, Disputed, Banned
- Grey: Draft, Expired
- Yellow: Warning, Needs Attention

### LoadCard

```dart
LoadCard(
  load: Load,
  variant: LoadCardVariant.compact, // compact, detailed
  context: CardContext.truckerFeed, // truckerFeed, supplierList
  onTap: () {},
  onChat: () {},
  onCall: () {},
  onAssign: () {},
)
```

### TripCard

```dart
TripCard(
  trip: Trip,
  variant: TripCardVariant.supplier, // supplier, trucker
  showMilestones: true,
  onTrack: () {},
  onContact: () {},
)
```

### ConversationListItem

```dart
ConversationListItem(
  conversation: Conversation,
  currentUserRole: UserRole.supplier,
  onTap: () {},
)
```

### PlaceInput

```dart
PlaceInput(
  label: "Origin City",
  value: selectedPlace,
  onChanged: (place) {},
  required: true,
)
```

**Features**:
- Google Places Autocomplete
- Recent places suggestion
- Current location option
- Validation

### DocumentUploader

```dart
DocumentUploader(
  documentType: DocumentType.aadhaar,
  onUpload: (file) {},
  maxSizeMB: 10,
  allowedTypes: ['jpg', 'png', 'pdf'],
)
```

### MilestoneTimeline

```dart
MilestoneTimeline(
  milestones: trip.milestones,
  currentStatus: trip.status,
  orientation: TimelineOrientation.vertical,
)
```

## 7.2 Design System Constants

### Colors

```dart
class AppColors {
  // Primary
  static const primary = Color(0xFF00897B); // Teal
  static const primaryDark = Color(0xFF004D40);
  static const primaryLight = Color(0xFFB2DFDB);
  
  // Status
  static const success = Color(0xFF4CAF50);
  static const warning = Color(0xFFFF9800);
  static const error = Color(0xFFE53935);
  static const info = Color(0xFF2196F3);
  
  // Neutrals
  static const background = Color(0xFFF5F5F5);
  static const surface = Color(0xFFFFFFFF);
  static const border = Color(0xFFE0E0E0);
}
```

### Typography

```dart
class AppTextStyles {
  static const heading1 = TextStyle(fontSize: 28, fontWeight: FontWeight.bold);
  static const heading2 = TextStyle(fontSize: 24, fontWeight: FontWeight.bold);
  static const heading3 = TextStyle(fontSize: 20, fontWeight: FontWeight.w600);
  static const body1 = TextStyle(fontSize: 16, fontWeight: FontWeight.normal);
  static const body2 = TextStyle(fontSize: 14, fontWeight: FontWeight.normal);
  static const caption = TextStyle(fontSize: 12, fontWeight: FontWeight.normal);
}
```

### Spacing

```dart
class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 48.0;
}
```

---

# 8. ERROR HANDLING STANDARDS

## 8.1 Error Categories

### Validation Errors
- Invalid input format
- Missing required fields
- Constraint violations

### Business Logic Errors
- Invalid state transition
- Permission denied
- Resource not found
- Duplicate operation

### System Errors
- Network failure
- Server error
- Timeout
- Service unavailable

## 8.2 Error Display Patterns

### Field-Level Errors
```
┌─────────────────────────────────────┐
│  Email Address                     │
│  ┌─────────────────────────────┐  │
│  │ user@example                │  │
│  └─────────────────────────────┘  │
│  ⚠️ Please enter a valid email   │
└─────────────────────────────────────┘
```

### Form-Level Errors
```
┌─────────────────────────────────────┐
│  ⚠️ Please fix the following errors: │
│  • Origin city is required          │
│  • Rate must be greater than 0      │
└─────────────────────────────────────┘
```

### Page-Level Errors
```
┌─────────────────────────────────────┐
│                                     │
│         ⚠️                         │
│    Something went wrong            │
│                                     │
│    We couldn't load your trips.     │
│    Please try again.               │
│                                     │
│         [Retry]                    │
│                                     │
└─────────────────────────────────────┘
```

## 8.3 Retry Strategies

| Operation | Max Retries | Backoff Strategy |
|-----------|-------------|------------------|
| API Calls | 3 | Exponential (1s, 2s, 4s) |
| File Upload | 2 | Linear (2s, 4s) |
| Realtime Connection | Infinite | Exponential (max 30s) |
| Location Fetch | 2 | Immediate |

## 8.4 Offline Handling

### Detection
- Monitor connectivity status
- Show persistent offline banner

### Behavior
- Cache recent data for viewing
- Queue mutations for sync
- Disable actions requiring network
- Show "Requires connection" message

### Sync on Reconnect
- Auto-sync queued operations
- Show sync progress
- Conflict resolution UI if needed

---

# 9. SECURITY & COMPLIANCE

## 9.1 Data Protection

### PII Handling
- Encrypt at rest (AES-256)
- TLS 1.3 in transit
- Mask in logs (mobile: *** *** 1234)

### Document Storage
- Private buckets only
- Signed URLs with expiry (15 min)
- Access logging enabled

### Data Retention
- Messages: 90 days
- Documents: 7 years (business records)
- Deleted accounts: 30-day grace + 90-day purge

## 9.2 Rate Limiting

| Endpoint | Limit | Window |
|----------|-------|--------|
| Auth attempts | 5 | 15 minutes |
| Message send | 60 | 1 minute |
| Load create | 20 | 1 hour |
| API general | 1000 | 1 hour |

## 9.3 Audit Logging

Logged Events:
- Authentication (success/fail)
- State changes (loads, trips, disputes)
- Document uploads/deletions
- Admin actions
- Security events

---

# 10. APPENDIX

## 10.1 Glossary

| Term | Definition |
|------|------------|
| **Load** | Shipment demand posted by Supplier |
| **Trip** | Execution instance created on assignment |
| **Booking** | Trucker interest/assignment request |
| **Milestone** | Key event in trip lifecycle |
| **POD** | Proof of Delivery document |
| **Bilty/LR** | Loading Receipt document |
| **Super Load** | Premium promoted load with guarantee |
| **Verification** | Identity and document approval process |

## 10.2 Abbreviations

| Abbreviation | Full Form |
|--------------|-----------|
| FK | Foreign Key |
| PII | Personally Identifiable Information |
| POD | Proof of Delivery |
| LR | Lorry Receipt (same as Bilty) |
| GPS | Global Positioning System |
| API | Application Programming Interface |
| JWT | JSON Web Token |
| OTP | One Time Password |

## 10.3 Revision History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2026-04-20 | Initial document |
| 1.1 | 2026-04-22 | Added microscopic detail level |

---

*End of Shared Features & Cross-Role Contracts*
*Last Updated: April 22, 2026*
