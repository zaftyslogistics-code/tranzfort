---
title: AI Voice Assistant - Feature Brainstorm V2
date: April 22, 2026
version: 2.0
purpose: Marketplace load suggestions, route planning, day-to-day trucker assistance, guard rails, offline architecture
status: DEFERRED

# AI Voice Assistant - Feature Brainstorm V2

> **⚠️ STATUS: DEFERRED (April 22, 2026)**
>
> This AI voice assistant feature brainstorm is retained for reference.
>
> **Decision:** AI integration deferred due to inference time and quality not meeting expectations.
> **Reason:** On-device AI inference (flutter_gemma) produced slow responses and repetitive, low-quality answers.
> **Future Plan:** Will be revisited in a future version with a different approach (potentially cloud-based AI or improved on-device models).
>
> See `TODO-22-april.md` for complete rollback details.

## 1. MARKETPLACE LOAD SUGGESTIONS FOR TRUCKERS

### 1.1 Load Discovery Voice Commands

| Hindi Command | English Command | AI Action |
|--------------|-----------------|-----------|
| "Aas paas load dhoondo" | "Find nearby loads" | Fetch loads near current GPS |
| "Kal ke liye load chahiye" | "Find loads for tomorrow" | Filter by pickup date |
| "Coal load dhoondo" | "Find coal loads" | Filter by material |
| "Mere truck ke hisaab se" | "Match my truck specs" | Filter by truck type/capacity |
| "Rate compare karo" | "Compare rates" | Show rate per km analysis |
| "Best load batao" | "Show best load" | Rank by rate, distance, urgency |

### 1.2 Smart Load Matching Algorithm

```
INPUT: Trucker's registered truck details
  - Truck type (Open/Closed/Container)
  - Capacity (tonnes)
  - Tyres (6/10/12-wheel)
  - Home location
  - Preferred routes
  - Operating states

INPUT: Current context
  - GPS location
  - Active trip status (if any)
  - Available from date
  - Hours driven today (fatigue check)

MATCHING LOGIC (Read-Only Query):
1. Get loads from marketplace (existing get_trucker_loads RPC)
2. Filter: pickup_date >= trucker.available_from
3. Filter: material_weight <= truck_capacity
4. Filter: truck_type matches OR "Any"
5. Sort by: rate_per_km DESC
6. Calculate: profit_estimate = rate - (fuel_cost + toll + driver_wage)
7. Return top 5 with voice summary
```

### 1.3 Voice Response Format

```
User: "Aas paas load dhoondo"

AI: "5 loads mile aapke truck ke liye:"
     ""
     "Number 1:"
     "Chandrapur se Mumbai, Coal, 25 tonnes"
     "Rate: 45,000 rupees"
     "Distance: 900 kilometer"
     "Profit estimate: 19,000 rupees"
     "Pickup: Kal subah 9 baje"
     ""
     "Number 2:"
     "Nagpur se Hyderabad, Steel, 20 tonnes"
     "Rate: 38,000 rupees..."
     ""
     "Konsa load dekhna hai?"
     "Ya 'saare batao' bolo."
```

### 1.4 Load Detail Deep Dive (Voice)

```
User: "Number 1 batao detail mein"

AI: "Load detail:"
     "Origin: Chandrapur, Maharashtra"
     "Destination: Navi Mumbai, Maharashtra"
     "Material: Coal, 25 tonnes"
     "Truck type: Open body, 10-wheel"
     "Rate: 45,000 rupees, fixed"
     "Advance: 20 percent"
     "Pickup: 23 April, 9:00 AM"
     "Supplier: ABC Logistics, Verified, 4.5 star"
     ""
     "Route estimate: Via NH6, 890 kilometer"
     "Time: 17-18 ghante"
     "Toll: approximately 850 rupees"
     "Fuel: approximately 22,500 rupees"
     "Net profit: approximately 19,000 rupees"
     "Per kilometer: 21 rupees"
     ""
     "Market average: 18-24 rupees per kilometer"
     "Verdict: Yeh load theek hai."
```

### 1.5 Profitability Calculator

```
User: "45,000 mein Chandrapur se Mumbai, profit kitna?"

AI: "Profit calculation:"
     "Revenue: 45,000 rupees"
     ""
     "Expenses estimate:"
     "  Fuel: 22,500 rupees"
     "  Toll: 850 rupees"
     "  Driver: 3,000 rupees"
     "  Food: 500 rupees"
     "  Misc: 500 rupees"
     ""
     "Total expense: 27,350 rupees"
     "Net profit: 17,650 rupees"
     "Profit per kilometer: 19.8 rupees"
     ""
     "Aapke last 5 trips ka average: 16,200 rupees profit"
     "Yeh load average se 1,450 rupees zyada hai."
     "Recommendation: Accept karo."
```

---

## 2. ROUTE CHECKING - GOOGLE MAPS + LOCAL FALLBACK

### 2.1 Route Query Voice Commands

| Hindi Command | English Command | Action |
|--------------|-----------------|--------|
| "Chandrapur se Mumbai ka rasta" | "Route from Chandrapur to Mumbai" | Multi-route comparison |
| "Best route kya hai?" | "What's the best route?" | Optimized route suggestion |
| "Toll kitna lagega?" | "How much toll?" | Toll plaza breakdown |
| "Kitna time lagega?" | "How much time?" | ETA with truck speed |
| "Highway pe petrol pump kahan?" | "Petrol pump on highway?" | POI search on route |
| "Khana kahan milega?" | "Where to eat?" | Food stops on route |

### 2.2 Online Route (Google Maps API Priority)

```
User: "Chandrapur se Mumbai ka rasta"

[IF INTERNET AVAILABLE]
AI: "3 routes mile:"
     ""
     "Route 1 - Recommended:"
     "Via NH6 (Nagpur, Amravati, Jalgaon)"
     "Distance: 890 kilometer"
     "Time: 17 ghante 30 minute"
     "Toll: 6 plazas, total 847 rupees"
     "Road condition: Good"
     ""
     "Route 2 - Shorter but single lane:"
     "Via NH53 (Mancherial, Adilabad)"
     "Distance: 850 kilometer"
     "Time: 19 ghante"
     "Toll: 4 plazas, total 620 rupees"
     "Road condition: Average, patches near Adilabad"
     ""
     "Route 3 - Expressway:"
     "Via Samruddhi Mahamarg (partial)"
     "Distance: 920 kilometer"
     "Time: 16 ghante"
     "Toll: 8 plazas, total 1,100 rupees"
     "Road condition: Excellent"
     ""
     "Recommendation: Route 1 - balance of time, cost, safety"
     "[Open Route 1 in Maps] [Save Route] [Toll Details]"
```

### 2.3 Offline Route (Local Database Fallback)

```
[IF NO INTERNET]

AI: "Internet nahi hai. Offline route bata raha hu:"
     ""
     "Chandrapur se Mumbai (Local database estimate):"
     "Straight line distance: 750 kilometer"
     "Highway estimate: 975 kilometer (x1.3 multiplier)"
     "Estimated time: 19-20 ghante"
     "Truck speed average: 50 km/h on highway"
     ""
     "Expected route via:"
     "Chandrapur - Nagpur - Amravati - Jalgaon - Nashik - Mumbai"
     ""
     "Toll estimate: 6-8 plazas"
     "Approximate toll cost: 800-1,000 rupees"
     ""
     "⚠️ Note: Ye estimate hai. Exact details ke liye internet chahiye."
     "[Save for Offline] [Try Internet Again]"
```

### 2.4 Route POI Discovery (On-Route Services)

```
User: "Raaste mein petrol pump aur khana kahan hai?"

AI: "Chandrapur se Mumbai route pe services:"
     ""
     "After 120 km - Nagpur:"
     "  HP Petrol Pump (NH6, right side)"
     "  Dhaba: Jay Bhavani (good food, truck parking)"
     "  Restroom: Available"
     ""
     "After 280 km - Amravati:"
     "  Indian Oil Petrol Pump"
     "  Hotel: Highway King (clean, AC)"
     "  Mechanic: Available"
     ""
     "After 450 km - Jalgaon:"
     "  Bharat Petroleum"
     "  Dhaba: Punjab Da Dhaba"
     "  Tire repair: Yes"
     ""
     "Total fuel stops recommended: 2"
     "Your 300L tank, 25T load = 4 km/litre"
     "Refuel at Nagpur and Nashik"
     "[Show on Map] [Save Route] [Add Reminder]"
```

### 2.5 Real-Time Traffic Integration

```
User: "Aage kya scene hai?"

[IF ONLINE]
AI: "Aage 45 km mein:"
     "Nagpur bypass pe construction chal raha hai"
     "Delay: 20-30 minute"
     "Alternative: Old NH7 bypass"
     "Detour: +8 km, same time"
     ""
     "After 200 km:"
     "Amravati toll plaza - moderate queue"
     "Estimated wait: 5 minute"
     "Fastag recommended"
     ""
     "Weather: Clear, no issues"
     "[Reroute] [Update Every 30 Min] [OK]"
```

---

## 3. DAY-TO-DAY TRUCKER HELP

### 3.1 Fuel & Services Locator

```
User: "Paas mein petrol pump dhoondo"

AI: "Aap abhi Nagpur se 20 km dur ho, NH6 pe"
     ""
     "Nearest petrol pumps:"
     ""
     "1. HP Petrol Pump - 5 km ahead"
     "   Right side, truck accessible"
     "   Diesel available, tyre pressure check"
     "   Rating: 4.2"
     ""
     "2. Indian Oil - 12 km ahead"
     "   Left side, highway dhaba attached"
     "   24/7, clean restroom"
     "   Rating: 4.5"
     ""
     "Your fuel level estimate: 45%"
     "Current range: ~180 km"
     "Recommendation: Refuel at option 1 (5 km)"
     "[Navigate to HP] [Navigate to Indian Oil] [Check Prices]"
```

### 3.2 Food & Rest Stops

```
User: "Khana kahan milega?"

AI: "Aapke route pe 3 achhe options:"
     ""
     "Option 1 - Jay Bhavani Dhaba (8 km):"
     "   North Indian, South Indian"
     "   Clean kitchen, truck parking"
     "   Budget: 150-200 rupees"
     "   Open: 6 AM - 11 PM"
     "   Rating: 4.3 (500+ reviews)"
     ""
     "Option 2 - Highway King (25 km):"
     "   AC restaurant, family section"
     "   Multiple cuisines"
     "   Budget: 300-400 rupees"
     "   Open: 24 hours"
     "   Rating: 4.6"
     ""
     "Aapne last break 3 ghante pehle liya tha."
     "1 ghante aur chalao, phir Option 1 pe ruko."
     "[Navigate] [Menu] [Parking Info]"
```

### 3.3 Rest & Break Reminders

```
AI (Proactive): "2 ghante se continuously drive kar rahe ho."
     "15 minute ka break lena zaroori hai."
     "Aage 10 km mein Jay Bhavani Dhaba hai - accha break spot."
     "[Take Break Now] [Remind in 30 Min] [Skip This Time]"
```

### 3.4 Mechanic & Emergency Services

```
User: "Mechanic chahiye, clutch mein problem hai"

AI: "Clutch problem? Immediate help:"
     ""
     "Nearest mechanics:"
     "1. Sharma Motors - 12 km ahead"
     "   Specialization: Heavy vehicles"
     "   Open: 8 AM - 9 PM"
     "   Phone: 98XXX-XXXXX"
     "   Rating: 4.4"
     ""
     "2. Highway Garage - 25 km ahead"
     "   24/7 service, Towing available"
     "   Phone: 97XXX-XXXXX"
     ""
     "Emergency alternative:"
     "  Call TranZfort support: 1800-XXX-XXXX"
     "  Ask other truckers on this route (chat)"
     ""
     "Temporary advice:"
     "  Clutch slip ho raha hai toh over-rev mat karo"
     "  Gradual gear shifting karo"
     "  Heavy load avoid karo agar possible ho"
     "[Call Mechanic] [Call Support] [Show Directions]"
```

---

## 4. TYRE PHOTO ANALYSIS - REMAINING LIFE ESTIMATION

### 4.1 Voice Flow

```
User: "Tyre ka photo lo aur batao kitna chalega"

AI: "Tyre ki photo lo. Camera khul raha hai..."
     "Tyre sidewall aur tread clear dikhe - paas se photo lo."
     ""
     [Camera opens with tyre overlay guide]
     [User captures photo]
     
AI: "Photo received. Analysis kar raha hu..."
     ""
     "Tyre Analysis Report:"
     ""
     "Brand: Apollo (detected from sidewall)"
     "Size: 10.00 R20 (estimated)"
     "Position: Rear axle (from wear pattern)"
     ""
     "Tread Depth Analysis:"
     "Current tread: 4.2 mm"
     "Legal minimum: 1.6 mm"
     "Remaining usable: 2.6 mm"
     ""
     "Wear Pattern:"
     "  Inner edge: Normal wear"
     "  Center: Slightly more wear (over-inflation possible)"
     "  Outer edge: Normal"
     "  Cuts/bruises: 2 minor detected"
     ""
     "Remaining Life Estimate:"
     "At current wear rate: 25,000 - 30,000 kilometer"
     "With 25T load on highway: 20,000 - 25,000 kilometer"
     ""
     "Recommendations:"
     "  Air pressure check karo - center wear = over-inflation"
     "  Alignment check recommended"
     "  Minor cuts monitoring needed"
     "  Rotate with front axle in 5,000 km"
     ""
     "Risk Level: LOW-MEDIUM"
     "Safe for current trip"
     "Plan replacement in next 2 months"
     "[Save Report] [Share with Mechanic] [Check Other Tyres] [Set Reminder]"
```

### 4.2 Multi-Tyre Fleet Assessment

```
User: "Saare tyres check karo"

AI: "Har tyre ki ek photo lo. Total 10 photos."
     "Front axle - Drive axle - Trailer axle"
     ""
     [User uploads 10 photos]
     
AI: "Fleet Tyre Assessment Complete:"
     ""
     "FRONT AXLE (2 tyres):"
     "  Tyre 1 (Left): Good, 35,000 km remaining"
     "  Tyre 2 (Right): Good, 32,000 km remaining"
     "  Status: HEALTHY"
     ""
     "DRIVE AXLE (4 tyres):"
     "  Tyre 3: Medium wear, 18,000 km, CHECK ALIGNMENT"
     "  Tyre 4: Good, 28,000 km remaining"
     "  Tyre 5: Low tread, 8,000 km, REPLACE SOON"
     "  Tyre 6: Good, 25,000 km remaining"
     "  Status: MIXED - Monitor tyre 5"
     ""
     "TRAILER AXLE (4 tyres):"
     "  Tyre 7: Good, 30,000 km remaining"
     "  Tyre 8: Sidewall damage, REPLACE URGENT"
     "  Tyre 9: Good, 28,000 km remaining"
     "  Tyre 10: Medium wear, 15,000 km remaining"
     "  Status: MIXED - Tyre 8 critical"
     ""
     "SUMMARY:"
     "  Healthy: 6 tyres"
     "  Monitor: 3 tyres"
     "  Replace soon: 1 tyre (Tyre 5)"
     "  Replace urgent: 1 tyre (Tyre 8 - sidewall damage)"
     ""
     "Estimated replacement cost: 12,000 - 15,000 rupees"
     "Recommendation: Replace tyre 8 before next long trip."
     "[Generate Full Report] [Find Tyre Dealer] [Schedule Service]"
```

---

## 5. GUARD RAILS - READ-ONLY AI ARCHITECTURE

### 5.1 Core Principle: ZERO WRITE OPERATIONS

The AI CANNOT:
- Post loads to marketplace
- Accept or reject bookings
- Update trip status or milestones
- Modify user profile
- Create/Edit/Delete database records
- Send messages on user's behalf
- Make payments or financial transactions
- Update truck details
- Upload documents automatically
- Delete any data

The AI CAN:
- Read and display existing data
- Calculate and estimate
- Analyze photos/documents
- Suggest routes and costs
- Answer questions
- Navigate to existing screens
- Provide recommendations (user must confirm action)

### 5.2 Implementation Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    AI Assistant Layer                      │
│                   (TARA - Voice Bot)                      │
├─────────────────────────────────────────────────────────┤
│                    Guard Rail Layer                        │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐      │
│  │ Command      │ │ Intent       │ │ Action       │      │
│  │ Parser       │ │ Validator    │ │ Router       │      │
│  │              │ │ (Read-only)  │ │ (Navigation) │      │
│  └─────────────┘ └─────────────┘ └─────────────┘      │
├─────────────────────────────────────────────────────────┤
│                    Data Access Layer                       │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐ │
│  │ TripRepo     │  │ LoadRepo     │  │ UserRepo     │ │
│  │ (read-only)  │  │ (read-only)  │  │ (read-only)  │ │
│  │ • getActive  │  │ • getLoads   │  │ • getProfile │ │
│  │ • getHistory │  │ • getMyLoads │  │ • getStatus  │ │
│  │ • getDetail  │  │ • getDetail  │  │ • getDocs    │ │
│  └──────────────┘  └──────────────┘  └──────────────┘ │
├─────────────────────────────────────────────────────────┤
│                    STRICT BLOCKS                           │
│  ❌ create_load()   ❌ update_trip()   ❌ send_message() │
│  ❌ post_booking()  ❌ edit_profile()  ❌ delete_trip()  │
│  ❌ assign_truck()  ❌ upload_doc()    ❌ make_payment() │
└─────────────────────────────────────────────────────────┘
```

### 5.3 Command Classification System

```dart
enum AiCommandType {
  READ_QUERY,      // ✅ Allowed: "Mera trip status kya hai?"
  READ_ANALYZE,    // ✅ Allowed: "Bilty scan karo" (reads photo, displays analysis)
  READ_CALCULATE,  // ✅ Allowed: "Profit kitna hai?"
  READ_NAVIGATE,   // ✅ Allowed: "Load detail khol" (opens screen with existing data)
  READ_SUGGEST,    // ✅ Allowed: "Best route batao"
  WRITE_ACTION,    // ❌ BLOCKED: "Booking accept karo" 
  WRITE_CREATE,    // ❌ BLOCKED: "Naya load post karo"
  WRITE_UPDATE,    // ❌ BLOCKED: "Trip complete karo"
  WRITE_DELETE,    // ❌ BLOCKED: "Load delete karo"
  UNCLEAR,         // ⚠️ Ask clarification
}
```

### 5.4 Response Templates for Blocked Actions

```
User: "Load post karo"
AI: "Sorry, main load post nahi kar sakta."
     "Main sirf madad kar sakta hu - details bata sakta hu,"
     "route plan kar sakta hu, cost estimate de sakta hu."
     ""
     "Load post karne ke liye:"
     "[Open Post Load Screen]"
     "Main wahan details fill karne mein help kar sakta hu."
     ""
     "Bolo, kaunsa route, material, weight?"
```

```
User: "Booking accept karo"
AI: "Sorry, main booking accept/reject nahi kar sakta."
     "Yeh aapko manually karna padega app mein."
     ""
     "Main booking details bata sakta hu:"
     "  Trucker: ABC Transport"
     "  Rating: 4.5"
     "  Trucks: 3 (Open Body, 10-wheel)"
     "  Last trip: 2 din pehle, completed"
     ""
     "[Open Booking Detail Screen]"
     "Wahan accept/reject kar sakte ho."
```

```
User: "Trip complete karo"
AI: "Main trip status update nahi kar sakta."
     "Yeh safety reason se aapko manually karna hai."
     ""
     "Main bata sakta hu:"
     "  Trip T-452: Mumbai - Delhi"
     "  Status: In Transit"
     "  Last update: 4 hours ago"
     "  Distance remaining: ~120 km"
     "  ETA: 3 hours"
     ""
     "Jab destination pahunche, app mein 'Mark Delivered' dabao."
     "Main uske baad proof upload mein help karunga."
     "[Open Trip Detail Screen]"
```

### 5.5 Safety Prompt Injection (System Level)

```
SYSTEM PROMPT (Always prepended to every LLM call):

"You are TARA, a helpful read-only assistant for Indian truckers."
"STRICT RULES:"
"1. You can ONLY READ and DISPLAY information."
"2. You CANNOT create, update, delete, or modify any data."
"3. You CANNOT perform actions on behalf of the user."
"4. You CANNOT send messages, make bookings, or post loads."
"5. If user asks for write action, politely decline and redirect."
"6. You CAN: analyze photos, read data, calculate costs, suggest routes, answer questions."
"7. You CAN: navigate user to app screens where THEY perform actions."
"8. Always speak in user's language (Hindi/English)."
"9. Be helpful but never override user decisions."
"10. When in doubt, provide information, don't take action."
```

---

## 6. OFFLINE CAPABLE ARCHITECTURE - TEMPORARY STORAGE

### 6.1 Design Principles

1. **No Persistent Cache**: All AI conversation data is session-only
2. **Temporary Storage**: Use RAM + temp files only, cleared on exit
3. **No History**: Previous conversations not stored
4. **Fresh Start**: Every AI session starts clean
5. **Auto-Cleanup**: Temp files deleted when app closes or session ends
6. **Device Clean**: No accumulation of AI data over time

### 6.2 Storage Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    AI MEMORY SYSTEM                        │
├─────────────────────────────────────────────────────────┤
│                                                            │
│  ┌─────────────┐        ┌─────────────┐                 │
│  │   IN-MEMORY │        │  TEMP FILES │                 │
│  │   SESSION   │        │  (Session)  │                 │
│  │   STORE     │        │  STORE      │                 │
│  │             │        │             │                 │
│  │ Current     │        │ Photo being │                 │
│  │ conversation│        │ analyzed    │                 │
│  │ messages    │        │ Document    │                 │
│  │ User context│        │ cache       │                 │
│  │ Active route│        │ Route data  │                 │
│  │ Voice state │        │ (temp)      │                 │
│  │             │        │             │                 │
│  │ Lifetime:   │        │ Lifetime:   │                 │
│  │ Session     │        │ Session     │                 │
│  │ only        │        │ only        │                 │
│  └─────────────┘        └─────────────┘                 │
│         ▲                      ▲                        │
│         │                      │                        │
│         └────── Session End ────┘                        │
│                    ↓                                      │
│              ┌─────────┐                               │
│              │  CLEAR  │  ← All temp data wiped         │
│              │  ALL    │                               │
│              └─────────┘                               │
│                                                            │
│  ┌─────────────┐        ┌─────────────┐                 │
│  │   EXISTING  │        │   MODEL     │                 │
│  │   APP CACHE │        │   CACHE     │                 │
│  │   (Shared)  │        │   (Persistent│                 │
│  │             │        │   only this) │                 │
│  │ User profile│        │             │                 │
│  │ Trip data   │        │ Gemma 3n    │                 │
│  │ Load lists  │        │ model file  │                 │
│  │ (managed by │        │ (~529MB)    │                 │
│  │  app)       │        │ Downloaded  │                 │
│  │             │        │ once, kept  │                 │
│  │ NOT AI data │        │ until update│                 │
│  └─────────────┘        └─────────────┘                 │
│                                                            │
└─────────────────────────────────────────────────────────┘
```

### 6.3 Session Lifecycle

```
Session Start:
  ├─ Create temp session directory: /tmp/ai_session_{uuid}/
  ├─ Initialize in-memory message buffer
  ├─ Load cached app data (trips, loads, profile)
  └─ Start voice listening

During Session:
  ├─ All conversation in memory only
  ├─ Photos analyzed in temp, results spoken, not stored
  ├─ Route calculations in memory, shown, then discarded
  ├─ Load suggestions fetched from server, displayed, not cached
  └─ Voice state maintained in memory

Session End (any of):
  ├─ User closes AI screen
  ├─ User presses "End Session" button
  ├─ App goes to background for >5 minutes
  ├─ App killed by system
  └─ User logs out

Cleanup:
  ├─ Clear all in-memory conversation data
  ├─ Delete temp session directory
  ├─ Release voice resources
  ├─ Cancel any pending downloads
  └─ Reset to clean state
```

### 6.4 Model Storage Only Persistent Item

```
Storage Hierarchy:

/data/data/com.tranzfort/app_flutter/
├── ai_models/                    ← PERSISTENT (only this)
│   ├── gemma3n_int4.task         ← Model file (529MB)
│   └── model_version.json         ← Version info for updates
│
├── ai_temp/                       ← TEMP (auto-cleared)
│   └── session_{uuid}/            ← Created per session
│       ├── photos/                ← Photo being analyzed
│       ├── voice_chunks/          ← Voice temp files
│       └── analysis_results/      ← Temporary results
│
└── (other app directories)

On app update: Keep ai_models/, clear ai_temp/
On session end: Delete ai_temp/session_{uuid}/
On logout: Clear ai_temp/, keep ai_models/
On storage pressure: Suggest clearing ai_models/ (user choice)
```

### 6.5 Session Data Contents (Auto-Cleared)

```
ai_temp/session_{uuid}/
├── conversation.json              ← Session messages (RAM-backed)
│   ├── user_message_1.wav         ← Voice recording (if voice input)
│   ├── ai_response_1.mp3          ← TTS output (temp)
│   ├── user_message_2.txt         ← Text input
│   └── ...
│
├── photos/
│   ├── temp_photo_1.jpg           ← Photo being analyzed
│   ├── analyzed_doc_1.json        ← OCR result (displayed, not saved)
│   └── ...
│
├── route_cache/
│   ├── current_calculation.json   ← Route being computed
│   └── poi_results.json           ← Nearby services (temp)
│
└── state.json                     ← Current session state
    ├── active_intent              ← What user is asking
    ├── context_stack              ← Conversation context
    └── pending_confirmation       ← Waiting for user confirmation
```

### 6.6 Data Privacy Guarantee

```
User Data Promise:

1. NO AI CONVERSATION HISTORY stored
   - Previous chats not remembered
   - No "you asked this yesterday"
   - Fresh start every time

2. NO PHOTO STORAGE
   - Photos analyzed immediately
   - Results spoken/displayed
   - Original photo deleted after analysis
   - No photo gallery in AI

3. NO PERSONAL DATA MINING
   - AI doesn't learn user habits
   - No personalized recommendations based on history
   - Each query independent

4. MODEL-LEVEL PRIVACY
   - All inference on-device
   - No data sent to cloud for AI processing
   - Only marketplace queries need internet (read-only)

5. USER CONTROL
   - "Clear all AI data" button available
   - Model can be deleted (reclaim 529MB)
   - Session can be ended anytime
```

---

## 7. OFFLINE-ONLINE HYBRID FLOW

### 7.1 Feature Availability Matrix

| Feature | Online Required | Offline Works | Cache Used |
|---------|----------------|---------------|------------|
| Voice Input (STT) | No | Yes | Device STT engine |
| Voice Output (TTS) | No | Yes | Device TTS engine |
| Gemma 3n Inference | No | Yes | Model file (persistent) |
| Document Photo Analysis | No | Yes | Temporary analysis |
| Trip Status Query | Partial | Cached data | App data cache |
| Load Discovery | Yes | No | Cannot show new loads |
| Route Planning (Google) | Yes | No | Needs API |
| Route Planning (Offline) | No | Yes | Local city database |
| Cost Calculation | No | Yes | Local math |
| Nearby Services | Yes | No | Needs Google Places |
| Weather | Yes | No | Needs weather API |
| Traffic Info | Yes | No | Needs traffic API |

### 7.2 Graceful Degradation Messages

```
User (offline): "Aas paas load dhoondo"
AI: "Internet nahi hai. Live loads nahi dhoond sakta."
     ""
     "Offline mein main help kar sakta hu:"
     "  • Aapke saved loads dekh sakta hu"
     "  • Route planning with local data"
     "  • Cost calculation"
     "  • Document analysis"
     "  • Trip status (cached)"
     ""
     "Internet connect karo for live marketplace."
     "[Try Again] [Use Offline Features]"
```

```
User (offline): "Weather kaisa hai?"
AI: "Weather real-time nahi dekh sakta - internet nahi hai."
     ""
     "General advice:"
     "  Mumbai area: Abhi garmi hai, 35-40°C"
     "  Barsaat ka season June se start hota hai"
     "  Highway pe pani ka backup rakho"
     ""
     "Internet connect karo for live weather."
```

---

## 8. IMPLEMENTATION PRIORITY

### Phase 1: Core Voice + Guard Rails (Week 1)
- [ ] AI floating button with TARA avatar
- [ ] Voice input/output system
- [ ] Command parser with read-only validator
- [ ] Guard rail layer (blocks all write operations)
- [ ] Basic responses: "I can read but not modify"

### Phase 2: Load Discovery + Route (Week 2)
- [ ] Marketplace load suggestion via voice
- [ ] Profit calculator
- [ ] Google Maps route (online)
- [ ] Local database route fallback (offline)
- [ ] Toll estimation

### Phase 3: Day-to-Day Help (Week 3)
- [ ] Fuel/services locator
- [ ] Food/rest stop finder
- [ ] Rest break reminders (proactive)
- [ ] Mechanic emergency services
- [ ] Nearby POI discovery

### Phase 4: Document AI + Tyre (Week 4)
- [ ] Bilty scan + OCR
- [ ] Receipt analysis
- [ ] Tyre photo analysis with life estimation
- [ ] Vehicle condition assessment
- [ ] Cargo damage documentation

### Phase 5: Offline Polish (Week 5)
- [ ] Temporary storage architecture
- [ ] Session auto-cleanup
- [ ] Offline graceful degradation
- [ ] Storage pressure handling
- [ ] Model update mechanism

---

*End of AI Features Brainstorm V2*
