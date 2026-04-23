---
title: Supplier Features - Microscopic Detail
date: April 22, 2026
version: 1.1
purpose: Screen-by-screen, feature-by-feature microscopic breakdown of Supplier functionality
---

# Supplier Features - Microscopic Detail

## Document Overview
This document provides microscopic-level detail of every Supplier feature, screen, component, and function. Each section breaks down a major feature area into its atomic components.

---

## Table of Contents
1. [Authentication & Onboarding](#1-authentication--onboarding)
2. [Home Dashboard](#2-home-dashboard)
3. [Load Management](#3-load-management)
4. [Trip Monitoring](#4-trip-monitoring)
5. [Booking & Assignment](#5-booking--assignment)
6. [Communication](#6-communication)
7. [Verification & Profile](#7-verification--profile)
8. [Super Load](#8-super-load)
9. [Documents & Proof](#9-documents--proof)
10. [Disputes & Support](#10-disputes--support)
11. [Account & Settings](#11-account--settings)
12. [Notifications](#12-notifications)

---

# 1. AUTHENTICATION & ONBOARDING

## 1.1 Entry Points

### 1.1.1 Splash Screen
- **Purpose**: Branded loading screen with logo animation
- **Components**:
  - Animated logo (main-logo-transparent.png, 120px)
  - App name "TranZfort for Suppliers"
  - Loading indicator
  - Version number (bottom)
- **Functionality**:
  - Check for existing session
  - Route to auth if no session
  - Route to Home if session exists
- **Duration**: 2-3 seconds minimum

### 1.1.2 Auth Entry Screen
- **Purpose**: Main login/registration gateway
- **Layout (Top to Bottom)**:
  1. AppBar with TTS action button (accessibility)
  2. App logo (80px height)
  3. Welcome title: "Supplier Portal"
  4. Subtitle: "Manage your shipments efficiently"
  5. **Google Sign-In Button** (white card with official logo)
  6. Trust microcopy: "Fastest way to get started"
  7. "or with email" divider
  8. Email text field
  9. Password field with visibility toggle
  10. "Sign In" outline button
  11. Row: "Sign Up" link + "Forgot Password?" link

### 1.1.3 Role Selection Screen
- **Purpose**: User selects role during onboarding
- **Options**:
  - Supplier (Shipper/Business)
  - Trucker (Transporter)
- **Validation**: Required selection
- **PopScope**: Confirmation dialog to prevent accidental exit

### 1.1.4 Onboarding Profile Completion
- **Purpose**: Collect business profile information
- **Fields**:
  - Full Name (owner/contact person)
  - Mobile Number (with OTP verification)
  - Email (optional but recommended)
  - Company Name (if applicable)
  - Business Address (Google Places autocomplete)
  - Operating Region/State
- **GPS Integration**:
  - Check GPS enabled
  - Request permissions
  - City-level resolution preferred
- **PopScope**: Confirmation dialog for unsaved changes

---

# 2. HOME DASHBOARD

## 2.1 Supplier Home Screen

### 2.1.1 Screen Overview
- **Route**: `/home`
- **Shell**: Primary (bottom navigation)
- **Purpose**: Command center for business operations

### 2.1.2 Page Sections (Top to Bottom)

#### Section 1: Supplier Identity Header
```
┌─────────────────────────────────────┐
│  Welcome back,                      │
│  ABC Logistics                      │
│  [Verified Badge]                   │
└─────────────────────────────────────┘
```

#### Section 2: Readiness Banners

**Verification Banner** (if incomplete):
- Yellow/Orange background
- Icon: Warning
- Text: "Complete verification to post loads"
- **CTA**: "Complete Now"

**Super Load Account Banner** (if incomplete):
- Blue background
- Icon: Info
- Text: "Complete account details for Super Load"
- **CTA**: "Complete Details"

#### Section 3: KPI Row (Key Performance Indicators)

**Horizontal scrollable cards**:

```
┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐
│ Active   │ │ Today's  │ │ Pending  │ │ Total    │
│ Loads    │ │ Trips    │ │ Chats    │ │ Loads    │
│    12    │ │    3     │ │    8     │ │   156    │
└──────────┘ └──────────┘ └──────────┘ └──────────┘
```

**Metrics**:
1. Active Loads: Currently open/published
2. Today's Trips: Active shipments
3. Pending Chats: Unread messages
4. Total Loads: All-time posted

#### Section 4: Quick Actions Rail

**Horizontal row**:
1. **"Post Load"** (Primary) → Routes to Post Load
2. **"My Loads"** → Routes to My Loads
3. **"View Trips"** → Routes to Trips
4. **"Messages"** → Routes to Messages

#### Section 5: Recent Loads Section

**Purpose**: Show last 3-5 loads needing attention

**Content**:
```
┌─────────────────────────────────────┐
│ Recent Loads           [View All →] │
│ ─────────────────────────────────── │
│ Load #12345: Mumbai → Delhi         │
│ Status: Awaiting Assignment    2h   │
│ ─────────────────────────────────── │
│ Load #12344: Pune → Chennai         │
│ Status: 3 Truckers Interested   5h    │
└─────────────────────────────────────┘
```

#### Section 6: Active Trips Section

**Content**:
```
┌─────────────────────────────────────┐
│ Active Trips           [View All →] │
│ ─────────────────────────────────── │
│ Trip #T789: Delhi → Mumbai          │
│ Status: In Transit • ETA: 6 hours    │
│ Trucker: XYZ Transport              │
└─────────────────────────────────────┘
```

#### Section 7: Recent Conversations Preview

**Content**:
```
┌─────────────────────────────────────┐
│ Recent Messages        [Open Inbox] │
│ ─────────────────────────────────── │
│ [Unread dot] ABC Transport          │
│ "Can we reschedule pickup?"           │
│                                     │
│ [No dot] XYZ Logistics              │
│ "POD uploaded, please check"         │
└─────────────────────────────────────┘
```

### 2.1.3 Technical Details
- **Provider**: `supplierHomeProvider`
- **Refresh**: Pull-to-refresh
- **Loading**: Skeleton screens
- **Empty States**: CTA to create first load

---

# 3. LOAD MANAGEMENT

## 3.1 Post Load Screen

### 3.1.1 Screen Overview
- **Route**: `/post-load`
- **Shell**: Detail (with back arrow)
- **Purpose**: Create and publish new load
- **Status**: MVP critical form

### 3.1.2 Form Structure

#### Section 1: Route and Schedule

**Origin City**:
- Label: "From City"
- Input: Searchable dropdown with Google Places
- Autocomplete with recent cities
- Required validation

**Origin Exact Address** (Optional):
- Label: "Pickup Address (Optional)"
- Input: Text field
- Helper: "Exact address helps truckers find location"

**Destination City**:
- Label: "To City"
- Input: Searchable dropdown
- Required validation

**Destination Address** (Optional):
- Label: "Drop Address (Optional)"
- Input: Text field

**Pickup Date**:
- Label: "Pickup Date"
- Input: Date picker
- Minimum: Today
- Maximum: Today + 90 days
- Required

**Pickup Time Window**:
- Label: "Pickup Time"
- Input: Dropdown
- Options: Any Time, Morning (6-12), Afternoon (12-4), Evening (4-8), Night (8-6)
- Default: Any Time

**Estimated Distance** (Auto-calculated):
- Display: "~1,450 km" (if available)
- Source: Google Maps API

#### Section 2: Load Details

**Material Type**:
- Label: "Material"
- Input: Dropdown
- Options: Cement, Steel, Sand, Grains, Coal, Container, FMCG, Other
- Required

**Minimum Weight**:
- Label: "Min Weight (Tonnes)"
- Input: Number field
- Minimum: 1
- Maximum: 50
- Required

**Maximum Weight**:
- Label: "Max Weight (Tonnes)"
- Input: Number field
- Must be >= Minimum
- Required

**Number of Trucks**:
- Label: "Trucks Required"
- Input: Number stepper (1-20)
- Default: 1
- Required

**Load Type**:
- Label: "Load Type"
- Input: Radio buttons
- Options: Full Load, Part Load
- Default: Full Load

**Packaging Type**:
- Label: "Packaging"
- Input: Dropdown
- Options: Loose, Bags, Boxes, Container, Other
- Default: Loose

#### Section 3: Vehicle Requirements

**Truck Type**:
- Label: "Preferred Truck Type"
- Input: Dropdown
- Options: Any, Open Body, Closed Body, Container, Trailer
- **Default: Any** (Locked rule)
- Helper: "Selecting 'Any' gives maximum visibility"

**Tyre Count**:
- Label: "Tyre Requirement"
- Input: Dropdown
- Options: Any, 6-wheel, 10-wheel, 12-wheel, 14-wheel
- **Default: Any** (Locked rule)

**Body Type**:
- Label: "Body Type"
- Input: Dropdown
- Options: Any, Standard, High Side, Platform, Tipper
- **Default: Any** (Locked rule)

**Special Requirements** (Text):
- Label: "Special Requirements"
- Input: Multi-line text
- Placeholder: "e.g., Refrigerated, Hazmat certification required"
- Optional

#### Section 4: Pricing

**Price Type**:
- Label: "Pricing Type"
- Input: Radio buttons
- Options: Fixed Rate, Negotiable
- Default: Fixed Rate

**Rate Amount**:
- Label: "Rate (₹)"
- Input: Currency field
- Placeholder: "e.g., 25000"
- Required if Fixed Rate selected

**Advance Percentage**:
- Label: "Advance Required (%)"
- Input: Slider (0-50%)
- Default: 0%
- Display value: "No Advance" or "20% Advance"

**Rate Per Tonne** (Auto-calculated):
- Display: "~₹1,250 per tonne"
- Calculated: Rate / Average Weight

#### Section 5: Instructions and Notes

**Loading Instructions**:
- Label: "Loading Instructions"
- Input: Multi-line text
- Placeholder: "Any specific requirements for loading..."
- Max: 500 characters

**Unloading Instructions**:
- Label: "Unloading Instructions"
- Input: Multi-line text
- Placeholder: "Any specific requirements at destination..."

**Contact Notes**:
- Label: "Contact Information"
- Input: Multi-line text
- Placeholder: "Additional contact person, landmark, etc."

**Document Requirements**:
- Label: "Documents Required from Trucker"
- Checkboxes:
  - [ ] Bilty/LR
  - [ ] POD (Proof of Delivery)
  - [ ] E-way Bill
  - [ ] Insurance

### 3.1.3 Form Actions

**Primary CTA**: "Post Load"
- Enabled when: All required fields valid
- On Tap: Validate form, show confirmation, publish

**Secondary CTA**: "Save as Draft"
- Saves current state
- No validation required
- Shows success toast

**Tertiary CTA**: "Discard"
- Shows confirmation dialog
- "You have unsaved changes. Discard?"
- Options: "Keep Editing", "Discard"

**Super Load CTA**: "Request Super Load Promotion"
- Visible only after load is valid
- Opens Super Load request flow

### 3.1.4 Form Validation

**Real-time Validation**:
- Field-level validation on blur
- Error messages below fields
- Red border for invalid fields

**Submit Validation**:
- Scroll to first error
- Shake animation on error fields
- Summary error banner at top

**Validation Rules**:
- Origin and Destination cannot be same
- Max Weight >= Min Weight
- Pickup Date must be future
- Rate must be > 0 (if fixed)

### 3.1.5 Success State

**Success Screen**:
```
┌─────────────────────────────────────┐
│           ✓                         │
│     Load Posted Successfully!       │
│                                     │
│  Load #12345 is now live and        │
│  visible to verified truckers.      │
│                                     │
│  [Share Load]  [View Load]          │
│                                     │
│  Request Super Load promotion?      │
│  [Request Now] [Maybe Later]        │
└─────────────────────────────────────┘
```

**Auto-redirect**: After 5 seconds to My Loads

## 3.2 My Loads Screen

### 3.2.1 Screen Overview
- **Route**: `/my-loads`
- **Shell**: Primary (bottom navigation)
- **Purpose**: Central workspace for all loads

### 3.2.2 Tab Structure

**Tab 1: Drafts**
- Unpublished saved loads
- Edit/resume capability
- "Post Now" CTA

**Tab 2: Open**
- Published, seeking truckers
- Awaiting assignment
- Can pause/resume visibility

**Tab 3: Assigned**
- Truckers assigned
- Trips created
- Active coordination

**Tab 4: In Transit**
- Trips underway
- Tracking capability
- Milestone monitoring

**Tab 5: Completed**
- Delivered loads
- Proof received
- History archive

**Tab 6: Cancelled**
- Cancelled loads
- Reason display
- Restore option (if applicable)

### 3.2.3 Load Card Structure

```
┌─────────────────────────────────────┐
│  Load #12345        [Status Badge] │
│  Mumbai → Delhi                     │
│  Cement • 18-22 tonnes • 1 truck   │
│  Pickup: Today, 2PM               │
│  ─────────────────────────────────  │
│  3 Truckers Interested             │
│                                     │
│  [Primary CTA]  [Secondary]         │
└─────────────────────────────────────┘
```

**Status Badges**:
- Grey: Draft
- Green: Open
- Blue: Assigned
- Orange: In Transit
- Teal: Completed
- Red: Cancelled

**Primary CTA by State**:
- Draft: "Publish Load"
- Open: "View Requests"
- Assigned: "Track Trip"
- In Transit: "Track Live"
- Completed: "View POD"

### 3.2.4 Search and Filter

**Search Bar**:
- Placeholder: "Search by load number, route..."
- Real-time search
- Clear button

**Filter Chips**:
- Date range
- Material type
- Status
- Route

### 3.2.5 Empty States

**Drafts Empty**:
- Icon: Document
- Text: "No drafts saved"
- CTA: "Create New Load"

**Open Empty**:
- Icon: Truck
- Text: "No open loads"
- CTA: "Post Your First Load"

## 3.3 Load Detail Screen

### 3.3.1 Screen Overview
- **Route**: `/load-detail/:loadId`
- **Shell**: Detail (with back arrow)
- **Purpose**: Authoritative view of single load

### 3.3.2 Page Sections

#### Section 1: Load Summary Header
```
┌─────────────────────────────────────┐
│  Load #12345                        │
│  Mumbai → Delhi                     │
│  Status: [ACTIVE - Seeking Truckers]│
│  Posted: 3 hours ago                │
└─────────────────────────────────────┘
```

#### Section 2: Route and Schedule Block
- Large route display
- Pickup date/time
- Distance (if calculated)
- Map preview

#### Section 3: Load Detail Block
- Material type
- Weight range
- Number of trucks
- Packaging type
- Load type

#### Section 4: Vehicle Requirements Block
- Truck type preference
- Tyre requirement
- Body type
- Special requirements

#### Section 5: Pricing Block
```
┌─────────────────────────────────────┐
│  PRICING                            │
│  ─────────────────────────────────  │
│  Rate: ₹25,000                      │
│  Type: Fixed                        │
│  Advance: 20% required              │
│  Est. per tonne: ₹1,250            │
└─────────────────────────────────────┘
```

#### Section 6: Booking/Requests Block

**If Open State**:
- "3 Truckers Interested"
- List of interested truckers
- For each: Name, rating, truck details
- **CTAs**: "Assign", "Reject", "View Profile", "Chat"

**If Assigned**:
- Assigned trucker card
- Trip reference
- Status: "Trip Created"
- **CTA**: "Track Trip"

#### Section 7: Trip Section (if active)
- Trip reference
- Current status
- Trucker details
- Milestone progress bar
- **CTA**: "Open Trip Detail"

#### Section 8: Documents Block
- Required documents list
- Uploaded documents (thumbnails)
- Upload buttons

#### Section 9: Activity Timeline
- Load created
- Published
- First interest received
- Assigned
- Trip started
- Delivered
- Completed

#### Section 10: Action Buttons

**Primary Actions by State**:
- Open: "Pause Visibility" / "Close Load" / "Request Super Load"
- Assigned: "Track Trip" / "Contact Trucker"
- Completed: "View POD" / "Download Report"

**Secondary Actions**:
- "Duplicate Load" (creates copy)
- "Edit Load" (if draft)
- "Share Load"
- "Raise Issue"

### 3.3.3 Super Load Banner (if promoted)

```
┌─────────────────────────────────────┐
│  ⭐ SUPER LOAD - ACTIVE             │
│  Payment Guarantee Included         │
│  Priority Support Enabled           │
│  Expires: 24 Apr, 11:59 PM         │
└─────────────────────────────────────┘
```

---

# 4. TRIP MONITORING

## 4.1 Trips Screen

### 4.1.1 Screen Overview
- **Route**: `/trips`
- **Shell**: Primary (bottom navigation)
- **Purpose**: Monitor shipment execution

### 4.1.2 Tab Structure

**Tab 1: Active**
- Trips in progress
- Milestone tracking
- Delay alerts

**Tab 2: Delayed**
- Overdue pickups/deliveries
- Highlighted in red
- Contact CTAs

**Tab 3: Upcoming**
- Assigned but not started
- Future pickups

**Tab 4: Completed**
- Delivered trips
- Proof available
- History

### 4.1.3 Trip Card Structure

```
┌─────────────────────────────────────┐
│  Trip #T789         [Status Badge] │
│  Mumbai → Delhi                     │
│  Cement, 20 tonnes                  │
│  Trucker: ABC Transport             │
│  ─────────────────────────────────  │
│  Status: In Transit                │
│  Last Update: 2 hours ago          │
│                                     │
│  Milestone: ●──●──○──○──○          │
│                                     │
│  [Track] [Contact] [View Docs]      │
└─────────────────────────────────────┘
```

### 4.1.4 Trip Detail Screen

#### Section 1: Trip Header
- Trip reference
- Load reference (linked)
- Route
- Current status with timestamp

#### Section 2: Trucker Information Card
```
┌─────────────────────────────────────┐
│  [Photo]  ABC Transport             │
│           ★ 4.5 (23 trips)          │
│           Truck: MH 12 AB 3456      │
│           Driver: Rajesh (98765...)│
│                                     │
│  [View Full Profile]  [Call Now]   │
└─────────────────────────────────────┘
```

#### Section 3: Milestone Timeline

```
Timeline View:

● Assigned
│  23 Apr, 9:00 AM
│  Load assigned to ABC Transport
│
● Pickup Pending
│  24 Apr, 10:00 AM (Scheduled)
│  Awaiting trucker arrival
│
○ Picked Up
   [Pending - Expected by 2PM]
```

**Visual**:
- Completed: Filled circle, teal
- Current: Pulsing circle, orange
- Pending: Empty circle, grey

#### Section 4: Live Tracking (if available)
- Map with truck location
- Route line
- ETA calculation
- Last updated timestamp
- Refresh button

#### Section 5: Documents and Proof
- Bilty/LR (from trucker)
- POD (Proof of Delivery)
- View/download buttons
- Upload date

#### Section 6: Communication
- "Chat with Trucker" button
- "Call Trucker" button
- Message history preview

#### Section 7: Actions
- "Mark as Complete" (if delivered)
- "Raise Issue" button
- "Download Trip Report"

### 4.1.5 Delay Alerts

**Alert Card**:
```
┌─────────────────────────────────────┐
│  ⚠️ DELAY ALERT                    │
│  Pickup is 2 hours overdue          │
│                                     │
│  [Contact Trucker]  [View Details] │
└─────────────────────────────────────┘
```

**Triggers**:
- Pickup not marked by scheduled time + grace period
- Delivery overdue
- No milestone update in 12+ hours (transit)

---

# 5. BOOKING & ASSIGNMENT

## 5.1 Booking Request Flow

### 5.1.1 View Requests Screen

**Access**: From Load Detail (Open state)

**Content**:
```
┌─────────────────────────────────────┐
│  3 Truckers Interested              │
│  Load: Mumbai → Delhi               │
│  ─────────────────────────────────  │
│                                     │
│  1. ABC Transport                   │
│     ★ 4.5 • 23 trips completed     │
│     Truck: Open Body, 10-wheel     │
│     [View Profile] [Chat] [Assign] │
│                                     │
│  2. XYZ Logistics                   │
│     ★ 4.2 • 15 trips completed     │
│     [View Profile] [Chat] [Assign] │
└─────────────────────────────────────┘
```

### 5.1.2 Trucker Profile Preview

**Modal Bottom Sheet**:
- Trucker name and photo
- Rating and trip count
- Verification badge
- Truck details
- Recent trip history (last 5)
- Reviews from other suppliers
- **CTAs**: "Assign", "Reject", "Chat"

### 5.1.3 Assignment Confirmation

**Confirmation Dialog**:
```
┌─────────────────────────────────────┐
│  Assign Load?                       │
│  ─────────────────────────────────  │
│  Trucker: ABC Transport             │
│  Load: Mumbai → Delhi               │
│  Rate: ₹25,000                      │
│                                     │
│  This will create a trip and notify │
│  the trucker immediately.           │
│                                     │
│  [Cancel]    [Confirm Assignment]   │
└─────────────────────────────────────┘
```

### 5.1.4 Post-Assignment Actions

**Success State**:
- Trip created notification
- Load moved to "Assigned" tab
- Trucker receives notification
- Chat automatically opened (optional)

---

# 6. COMMUNICATION

## 6.1 Messages (Inbox) Screen

### 6.1.1 Screen Overview
- **Route**: `/messages`
- **Shell**: Utility
- **Purpose**: Manage all supplier-trucker communication

### 6.1.2 Grouping Rule
**MANDATORY**: Chats grouped by LOAD first

**Structure**:
```
Load #12345: Mumbai → Delhi
├── Chat with ABC Transport (Trucker)
└── (No other chats for this load)

Load #12344: Pune → Chennai
├── Chat with XYZ Logistics
```

### 6.1.3 Inbox List Item

```
┌─────────────────────────────────────┐
│  Load #12345                        │
│  Mumbai → Delhi • Cement          │
│  ─────────────────────────────────  │
│  [Unread] ABC Transport            │
│  "When can you pickup?"        5m   │
│  [2 unread] 🔴                     │
└─────────────────────────────────────┘
```

### 6.1.4 Chat Detail Screen

#### Header
```
┌─────────────────────────────────────┐
│  ← ABC Transport                    │
│     Load #12345: Mumbai → Delhi    │
│     [📞] [⋯]                        │
└─────────────────────────────────────┘
```

#### Message Bubbles

**Supplier Message (Right)**:
- Background: Teal/Primary
- Text: White
- Timestamp below

**Trucker Message (Left)**:
- Background: Grey/Surface
- Text: Black
- Timestamp below

#### Message Types
1. **Text**: Standard bubble
2. **Image**: Thumbnail, tap to fullscreen
3. **Location**: Map preview
4. **Load Card**: Rich preview (if discussing other loads)
5. **Trip Update**: System message (trip assigned, etc.)

#### Input Area
- Text field: "Type a message..."
- Attachment button: Camera, Gallery, Location
- Send button
- Typing indicator

#### Load Context Bar (Fixed Bottom)
```
┌─────────────────────────────────────┐
│  Discussing: Load #12345            │
│  Mumbai → Delhi                     │
│  [View Load Details →]              │
└─────────────────────────────────────┘
```

---

# 7. VERIFICATION & PROFILE

## 7.1 Verification Screen

### 7.1.1 Screen Overview
- **Route**: `/verification`
- **Purpose**: Complete business verification

### 7.1.2 Required Documents

**All Required**:

1. **Aadhaar Card**
   - Front side upload
   - Back side upload
   - OCR auto-fill number
   - Status: Pending/Approved/Rejected

2. **PAN Card**
   - Front side upload
   - OCR auto-fill
   - Status tracking

3. **Profile Photo**
   - Owner/contact person photo
   - Guidelines: Clear face, professional
   - Real-time validation

4. **Business Licence/Registration**
   - Document upload
   - Business registration proof
   - GST certificate (optional but recommended)

### 7.1.3 GPS Location Capture

**Flow**:
1. Check GPS service enabled
2. If disabled: Prompt to enable
3. Capture coordinates
4. Reverse geocode
5. Display: "Verification Location: Pune, Maharashtra"
6. **Rule**: City-level resolution preferred

### 7.1.4 Verification States

| State | Badge | Description |
|-------|-------|-------------|
| Unverified | Grey | Not started |
| Pending | Orange | Under review |
| Verified | Green | Approved |
| Rejected | Red | Needs correction |

### 7.1.5 Rejection Handling

**Rejection Card**:
- Red header
- Specific rejection reason
- Problem document highlighted
- "Resubmit" button
- Guidelines for correction

## 7.2 Business Profile Screen

### 7.2.1 Editable Fields

**Business Identity**:
- Company Name
- Owner/Primary Contact Name
- Mobile Number (verified, non-editable)
- Email Address

**Business Address**:
- Street Address
- City (Google Places)
- State
- PIN Code

**Business Details**:
- GST Number (if applicable)
- PAN Number
- Business Registration Number
- Years in Operation
- Fleet Size (approximate)

**Operating Regions**:
- Primary states (multi-select)
- Primary routes (multi-select)

### 7.2.2 Profile Visibility

**Public Profile Shows**:
- Company name
- Rating
- Trip count
- Verification badge
- Operating regions

**Private (Not Shown)**:
- Contact details
- Documents
- Account details

---

# 8. SUPER LOAD

## 8.1 Super Load Overview

**Definition**: Premium load promotion service with payment guarantee

**Process**:
1. Supplier posts load
2. Requests Super Load promotion
3. Ops reviews and approves
4. Supplier pays fee off-platform
5. Load gets priority visibility

## 8.2 Super Load Request Flow

### 8.2.1 Request Screen

**Content**:
```
┌─────────────────────────────────────┐
│  Request Super Load Promotion       │
│  ─────────────────────────────────  │
│  Load: Mumbai → Delhi               │
│                                     │
│  Benefits:                          │
│  ✓ Payment Guarantee                │
│  ✓ Priority Listing                 │
│  ✓ Verified Trucker Badge          │
│  ✓ Dedicated Support                │
│                                     │
│  Fee: Based on route and load      │
│  (Ops will contact you)            │
│                                     │
│  Account Details Required:          │
│  ✗ Bank Account (incomplete)       │
│                                     │
│  [Complete Account Details First]  │
└─────────────────────────────────────┘
```

### 8.2.2 Account Details Form

**Bank Details**:
- Account Holder Name
- Bank Account Number
- IFSC Code
- Bank Name (auto-filled from IFSC)
- Branch (auto-filled)

**UPI Details** (Optional):
- UPI ID

**Billing Address**:
- Same as business address (toggle)
- Or separate billing address

### 8.2.3 Request Confirmation

**Dialog**:
```
┌─────────────────────────────────────┐
│  Submit Super Load Request?         │
│  ─────────────────────────────────  │
│  Your request will be reviewed    │
│  by our operations team.          │
│                                     │
│  If approved, you will be          │
│  contacted for payment.            │
│                                     │
│  [Cancel]    [Submit Request]      │
└─────────────────────────────────────┘
```

### 8.2.4 Super Load Status Tracking

**States**:
- **Requested**: Pending Ops review
- **Under Review**: Being evaluated
- **Approved**: Awaiting payment
- **Payment Pending**: Awaiting fee payment
- **Active**: Live with priority
- **Rejected**: Reason provided
- **Expired**: Promotion period ended

---

# 9. DOCUMENTS & PROOF

## 9.1 Document Management

### 9.1.1 Required Documents by Stage

**Verification Stage**:
- Aadhaar
- PAN
- Profile Photo
- Business Licence

**Load Execution Stage**:
- Bilty/LR (from trucker)
- POD (Proof of Delivery)
- E-way Bill (if applicable)

**Super Load Stage**:
- Bank Details
- UPI ID (optional)

### 9.1.2 Document Upload Flow

**Steps**:
1. Tap upload area
2. Choose: Camera / Gallery / Files
3. If Camera: Full-screen capture with guides
4. Preview with crop/rotate options
5. Quality check (blur detection)
6. Upload progress
7. Success/failure feedback
8. Thumbnail display

**Supported Formats**:
- Images: JPG, PNG (max 10MB)
- Documents: PDF (max 10MB)
- Compression: Automatic to <2MB

### 9.1.3 Document Viewer

**Features**:
- Fullscreen view
- Zoom/pan
- Download to device
- Share (limited)

---

# 10. DISPUTES & SUPPORT

## 10.1 Dispute Flow

### 10.1.1 Dispute Categories

1. **Quantity Mismatch**
   - Loaded ≠ Received weight

2. **Payment Issue**
   - Non-payment by trucker

3. **Fake Documents**
   - False POD or Bilty

4. **Scam/Fraud**
   - Deceptive trucker behavior

5. **Damage/Shortage**
   - Cargo damaged or missing

6. **Other**
   - Free text description

### 10.1.2 Raise Dispute Form

**Step 1: Select Trip**
- Dropdown of completed trips
- Search by trip number

**Step 2: Select Category**
- Radio buttons
- Category description

**Step 3: Provide Details**

**For Quantity Mismatch**:
- Expected tonnage
- Received tonnage (from POD)
- Difference calculation

**For Payment Issue**:
- Agreed amount
- Amount paid (if any)
- Outstanding amount
- Payment due date

**Step 4: Evidence Upload**
- Photos (max 5)
- Documents (max 3)
- Chat screenshots
- Bilty/POD photos

**Step 5: Review & Submit**
- Summary of dispute
- Confirm accuracy checkbox
- Submit button

### 10.1.3 Dispute Status Tracking

**States**:
- Submitted
- Under Review
- Needs More Proof
- Resolved
- Rejected
- Enforcement Applied

**Dispute Card**:
```
┌─────────────────────────────────────┐
│  Dispute #D123                      │
│  Trip: Mumbai → Delhi               │
│  Category: Payment Issue            │
│  Status: Under Review               │
│  [View Details]                     │
└─────────────────────────────────────┘
```

## 10.2 Support Tickets

### 10.2.1 Contact Support Form

**Fields**:
- Category: Technical / Operational / Billing / Other
- Subject
- Description
- Attachments (max 3)
- Priority: Normal / Urgent

### 10.2.2 Ticket Tracking

**States**:
- Submitted
- Assigned
- In Progress
- Waiting for User
- Resolved
- Closed

---

# 11. ACCOUNT & SETTINGS

## 11.1 Account Screen

### 11.1.1 Sections

#### Business Summary Card
- Company logo
- Company name
- Owner name
- Rating and trip count

#### Verification Status Card
- Current status
- Progress checklist
- CTA if incomplete

#### Super Load Account Card
- Account readiness
- Bank details status
- Complete/Update button

#### Settings Section

**Language**:
- English / Hindi

**Notifications**:
- Push toggles per category
- SMS preferences
- Email preferences

**App Preferences**:
- Theme (if supported)
- Text size

#### Support Section
- Help Center
- Contact Support
- Report Problem

#### Legal Section
- Terms of Service
- Privacy Policy
- Data Deletion Request

#### Account Actions
- Log Out
- Delete Account (with confirmation flow)

### 11.2 Data Deletion Flow

**Step 1**: Warning about consequences
**Step 2**: OTP verification
**Step 3**: Blocker check (active trips, disputes)
**Step 4**: Account deactivation (immediate)
**Step 5**: 30-day grace period
**Step 6**: Permanent deletion

---

# 12. NOTIFICATIONS

## 12.1 Notification Types

**Operational**:
- New trucker interest
- Trip assigned
- Pickup completed
- Delivery completed
- Proof uploaded
- Document verified/rejected

**Communication**:
- New message received
- Missed call

**Super Load**:
- Request approved/rejected
- Payment reminder
- Promotion started/ending

**System**:
- App updates
- Policy changes
- Maintenance notices

## 12.2 Notification Settings

**Per Category Toggles**:
- Trucker interest
- Trip updates
- Messages
- Verification updates
- Super Load updates
- System announcements

**Quiet Hours**:
- Enable/disable
- Time range
- Emergency override

## 12.3 Deep Links

| Type | Destination |
|------|-------------|
| Trucker Interest | Load Detail → Requests |
| Trip Update | Trip Detail |
| New Message | Chat |
| Verification | Verification Screen |
| Super Load | Super Load Status |

---

# 13. STATE SUMMARY

## 13.1 Load State Flow

```
┌─────────┐     ┌─────────┐     ┌──────────────┐
│  DRAFT  │────→│  ACTIVE │────→│   ASSIGNED   │
└─────────┘     │  (OPEN) │     │  (PARTIAL/   │
     │          └─────────┘     │    FULL)     │
     │                 │        └──────────────┘
     │                 │               │
     │                 ▼               ▼
     │          ┌─────────┐     ┌──────────────┐
     │          │ CANCELLED│     │  IN_TRANSIT  │
     │          │ EXPIRED  │     └──────────────┘
     │          │ FILLED_  │            │
     │          │ OUTSIDE  │            ▼
     │          └─────────┘     ┌──────────────┐
     │                          │   COMPLETED  │
     └─────────────────────────→│   DISPUTED   │
                                └──────────────┘
```

## 13.2 Booking States

```
SUBMITTED → APPROVED → (Trip Created)
    │
    ├──→ REJECTED
    │
    └──→ WITHDRAWN
```

## 13.3 Trip States

```
ASSIGNED → PICKUP_PENDING → PICKED_UP → 
IN_TRANSIT → DELIVERED → PROOF_SUBMITTED → 
COMPLETED

Alternative:
Any state ──→ CANCELLED
Any state ──→ DISPUTED
```

---

# 14. KEY BUSINESS RULES

## 14.1 Off-Platform Settlement Rule

**CRITICAL**: Standard freight payment between Supplier and Trucker happens OFF-PLATFORM.

**Platform Role**:
- Load matching
- Communication
- Trip tracking
- Document exchange
- Dispute evidence collection

**Not Platform Role**:
- Payment processing
- Freight settlement
- Money holding

## 14.2 Super Load Exception

**Only monetized workflow**:
- Manual coordination by Ops
- Fee paid off-platform
- Payment guarantee provided
- Priority support included

## 14.3 Verification Dependencies

| Feature | Unverified | Pending | Verified |
|---------|------------|---------|----------|
| Post Load | ❌ | ❌ | ✅ |
| Publish Draft | ❌ | ❌ | ✅ |
| Super Load | ❌ | ❌ | ✅ |
| Chat | ✅ | ✅ | ✅ |
| Assign Trucker | ❌ | ❌ | ✅ |

## 14.4 Load Edit Rules

**CAN Edit (Draft)**:
- Any field

**CANNOT Edit (Published)**:
- Major fields locked
- Recovery: Duplicate → Edit → Publish as new

**CAN Control (Published)**:
- Pause/Resume visibility
- Close load
- Assign trucker

---

*End of Supplier Features - Microscopic Detail*
*Last Updated: April 22, 2026*
