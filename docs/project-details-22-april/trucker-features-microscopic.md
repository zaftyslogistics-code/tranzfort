---
title: Trucker Features - Microscopic Detail
date: April 22, 2026
version: 1.1
purpose: Screen-by-screen, feature-by-feature microscopic breakdown of Trucker functionality
---

# Trucker Features - Microscopic Detail

## Document Overview
This document provides microscopic-level detail of every Trucker feature, screen, component, and function. Each section breaks down a major feature area into its atomic components.

---

## Table of Contents
1. [Authentication & Onboarding](#1-authentication--onboarding)
2. [Home Dashboard](#2-home-dashboard)
3. [Load Discovery (Find Loads)](#3-load-discovery-find-loads)
4. [Load Detail & Evaluation](#4-load-detail--evaluation)
5. [Trip Management](#5-trip-management)
6. [Communication](#6-communication)
7. [Verification & Profile](#7-verification--profile)
8. [Vehicle Management](#8-vehicle-management)
9. [Disputes & Support](#9-disputes--support)
10. [Account & Settings](#10-account--settings)
11. [Notifications](#11-notifications)

---

# 1. AUTHENTICATION & ONBOARDING

## 1.1 Entry Points

### 1.1.1 Splash Screen
- **Location**: `@TranZfort/lib/src/features/auth/presentation/auth_screens.dart:28-50`
- **Purpose**: Branded loading screen with logo animation
- **Components**:
  - Animated logo (main-logo-transparent.png, 120px)
  - App name "TranZfort"
  - Loading indicator
  - Version number (bottom)
- **Functionality**:
  - Check for existing session
  - Route to: `AppRoutes.authPath` if no session
  - Route to: Home if session exists
- **Duration**: 2-3 seconds minimum for UX

### 1.1.2 Auth Entry Screen
- **Location**: `@TranZfort/lib/src/features/auth/presentation/auth_screen_sections.dart:102-231`
- **Purpose**: Main login/registration gateway
- **Layout (Top to Bottom)**:
  1. AppBar with TTS action button (accessibility)
  2. App logo (80px height)
  3. Welcome title + subtitle
  4. **Google Sign-In Button** (white card with official Google logo)
  5. Trust microcopy: "Fastest way to get started"
  6. "or with email" divider
  7. Email text field
  8. Password field with visibility toggle
  9. "Sign In" outline button
  10. Row: "Sign Up" link + "Forgot Password?" link

### 1.1.3 Google Sign-In Button
- **Location**: `@TranZfort/lib/src/shared/widgets/google_sign_in_button.dart`
- **Design**:
  - White Material card with elevation 2
  - Official Google "G" logo (Image.asset)
  - Label: "Continue with Google"
  - Height: 52px, Border radius: 12px
  - Loading state: CircularProgressIndicator (teal)
- **Behavior**:
  - Calls `authRepository.signInWithGoogle()`
  - Shows loading state during sign-in
  - Error handling with user-friendly messages

### 1.1.4 Email/Password Auth Screen
- **Location**: `@TranZfort/lib/src/features/auth/presentation/auth_screens_email_password.dart`
- **States**:
  - Sign-In mode
  - Sign-Up mode
  - "Check your email" verification state
- **Features**:
  - PopScope with unsaved-changes dialog (lines 175-192)
  - Form validation
  - Password visibility toggle
  - Error message display

### 1.1.5 Role Selection Screen
- **Purpose**: User selects their role during onboarding
- **Options**:
  - Supplier (Shipper)
  - Trucker (Transporter)
- **Validation**: Required selection before proceeding
- **PopScope**: Confirmation dialog to prevent accidental exit

### 1.1.6 Onboarding Profile Completion Screen
- **Location**: `@TranZfort/lib/src/features/auth/presentation/onboarding_profile_completion.dart`
- **Purpose**: Collect basic profile information
- **Fields**:
  - Full Name (required)
  - Mobile Number (required, with OTP verification)
  - Home City (Google Places Autocomplete)
  - Operating Regions (multi-select)
- **GPS Integration**:
  - Check GPS service enabled
  - Request location permissions (AndroidManifest: ACCESS_FINE_LOCATION, ACCESS_COARSE_LOCATION)
  - Google Places Autocomplete for city selection
  - Captures: city, state, latitude, longitude
- **PopScope**: Confirmation dialog for unsaved changes

---

# 2. HOME DASHBOARD

## 2.1 Trucker Home Screen

### 2.1.1 Screen Overview
- **Route**: `/home`
- **Shell**: Primary (bottom navigation)
- **Purpose**: Command center showing readiness, alerts, and quick actions

### 2.1.2 Page Sections (Top to Bottom)

#### Section 1: Readiness Banner
- **Purpose**: Show verification and vehicle status
- **States**:
  - **Complete**: Green check, "Ready to work"
  - **Incomplete**: Warning banner with specific missing items:
    - "Complete Aadhaar verification"
    - "Upload PAN card"
    - "Add profile photo"
    - "Add at least one truck"
- **CTA**: "Complete Verification" → Routes to verification flow
- **Visual**: Icon + Text + Arrow button

#### Section 2: Active Trip Summary
- **Purpose**: Show current operational commitments
- **Components**:
  - "Active Trip" header
  - Compact trip card (if any active)
  - Route preview (Origin → Destination)
  - Current status badge
  - Next milestone countdown
- **Empty State**: "No active trips. Find loads to get started."
- **CTA**: "Open Trips" → Routes to Trips page

#### Section 3: Urgent Alerts
- **Purpose**: Critical notifications requiring action
- **Alert Types**:
  - Verification rejected
  - Truck approval rejected
  - Dispute raised against you
  - Trip delay detected
  - Document expiry warning
- **Visual**: Red/orange warning cards with icon
- **CTA**: Action button per alert type

#### Section 4: Quick Actions Rail
- **Layout**: Horizontal scrollable row
- **Actions**:
  1. "Find Loads" (primary) → Routes to Find Loads
  2. "My Trips" → Routes to Trips
  3. "Messages" → Routes to Messages
  4. "Add Truck" → Routes to vehicle setup
- **Visual**: Icon + Label cards

#### Section 5: Recent Activity Snapshot
- **Purpose**: Show last 3-5 recent items
- **Content**:
  - Recently viewed loads
  - Recent trip updates
  - Recent messages
- **Each Item**: Title, timestamp, brief summary
- **CTA**: "View All" → Routes to respective list

### 2.1.3 Technical Details
- **Provider**: `truckerHomeProvider`
- **Data Sources**:
  - Verification status
  - Active trips
  - Recent notifications
  - Vehicle count
- **Refresh**: Pull-to-refresh enabled
- **Loading**: Skeleton screens for each section

---

# 3. LOAD DISCOVERY (FIND LOADS)

## 3.1 Find Loads Screen

### 3.1.1 Screen Overview
- **Route**: `/find-loads`
- **Shell**: Primary (bottom navigation)
- **Purpose**: Marketplace discovery workspace
- **Key Rule**: Non-verified Truckers CAN browse but CANNOT contact

### 3.1.2 Top Navigation Tabs
- **Tab 1: "All Loads"** - Full marketplace feed
- **Tab 2: "Super Loads"** - Promoted/priority loads only
- **Visual**: Underline indicator, smooth transition
- **Rule**: Shared filter state across tabs

### 3.1.3 Search and Filter Bar

#### Search Field
- **Placeholder**: "Search by city, route, or material"
- **Functionality**:
  - Real-time search (debounced 300ms)
  - Search history (last 5 searches)
  - Clear button (X icon)
- **Keyboard**: Search action button

#### Quick Filter Chips (Horizontal Scroll)
- **Filters**:
  - "Near Me" (uses current location)
  - "Today" (pickup date)
  - "Tomorrow"
  - "This Week"
  - "My Truck Type" (pre-selected if only one truck)
  - "Any Material"
- **Visual**: Rounded chips, selected state highlighted

#### Advanced Filter Button
- **Icon**: Filter/sliders icon
- **Action**: Opens bottom sheet with full filters

### 3.1.4 Advanced Filter Bottom Sheet

#### Route Filters Section
- **Origin City**: Searchable dropdown with Google Places
- **Destination City**: Searchable dropdown with Google Places
- **Radius**: Slider (10km - 500km) for "Near Me"

#### Load Details Section
- **Material Type**: Multi-select chips
  - Cement, Steel, Sand, Grains, etc.
- **Weight Range**: Dual-handle slider (tonnes)
  - Min: 1 tonne
  - Max: 50 tonnes

#### Vehicle Requirements Section
- **Truck Type**: Dropdown (Any, Open Body, Closed Body, etc.)
- **Tyre Count**: Dropdown (Any, 6-wheel, 10-wheel, etc.)
- **Body Type**: Dropdown (Any, Standard, High Side, etc.)

#### Timing Section
- **Pickup Date**: Date picker (today + 30 days)
- **Pickup Window**: Morning/Afternoon/Evening/Night

#### Pricing Section
- **Rate Range**: Min/Max input fields
- **Advance Required**: Toggle yes/no

#### Action Buttons
- **Primary**: "Apply Filters"
- **Secondary**: "Reset All"
- **Tertiary**: "Cancel"

### 3.1.5 Filter Summary Bar
- **Display**: Below search, above feed
- **Format**: "Showing X loads • Filter 1 • Filter 2 • [Clear All]"
- **Interactive**: Tap filter to remove, X to clear all

### 3.1.6 Compact Load Feed

#### Feed Layout
- **Type**: Infinite scroll list
- **Card Size**: Fixed height (~180px)
- **Spacing**: 12px between cards
- **Loading**: Skeleton cards while loading
- **Empty State**: "No loads found. Try adjusting filters."
- **Pagination**: 20 items per page, lazy load on scroll

#### Compact Load Card Structure

**Row 1: Route Header**
```
[Origin City] → [Destination City]    [Posted Time]
```
- Origin/Destination: Bold, 16px
- Posted: "2h ago", muted color

**Row 2: Price & Timing**
```
[₹25,000]    [Pickup: Today, 2PM]    [Advance: 20%]
```
- Price: Primary color, bold
- Pickup: Standard text
- Advance: Muted text (if shown)

**Row 3: Shipment Details**
```
[Material: Cement] • [18-22 tonnes] • [Open Body]
```

**Row 4: Truck Requirements**
```
[10-wheel] • [Tyre: Any]
```

**Row 5: Supplier & Badges**
```
[Supplier: ABC Logistics]    [Match Badge] [Super Load Badge]
```
- Match Badge: Shows if matches trucker's registered truck
- Super Load Badge: Gold/yellow star with "Super Load" text

**Card Background**:
- Normal: White card
- Super Load: Subtle gold tint or left border

#### Card Interactions
- **Tap**: Opens Load Detail
- **Long Press**: Quick preview (optional)
- **Swipe**: No swipe actions (to avoid accidental triggers)

### 3.1.7 Super Load Card Rules

**Visual Differentiators**:
- Gold/yellow left border (4px)
- "Super Load" badge top-right
- Payment guarantee microcopy
- Slightly elevated shadow

**Payment Guarantee Note**:
```
"Payment Guaranteed by TranZfort"
```
- Small text below price
- Info icon with tooltip
- Does NOT imply in-app settlement

### 3.1.8 Verification Gate Overlay

**When**: Trucker not verified AND taps "Chat" or "Call"

**Overlay Content**:
- Icon: Lock
- Title: "Complete Verification to Contact"
- Message: "To chat or call suppliers, complete:"
- Checklist:
  - [ ] Aadhaar verification
  - [ ] PAN verification
  - [ ] Profile photo
  - [ ] Add at least one truck
- **CTA**: "Complete Verification" → Routes to verification
- **Secondary**: "Browse Loads" → Closes overlay

---

# 4. LOAD DETAIL & EVALUATION

## 4.1 Load Detail Screen

### 4.1.1 Screen Overview
- **Route**: `/load-detail/:loadId`
- **Shell**: Detail (with back arrow)
- **Purpose**: Help Trucker make confident decision about load

### 4.1.2 Page Structure

#### Section 1: Route Header Card
```
┌─────────────────────────────────────┐
│  Mumbai  →  Delhi                   │
│  Pickup: 24 Apr, 2:00 PM           │
│  Posted 3 hours ago by ABC Logistics│
└─────────────────────────────────────┘
```
- **Large Route Display**: Origin → Destination
- **Pickup Date/Time**: Prominent
- **Posted Info**: Time ago + Supplier name

#### Section 2: Pricing & Timing Summary Card
```
┌─────────────────────────────────────┐
│  FARE                          ₹XX,XXX│
│  ───────────────────────────────────  │
│  Advance Required            20%    │
│  Payment Terms          On Delivery │
│  Est. Distance            1,450 km    │
│  Est. Drive Time         24 hours   │
└─────────────────────────────────────┘
```

#### Section 3: Shipment Details Card
**Fields**:
- Material Type: Cement
- Weight Range: 18-22 tonnes
- Number of Trucks: 1
- Load Type: Full Load
- Packaging: Bags
- Special Handling: None

#### Section 4: Truck Requirements Card
**Fields**:
- Truck Type: Open Body (Required)
- Tyre Count: 10-wheel (Required)
- Body Type: Standard (Preferred)
- Special Requirements: None

#### Section 5: Supplier Summary Card
```
┌─────────────────────────────────────┐
│  [Photo]  ABC Logistics             │
│           ★ 4.5 (23 trips)          │
│           Verified Supplier         │
│                                     │
│  [View Profile]  [Report]             │
└─────────────────────────────────────┘
```
- Supplier logo/initial
- Name
- Rating and trip count
- Verification badge
- CTAs: View full profile, Report supplier

#### Section 6: Super Load Banner (if applicable)
```
┌─────────────────────────────────────┐
│  ⭐ SUPER LOAD                      │
│  Payment Guaranteed                 │
│  Priority Support Included          │
└─────────────────────────────────────┘
```
- Gold background
- Star icon
- Three key benefits listed

#### Section 7: Contact Actions
**Layout**: Horizontal row of 3 buttons

**Button 1: "Chat"**
- Icon: Chat bubble
- State: Enabled (if verified) / Disabled with lock (if not)
- Action: Opens conversation

**Button 2: "Call"**
- Icon: Phone
- State: Enabled (if verified) / Disabled with lock (if not)
- Action: Initiates phone call

**Button 3: "Share"**
- Icon: Share
- State: Always enabled
- Action: Opens share sheet

**Share Content**:
```
Load on TranZfort
Mumbai → Delhi
Cement, 18-22 tonnes
Pickup: 24 Apr, 2PM
Contact via app
[Link to load]
```

### 4.1.3 Verification Gate Modal

**Triggered**: Non-verified Trucker taps Chat or Call

**Content**:
- Title: "Complete Verification to Contact"
- Subtitle: "Verify your account to connect with suppliers"
- Missing Requirements List:
  - ✓ Mobile verified
  - ✗ Aadhaar not uploaded
  - ✗ PAN not uploaded
  - ✗ Profile photo missing
  - ✗ No trucks added
- **CTA**: "Complete Verification" (primary)
- **Secondary**: "Continue Browsing"

### 4.1.4 Map Preview Section

**Features**:
- Static map showing route
- Origin and destination markers
- Estimated route line
- Distance and duration
- **CTA**: "Open in Google Maps" (external link)

---

# 5. TRIP MANAGEMENT

## 5.1 Trips List Screen

### 5.1.1 Screen Overview
- **Route**: `/trips`
- **Shell**: Primary (bottom navigation)
- **Purpose**: Show operational commitments and execution state

### 5.1.2 Tab Structure

**Tab 1: Active**
- Currently assigned trips
- In-progress milestones

**Tab 2: Upcoming**
- Assigned but not started
- Future pickup dates

**Tab 3: Completed**
- Delivered trips
- Proof submitted

**Tab 4: Disputed**
- Active disputes
- Awaiting resolution

### 5.1.3 Trip Card Structure

```
┌─────────────────────────────────────┐
│  Mumbai → Delhi         [Status]    │
│  Pickup: Today, 2PM                 │
│  Material: Cement, 20 tonnes        │
│  ─────────────────────────────────  │
│  Current: In Transit                │
│  [Track] [Contact] [Upload Proof]   │
└─────────────────────────────────────┘
```

**Status Badges**:
- Blue: Assigned / Pickup Pending
- Orange: Picked Up / In Transit
- Green: Delivered / Completed
- Red: Disputed / Delayed

### 5.1.4 Trip Detail Screen

#### Section 1: Trip Header
- Load reference number
- Route (Origin → Destination)
- Current status with timestamp
- Supplier info

#### Section 2: Milestone Timeline
```
● Assigned              [timestamp]
│
● Pickup Pending        [timestamp]
│
○ Picked Up             [pending]
│
○ In Transit            [pending]
│
○ Delivered             [pending]
│
○ Completed             [pending]
```
- Filled circles: Completed
- Empty circles: Pending
- Current: Highlighted with pulse animation

#### Section 3: Linked Truck Card
- Truck number
- Truck type
- Driver contact (if added)

#### Section 4: Proof and Documents Section
- **Required Uploads**:
  - Bilty/LR (Loading Receipt)
  - POD (Proof of Delivery)
- **Upload Buttons**: Camera icon + "Upload [Document Type]"
- **Uploaded State**: Thumbnail + "View" + "Retake"
- **Status**: Pending verification / Verified

#### Section 5: Contact Actions
- "Call Supplier"
- "Chat with Supplier"
- "View Load Details"

#### Section 6: Dispute and Support Entry
- "Raise Dispute" button (destructive style)
- "Contact Support" link

### 5.1.5 Milestone Update Flow

**Pickup Completion**:
1. Trucker taps "Mark as Picked Up"
2. GPS location captured automatically
3. Optional: Upload loading photo
4. Timestamp recorded
5. Supplier notified

**Delivery Completion**:
1. Trucker taps "Mark as Delivered"
2. GPS location captured
3. Required: Upload POD photo
4. Optional: Upload delivery photo
5. Supplier notified
6. Trip moves to "Proof Submitted" state

### 5.1.6 Document Upload Flow

**Upload Steps**:
1. Tap upload button
2. Choose: Camera / Gallery
3. Camera: Full-screen capture with guides
4. Gallery: Image picker
5. Preview with retake/confirm
6. Automatic compression
7. Upload progress indicator
8. Success/failure feedback
9. Thumbnail appears in trip detail

**Supported Formats**: JPG, PNG, PDF (for documents)
**Max Size**: 10MB per file
**Compression**: Automatic to <2MB

---

# 6. COMMUNICATION

## 6.1 Messages List Screen

### 6.1.1 Screen Overview
- **Route**: `/messages`
- **Shell**: Utility (outside primary shell)
- **Purpose**: Conversation management

### 6.1.2 Conversation Grouping Rule
**MANDATORY**: Chats grouped by load first

**Structure**:
```
Load #12345: Mumbai → Delhi
├── Conversation with ABC Logistics
└── (No other conversations for this load)
```

### 6.1.3 Conversation List Item
```
┌─────────────────────────────────────┐
│  Load #12345                        │
│  Mumbai → Delhi • Cement            │
│  ─────────────────────────────────  │
│  [Unread dot] ABC Logistics         │
│  "Can you pickup today?"     2m ago │
│                                     │
│  [2 unread messages]                │
└─────────────────────────────────────┘
```

**Fields**:
- Load reference
- Route + material
- Supplier name
- Last message preview (truncated)
- Timestamp
- Unread count badge

### 6.1.4 Chat Detail Screen

#### Header
- Back button
- Supplier name + photo
- Load context: "Load #12345: Mumbai → Delhi"
- Action: Call button, More options

#### Message Bubbles

**Trucker Message (Right)**:
- Background: Primary color (teal)
- Text: White
- Timestamp below
- Read receipt checkmarks

**Supplier Message (Left)**:
- Background: Grey/surface color
- Text: Black
- Timestamp below

**Message Types**:
1. **Text**: Standard bubble
2. **Image**: Thumbnail, tap to fullscreen
3. **Location**: Map preview, tap to open maps
4. **Load Card**: Rich preview of linked load

#### Input Area
- Text field with placeholder
- Attachment button (camera, gallery, location)
- Send button (disabled if empty)
- Typing indicator when supplier typing

#### Load Context Bar (Bottom)
- Fixed bar above keyboard
- Shows: "Discussing Load #12345"
- Tap to view load details

### 6.1.5 Communication Rules

**Eligibility**:
- Verified Truckers: Full chat + call
- Non-verified: Chat/call blocked with clear explanation

**Retention**:
- Messages retained for dispute review
- 90-day retention policy
- Cannot delete individual messages

**Notifications**:
- Push notification for new message
- Deep link to conversation
- Unread badge on Messages tab

---

# 7. VERIFICATION & PROFILE

## 7.1 Verification Screen

### 7.1.1 Screen Overview
- **Route**: `/verification`
- **Purpose**: Complete identity verification

### 7.1.2 Verification Checklist

**Required Items (ALL mandatory)**:

1. **Aadhaar Card**
   - Front side photo
   - Back side photo
   - Number input (auto-extracted if possible)
   - OCR for auto-fill
   - Status: Pending / Approved / Rejected

2. **PAN Card**
   - Front side photo
   - Number input
   - OCR for auto-fill
   - Status: Pending / Approved / Rejected

3. **Profile Photo**
   - Camera capture
   - Guidelines: Clear face, no sunglasses, plain background
   - Real-time validation
   - Status: Pending / Approved / Rejected

4. **At Least One Truck**
   - See Section 8 for truck addition flow
   - Must be approved by admin
   - Edits trigger re-approval

**Optional Items**:
- Business Registration (if applicable)
- GST Certificate

### 7.1.3 Verification Status States

| State | Color | Description |
|-------|-------|-------------|
| Unverified | Grey | Not started |
| Pending | Orange | Submitted, awaiting review |
| Verified | Green | Approved, full access |
| Rejected | Red | Rejected, resubmission required |

### 7.1.4 GPS Location Capture

**Flow**:
1. Check GPS enabled
2. If disabled: Show dialog "Enable GPS for accurate location"
3. Button: "Enable GPS" → Opens device settings
4. On return: Retry location fetch (2s delay)
5. Capture coordinates
6. Reverse geocode to city level
7. Display: "Verification Location: Pune, Maharashtra"

**Rule**: City-level resolution preferred over village

### 7.1.5 Rejection Handling

**Rejection Card**:
- Red header: "Verification Rejected"
- Rejection reason (specific)
- Rejected document preview
- "Resubmit" button
- Common reasons list:
  - Blurry photo
  - Document expired
  - Information mismatch
  - Face not clear

---

# 8. VEHICLE MANAGEMENT

## 8.1 Vehicle List Screen

### 8.1.1 Screen Overview
- **Route**: `/vehicles`
- **Purpose**: Manage truck fleet

### 8.1.2 Truck Card Structure

```
┌─────────────────────────────────────┐
│  [Truck Photo]  MH 12 AB 3456      │
│                 Open Body          │
│                 10-wheel           │
│                 [Status Badge]     │
│                                     │
│  [Edit]  [View Details]            │
└─────────────────────────────────────┘
```

**Status Badges**:
- Green: Approved
- Orange: Pending Review
- Red: Rejected
- Yellow: Edited, Pending Re-approval

### 8.1.3 Add/Edit Truck Form

**Sections**:

1. **Vehicle Registration**
   - Truck Number: Text input (format validation)
   - RC Photo: Upload front + back
   - RC Number: Auto-extract or manual

2. **Vehicle Specifications**
   - Truck Type: Dropdown (Open Body, Closed Body, Container, etc.)
   - Tyre Count: Dropdown (6-wheel, 10-wheel, 12-wheel, etc.)
   - Body Type: Dropdown (Standard, High Side, Platform, etc.)
   - Capacity: Number input (tonnes)

3. **Vehicle Photos**
   - Front view (required)
   - Side view (optional)
   - Back view (optional)
   - Guidelines for each

4. **Operating Details**
   - Preferred routes (multi-select)
   - Home location
   - Driver contact (optional)

### 8.1.4 Truck Approval Workflow

**States**:
1. **Draft**: Adding details
2. **Pending**: Submitted for review
3. **Approved**: Ready for trips
4. **Rejected**: Issues found, needs correction
5. **Edited**: Modified, needs re-approval

**Edit Rule**: Material changes trigger re-approval
- Truck number change
- Type change
- Capacity change

**No Re-approval Needed**:
- Photo updates
- Route preferences
- Driver contact

---

# 9. DISPUTES & SUPPORT

## 9.1 Disputes Screen

### 9.1.1 Screen Overview
- **Route**: `/disputes`
- **Purpose**: Submit and track disputes

### 9.1.2 Dispute Categories

1. **Quantity Mismatch**
   - Loaded tonnes ≠ Received tonnes
   - Requires: Bilty proof, Delivery proof

2. **Payment Issue**
   - Non-payment or partial payment
   - Requires: Payout proof, Communication logs

3. **Fake Proof**
   - Counterparty submitted false documents
   - Requires: Evidence of forgery

4. **Scam/Fraud**
   - Deceptive behavior
   - Requires: All communication, Proof

5. **Other**
   - Free text description

### 9.1.3 Raise Dispute Form

**Step 1: Select Trip**
- Dropdown of completed trips
- Shows: Route, Supplier, Date

**Step 2: Select Category**
- Radio buttons for categories
- Description per category

**Step 3: Provide Details**

**For Quantity Mismatch**:
- Loaded tonnage (from bilty)
- Received tonnage (from bilty)
- Difference calculation
- Upload bilty photo

**For Payment Issue**:
- Expected amount
- Received amount
- Upload payout proof (if any)
- Explanation

**Step 4: Evidence Upload**
- Photo evidence
- Document uploads
- Chat screenshots
- Maximum 5 files

**Step 5: Review & Submit**
- Summary of dispute
- Confirm accuracy checkbox
- Submit button

### 9.1.4 Dispute Status Tracking

**States**:
- **Submitted**: Received, awaiting review
- **Under Review**: Being investigated
- **Needs More Proof**: Additional evidence requested
- **Resolved**: Decision made
- **Rejected**: Not substantiated
- **Enforcement Applied**: Action taken

**Dispute Card**:
```
┌─────────────────────────────────────┐
│  Dispute #D123                      │
│  Load: Mumbai → Delhi               │
│  Category: Quantity Mismatch        │
│  Status: Under Review               │
│  Submitted: 3 days ago              │
│                                     │
│  [View Details]                     │
└─────────────────────────────────────┘
```

### 9.1.5 Support Ticket Flow

**Access**: From Account → Contact Support

**Form**:
- Category: Technical / Operational / Billing / Other
- Subject: Text input
- Description: Multi-line text
- Attachments: Up to 3 files
- Priority: Normal / Urgent

---

# 10. ACCOUNT & SETTINGS

## 10.1 Account Screen

### 10.1.1 Screen Overview
- **Route**: `/account`
- **Purpose**: Centralized profile, settings, and support

### 10.1.2 Page Sections

#### Section 1: Profile Summary Card
- Profile photo
- Full name
- Mobile number
- Email (if added)
- Edit button

#### Section 2: Verification Status Card
- Current status with icon
- Progress bar for incomplete items
- "Complete Verification" button (if needed)

#### Section 3: Truck Readiness Card
- Number of trucks added
- Number approved
- "Add Truck" / "Manage Trucks" button

#### Section 4: Settings Section

**Language**:
- Current: English / Hindi
- Tap to change

**Notifications**:
- Toggle: Push notifications
- Toggle: SMS notifications
- Toggle: Email notifications

**App Preferences**:
- Dark mode toggle (if supported)
- Text size preference

#### Section 5: Support Section
- "Help Center" → FAQ
- "Contact Support" → Ticket form
- "Report a Problem"

#### Section 6: Legal Section
- Terms of Service
- Privacy Policy
- Data Deletion Request

#### Section 7: Account Actions
- "Log Out" (destructive style)
- "Delete Account" (red, with confirmation)

### 10.1.3 Edit Profile Screen

**Editable Fields**:
- Full name
- Email
- Home city (Google Places)
- Operating regions (multi-select)

**Non-editable** (shown for reference):
- Mobile number
- Role

### 10.1.4 Data Deletion Flow

**Step 1: Request Deletion**
- Warning about consequences
- Checkbox: "I understand my data will be deleted"
- Reason selection (optional)
- Confirm button

**Step 2: Verification**
- OTP to registered mobile
- Enter OTP

**Step 3: Blocker Check**
System checks:
- Active trips? → Block
- Pending disputes? → Block
- Verification in progress? → Block

**Step 4: Processing**
- Account deactivated immediately
- 30-day grace period
- Permanent deletion after retention period

---

# 11. NOTIFICATIONS

## 11.1 Notifications Screen

### 11.1.1 Screen Overview
- **Route**: `/notifications`
- **Purpose**: System and action-required notifications

### 11.1.2 Notification Categories

**Operational**:
- New load matching your truck
- Trip assigned
- Pickup reminder
- Delivery confirmation
- Document verification complete

**Communication**:
- New message received
- Missed call from supplier

**Financial**:
- Payment reminder (if applicable)
- Dispute resolution

**System**:
- App updates
- Policy changes
- Maintenance notices

### 11.1.3 Notification Item Structure

```
┌─────────────────────────────────────┐
│  [Icon]  New Load Match!            │
│          A cement load from Mumbai  │
│          to Delhi matches your      │
│          truck type.                │
│          10 minutes ago     [•]     │
└─────────────────────────────────────┘
```

**Visual States**:
- Unread: Bold title, blue dot
- Read: Normal weight, no dot

### 11.1.4 Deep Link Behavior

| Notification Type | Deep Link Destination |
|-------------------|----------------------|
| Load Match | Load Detail |
| Trip Assigned | Trip Detail |
| New Message | Chat Detail |
| Verification Status | Verification Screen |
| Document Rejected | Reupload Screen |

### 11.1.5 Notification Settings

**Per Category Toggles**:
- Load matches
- Trip updates
- Messages
- Verification updates
- System announcements

**Quiet Hours**:
- Enable/disable
- Time range selection
- Emergency notifications override

---

# 12. STATE SUMMARY

## 12.1 Critical State Dependencies

```
Verification State Flow:
┌─────────────┐     ┌──────────┐     ┌──────────┐     ┌──────────┐
│  Unverified │────→│ Pending  │────→│ Verified │────→│ Rejected │
└─────────────┘     └──────────┘     └──────────┘     └──────────┘
      │                                              │
      └──────────────────────────────────────────────┘
                        (resubmit)

Vehicle State Flow:
┌──────────┐     ┌──────────┐     ┌──────────┐     ┌──────────────────┐
│  Draft   │────→│ Pending  │────→│ Approved │────→│ Edited (Pending) │
└──────────┘     └──────────┘     └──────────┘     └──────────────────┘
                                            │                │
                                            └────────────────┘
                                            (re-approval cycle)

Trip State Flow:
┌──────────┐     ┌───────────────┐     ┌──────────┐     ┌──────────┐
│ Assigned │────→│ Pickup Pending│────→│Picked Up │────→│In Transit│
└──────────┘     └───────────────┘     └──────────┘     └──────────┘
                                                               │
     ┌───────────────────────────────────────────────────────────┘
     ▼
┌──────────┐     ┌───────────────┐     ┌──────────┐
│ Delivered│────→│Proof Submitted│────→│Completed │
└──────────┘     └───────────────┘     └──────────┘
     │
     ▼
┌──────────┐
│ Disputed │
└──────────┘
```

## 12.2 Permission Matrix

| Feature | Unverified | Pending | Verified |
|---------|------------|---------|----------|
| Browse Loads | ✅ | ✅ | ✅ |
| View Load Detail | ✅ | ✅ | ✅ |
| Chat with Supplier | ❌ | ❌ | ✅ |
| Call Supplier | ❌ | ❌ | ✅ |
| Accept Trip | ❌ | ❌ | ✅ |
| View Assigned Trips | ❌ | ❌ | ✅ |
| Upload Proof | ❌ | ❌ | ✅ |
| Raise Dispute | ❌ | ❌ | ✅ |

---

# 13. TECHNICAL NOTES

## 13.1 Data Flow Architecture

```
UI → Provider → Repository → Backend (Supabase)
 ↑______________________________↓
         Realtime Updates
```

**Source of Truth Priority**:
1. Database (Supabase)
2. Repository layer
3. Provider/State management
4. UI (read-only)

## 13.2 File Size Limits

- Profile Photo: 5MB max
- Documents: 10MB max
- Proof Photos: 10MB max (auto-compress to 2MB)
- Chat Images: 5MB max

## 13.3 Pagination Rules

- Load Feed: 20 items per page
- Trip List: 15 items per page
- Messages: 50 per fetch, load more on scroll
- Notifications: 30 per page

## 13.4 Offline Behavior

- Browse cached loads
- View cached trip details
- Cannot send messages
- Cannot upload documents
- "You're offline" banner shown

---

*End of Trucker Features - Microscopic Detail*
*Last Updated: April 22, 2026*
