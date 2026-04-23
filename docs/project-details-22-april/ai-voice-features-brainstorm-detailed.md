---
title: AI Voice Assistant - Detailed Feature Brainstorm
date: April 22, 2026
version: 1.0
purpose: Voice-first AI design with camera integration, floating button, and interaction flow
status: DEFERRED

# AI Voice Assistant - Detailed Feature Brainstorm

> **⚠️ STATUS: DEFERRED (April 22, 2026)**
>
> This AI voice assistant feature brainstorm is retained for reference.
>
> **Decision:** AI integration deferred due to inference time and quality not meeting expectations.
> **Reason:** On-device AI inference (flutter_gemma) produced slow responses and repetitive, low-quality answers.
> **Future Plan:** Will be revisited in a future version with a different approach (potentially cloud-based AI or improved on-device models).
>
> See `TODO-22-april.md` for complete rollback details.

## 1. CORE PHILOSOPHY: VOICE-FIRST DESIGN

### Why Voice-First for Truckers?
- **Hands-free operation** while driving
- **Low literacy barrier** - speak in Hindi/English/Hinglish
- **Faster than typing** on bumpy roads
- **Natural for Indian market** - voice memos, WhatsApp audio culture
- **Eyes stay on road** - critical safety feature

### Chat vs Voice Decision
| Aspect | Text Chat | Voice-First |
|--------|-----------|-------------|
| Truck driver use | ❌ Hard to type while driving | ✅ Speak naturally |
| Literacy barrier | ❌ Requires typing | ✅ Just speak |
| Road safety | ❌ Eyes off road | ✅ Keep eyes forward |
| Speed | ❌ Slow input | ✅ Instant input |
| Learning curve | ❌ UI navigation needed | ✅ Natural conversation |
| **Final Decision** | **VOICE-FIRST with optional text fallback** |

---

## 2. FLOATING AI BUTTON DESIGN

### Visual Specifications

```
┌─────────────────────────────────────────┐
│                                         │
│    ╭───────────────╮                    │
│    │   🤖          │  ← AI Bot Icon    │
│    │   TARA        │                    │
│    ╰───────────────╯                    │
│         Floating Button                 │
│                                         │
└─────────────────────────────────────────┘
```

**Button Appearance:**
- **Shape**: Circular (56dp diameter)
- **Position**: Bottom-right, 16dp from edges, floating above nav bar
- **Elevation**: 8dp (strong shadow for prominence)
- **Background**: Gradient from Teal (#00897B) to Teal Dark (#004D40)
- **Icon**: Animated robot/assistant face (Lottie animation)
- **Pulse Effect**: Subtle breathing animation when AI is "thinking"
- **Badge**: Red dot when new AI suggestion available

**States:**

| State | Visual | Animation |
|-------|--------|-----------|
| **Idle** | Solid teal, robot icon | Gentle floating (up/down 2px) |
| **Listening** | Expanding circle, microphone icon | Pulse rings expanding outward |
| **Processing** | Rotating gradient, loading dots | Spinning gradient + thinking dots |
| **Speaking** | Waveform visualization | Audio wave bars animating |
| **Offline** | Grey icon, muted | No animation |

**Micro-interactions:**
- **Haptic feedback** on long press
- **Ripple effect** on tap
- **Scale up to 1.1x** when active
- **Glow effect** (teal aura) when listening

---

## 3. VOICE INTERACTION PAGE DESIGN

### Screen Layout (Voice-First Mode)

```
┌─────────────────────────────────────────┐
│ [←]  AI Assistant          [Settings] │ ← Header
├─────────────────────────────────────────┤
│                                         │
│     ┌─────────────────┐                │
│     │                 │                │
│     │   🤖 TARA       │  ← AI Avatar   │
│     │   [Animated]    │    (Center)    │
│     │                 │                │
│     └─────────────────┘                │
│                                         │
│    "Namaste! Main TARA hoon."          │ ← Subtitle text
│    "Bolo, main madad karunga!"         │
│                                         │
│                                         │
│    ╭─────────────────────────────────╮│
│    │                                 ││
│    │    [AUDIO WAVE VISUALIZATION]   ││ ← Voice input
│    │         ▁▃▅▇▇▅▃▁               ││    indicator
│    │                                 ││
│    │    "Bolta rahiye..."           ││
│    │                                 ││
│    ╰─────────────────────────────────╯│
│                                         │
│    [📷]  [🎙️ HOLD TO SPEAK]  [📎]     │ ← Controls
│                                         │
│    Quick Actions:                       │
│    ┌─────┐ ┌─────┐ ┌─────┐ ┌─────┐   │
│    │Bilty│ │Trip │ │Route│ │Fuel │   │
│    │Scan │ │Status│ │Help │ │Calc │   │
│    └─────┘ └─────┘ └─────┘ └─────┘   │
│                                         │
└─────────────────────────────────────────┘
```

### Full-Screen Voice Mode (Active)

```
┌─────────────────────────────────────────┐
│                                         │
│         ┌─────────────┐               │
│         │             │               │
│         │    🤖       │  ← Large      │
│         │   TARA      │    animated   │
│         │  [Orb]      │    avatar     │
│         │             │               │
│         └─────────────┘               │
│                                         │
│    "Chandrapur se Mumbai ka             │
│     route batao..."                     │ ← User voice
│    ─────────────────────                │    transcript
│                                         │
│    [REAL-TIME AUDIO WAVE - FULL WIDTH] │
│                                         │
│    "Nagpur se ho kar jao,              │
│     950 km hai, 18 ghante               │ ← AI response
│     lagenge..."                         │    (spoken)
│                                         │
│         [🛑 STOP]                       │ ← Big stop button
│                                         │
└─────────────────────────────────────────┘
```

---

## 4. AI CAPABILITIES WITH CAMERA/UPLOAD

### Feature 1: Bilty Document Scanning (Voice-Triggered)

**User Flow:**
```
User: "Bilty scan karo"
AI: "Bilty ki photo lo. Camera khul raha hai..."
     ↓
[Camera Opens with Document Overlay Guide]
     ↓
User captures photo
     ↓
AI: "Bilty samajh liya. Details:"
     "Chandrapur se Mumbai, Coal, 25 tonnes"
     "Route: NH6, 900 km, ~18 ghante"
     "Toll: ~₹850 (5 toll plazas)"
     "Google Maps link bhej raha hu..."
```

**Visual Flow:**
```
┌─────────────────────────────────────────┐
│  [Camera Preview with Document Frame]  │
│                                         │
│    ╭─────────────────────╮             │
│    │  ┌─────────────┐   │             │
│    │  │             │   │  ← Document │
│    │  │   BILTY     │   │    overlay  │
│    │  │   [📄]      │   │             │
│    │  │             │   │             │
│    │  └─────────────┘   │             │
│    ╰─────────────────────╯             │
│                                         │
│  [Capture]  [Gallery]  [Flash]          │
│                                         │
│  🎙️ "Bilty frame me rakho aur          │
│      capture dabao"                    │
│                                         │
└─────────────────────────────────────────┘
```

**Extracted Information Display:**
```
┌─────────────────────────────────────────┐
│  ✅ Bilty Analysis Complete            │
│                                         │
│  ┌─────────────────────────────────┐   │
│  │ 📄 Bilty #: BTL-2026-4521       │   │
│  │ 🏭 Material: Coal               │   │
│  │ ⚖️ Weight: 25 tonnes            │   │
│  │ 📍 Origin: Chandrapur, MH       │   │
│  │ 🎯 Destination: Mumbai, MH      │   │
│  │ 🚛 Vehicle: MH-12-AB-3456       │   │
│  └─────────────────────────────────┘   │
│                                         │
│  [📍 Open Route in Maps]               │
│  [💾 Save to Trip]                     │
│  [🔄 Scan Another]                     │
│                                         │
└─────────────────────────────────────────┘
```

### Feature 2: Fuel Receipt Analysis

**User Flow:**
```
User: "Fuel receipt check karo"
AI: "Receipt ki photo lo"
     ↓
[Camera/Gallery - User uploads]
     ↓
AI: "Receipt analysis:"
     "Amount: ₹8,500"
     "Rate: ₹95/litre"
     "Quantity: 89.5 litres"
     "Date: 22 April 2026"
     "Station: HP Petrol Pump, Nagpur"
     ""
     "Average se ₹2/litre zyada hai"
     "Total expense track kar raha hu..."
```

### Feature 3: Vehicle Condition Assessment

**User Flow:**
```
User: "Truck ki problem batao"
AI: "Kya problem aa rahi hai? Photo lo ya batao"
     ↓
User: "Dekho vibration ho raha hai speed pe"
     ↓
AI: "Check karo:"
     "1. Tyre pressure - sab equal hai?"
     "2. Wheel balancing - kab hua tha?"
     "3. Suspension - koi awaaz?"
     "4. Engine mount - theek hai?"
     ""
     "Photo bhejo tyre aur suspension ki"
     ↓
[User uploads photos]
     ↓
AI: "Photos dekhi. Suggestions:"
     "Pehle tyre check karo - cuts/kharoch"
     "Phir mechanic dikhana - possible bearing issue"
```

### Feature 4: Cargo Damage Documentation

**User Flow:**
```
User: "Mal damage ho gaya"
AI: "Oh no! Pehle photos lo damage ki"
     ↓
[Multi-photo capture mode]
     ↓
AI: "Photos received. Analysis:"
     "Damage extent: 15-20% packaging"
     "Material: Cement bags (visible)"
     "Recommended action:"
     "1. Supplier ko turant inform karo"
     "2. Photos load detail me add karo"
     "3. Dispute raise karo agar serious hai"
     ""
     "Kya dispute raise karna hai?"
```

---

## 5. VOICE COMMAND CATEGORIES

### Category A: Trip Operations (Most Used)

| Voice Command (Hindi) | Voice Command (English) | Action |
|----------------------|------------------------|--------|
"Mera trip status kya hai?" | "What's my trip status?" | Read active trip details |
"Aaj pickup kahan hai?" | "Where is today's pickup?" | Show next pickup location |
"Route batao" | "Tell me the route" | Give turn-by-turn guidance |
"Kitna time bacha hai?" | "How much time left?" | ETA to destination |
"POD upload karo" | "Upload POD" | Open camera for POD capture |
"Pickup complete karo" | "Mark pickup done" | Update milestone + capture GPS |

### Category B: Document Scanning

| Voice Command | Action |
|--------------|--------|
"Bilty scan karo" | Open camera, OCR bilty, extract details |
"Receipt check karo" | Scan receipt, extract amount, compare prices |
"Document upload karo" | Generic document capture |
"POD photo lo" | Capture delivery proof |
"Insurance check karo" | Scan insurance doc, show expiry |

### Category C: Cost & Route Calculations

| Voice Command (Hindi) | Action |
|----------------------|--------|
"Chandrapur se Mumbai fuel kitna lagega?" | Calculate fuel cost |
"45,000 mein 900 km, theek hai?" | Analyze rate profitability |
"Toll charges batao" | Show toll plazas + estimated cost |
"Best route kya hai?" | Compare routes, suggest optimal |
"Driver ka kharcha kitna?" | Calculate driver costs |

### Category D: Load Discovery

| Voice Command | Action |
|--------------|--------|
"Mere aas paas load dhoondo" | Find loads near current location |
"Coal loads dhoondo" | Filter by material |
"Kal ke liye load chahiye" | Filter by pickup date |
"Mere truck type ke hisaab se" | Match with registered truck |

### Category E: Help & Emergency

| Voice Command | Action |
|--------------|--------|
"Emergency mein kya karna hai?" | Show emergency contacts, procedures |
"Police ka number do" | Show local police station contact |
"Mechanic chahiye" | Show nearby mechanics |
"Hospital kahan hai?" | Show nearest hospitals |
"Rasta bhool gaya" | Re-route assistance |

---

## 6. VOICE INTERACTION PATTERNS

### Pattern 1: Direct Question → Direct Answer

```
User: "Mera next pickup kahan hai?"
AI: "Aapka next pickup Nagpur mein hai"
     "Address: Industrial Area, Plot 45"
     "Time: 2:00 PM"
     "Material: Coal, 25 tonnes"
     ""
     "[Open in Maps] [Call Supplier]"
```

### Pattern 2: Command → Confirmation → Action

```
User: "Pickup complete karo"
AI: "Confirm karo - pickup ho gaya?"
     "Load: Coal, 25 tonnes"
     "Location: Chandrapur"
     "Time: Abhi"
     ""
     "[Ha, Complete] [Nahi, Ruko]"
     ↓
User: "Ha, complete karo"
AI: "Pickup marked complete. Supplier ko notification bhej diya."
     "Ab delivery ke liye niklo. Safe journey!"
```

### Pattern 3: Multi-Step Conversation

```
User: "Route plan karo"
AI: "Kahan se kahan tak?"
User: "Chandrapur se Mumbai"
AI: "Kitna weight?"
User: "25 tonnes"
AI: "Route analysis:"
     "Option 1: Via Nagpur-NH6"
     "   Distance: 950 km"
     "   Time: 18 hours"
     "   Toll: ₹850"
     "   Fuel: ~240 litres"
     ""
     "Option 2: Via Hyderabad (longer but better roads)"
     "   Distance: 1050 km"
     "   Time: 20 hours"
     "   Toll: ₹920"
     ""
     "[Open Option 1] [Open Option 2] [Save for Later]"
```

### Pattern 4: Image + Voice Combined

```
User: "Dekho yeh kya hai?" [uploads photo]
AI: "Photo dekhi. Yeh ek loading receipt (bilty) hai."
     "Main details extract kar raha hu..."
     ""
     "Origin: Chandrapur"
     "Destination: Mumbai"
     "Material: Coal"
     "Weight: 25 tonnes"
     ""
     "Sahi hai? Trip se match karta hai?"
User: "Ha, sahi hai"
AI: "Great! Bilty details trip mein save kar diye."
```

---

## 7. AI PERSONA: "TARA"

### Name Meaning
**T**rucking **A**ssistant for **R**oute & **A**dvisory

### Character Traits
- **Helpful**: Always ready to assist
- **Knowledgeable**: Knows trucking, routes, costs
- **Patient**: Repeats if user didn't understand
- **Culturally Appropriate**: Uses Hindi/Hinglish, respects trucker culture
- **Safety-Focused**: Reminds about breaks, speed limits

### Voice Characteristics (TTS)
- **Language**: Hindi/English based on user preference
- **Speed**: 0.9x (slightly slower for clarity)
- **Tone**: Warm, friendly, professional
- **Pitch**: Medium (not too high, not too low)
- **Accent**: Neutral Indian English / Clear Hindi

### Sample Dialogues

**Greeting:**
```
"Namaste! Main TARA hoon, aapka trucking assistant."
"Bolo, main aapki kya madad kar sakta hu?"
```

**Acknowledging Success:**
```
"Bahut badhiya! Trip successfully complete ho gaya."
"Aapne 2,450 km ka safar pura kiya."
"Rating: ⭐⭐⭐⭐⭐"
```

**Handling Problems:**
```
"Koi baat nahi, main help karunga."
"Pehle pareshani samjhao, phir solution nikalege."
```

**Safety Reminders:**
```
"2 ghante se drive kar rahe ho. 15 min ka break lo."
"Aage 5 km mein toll plaza hai. Slow down."
"Raat ho gayi hai. Sleepy feel ho raha hai toh rest karo."
```

---

## 8. QUICK ACTION CHIPS

### Persistent Bottom Chips (Context-Aware)

```
┌─────────────────────────────────────────┐
│                                         │
│  Quick Actions:                         │
│                                         │
│  ┌────────┐ ┌────────┐ ┌────────┐     │
│  │ 📄     │ │ 🚛     │ │ 🗺️     │     │
│  │ Bilty  │ │ My     │ │ Route  │     │
│  │ Scan   │ │ Trip   │ │ Help   │     │
│  └────────┘ └────────┘ └────────┘     │
│                                         │
│  ┌────────┐ ┌────────┐ ┌────────┐     │
│  │ ⛽     │ │ 💰     │ │ ⚠️     │     │
│  │ Fuel   │ │ Cost   │ │ Report │     │
│  │ Calc   │ │ Check  │ │ Issue  │     │
│  └────────┘ └────────┘ └────────┘     │
│                                         │
└─────────────────────────────────────────┘
```

**Dynamic Chips Based on Context:**

| Context | Chips Shown |
|---------|-------------|
| Active trip | "Trip Status", "Navigate", "Upload POD", "Call Supplier" |
| At pickup location | "Mark Pickup", "Take Photo", "Note Delay" |
| On highway | "Next Stop", "Fuel Check", "Rest Reminder" |
| Idle/No trip | "Find Loads", "My Trucks", "Route Planner" |
| Document uploaded | "Analyze", "Save", "Share", "Delete" |

---

## 9. CAMERA INTEGRATION SPECIFICATIONS

### Camera Overlay Modes

**Mode 1: Document Capture (Bilty/Receipt)**
```
┌─────────────────────────────────────────┐
│  ┌─────────────────────────────────┐   │
│  │  ╭─────────────────────────╮   │   │
│  │  │                         │   │   │
│  │  │    Document Border      │   │   │
│  │  │    ┌─────────────┐      │   │   │
│  │  │    │             │      │   │   │
│  │  │    │   [FRAME]   │      │   │   │
│  │  │    │             │      │   │   │
│  │  │    └─────────────┘      │   │   │
│  │  │                         │   │   │
│  │  ╰─────────────────────────╯   │   │
│  └─────────────────────────────────┘   │
│                                         │
│  📄 Align document in frame             │
│  Ensure all corners are visible         │
│                                         │
│  [📷 Capture]  [Gallery]  [Flash]       │
└─────────────────────────────────────────┘
```

**Mode 2: Damage/Cargo Photo**
```
┌─────────────────────────────────────────┐
│  [Camera Preview]                       │
│                                         │
│  Photo 1/3                              │
│                                         │
│  Tips:                                  │
│  • Capture damage clearly               │
│  • Include surrounding context          │
│  • Take close-up and wide shots         │
│                                         │
│  [📷]  [✓ Done]  [Retake]             │
└─────────────────────────────────────────┘
```

**Mode 3: General Upload**
```
┌─────────────────────────────────────────┐
│                                         │
│  Choose source:                         │
│                                         │
│     [📷 Camera]    [🖼️ Gallery]        │
│                                         │
│  Or describe:                          │
│  ┌─────────────────────────────────┐   │
│  │  Type or speak description... │   │
│  └─────────────────────────────────┘   │
│                                         │
└─────────────────────────────────────────┘
```

---

## 10. OFFLINE CAPABILITY MATRIX

| Feature | Online Required | Offline Works |
|---------|----------------|---------------|
| Voice Input/Output | ❌ No | ✅ Yes (on-device STT/TTS) |
| Document OCR | ⚠️ Partial | ✅ Gemma 3n vision works offline |
| Route Planning | ❌ No | ✅ Pre-loaded city data |
| Cost Calculation | ❌ No | ✅ Local math operations |
| Trip Status | ⚠️ Yes | ✅ Cached data |
| Live Traffic | ✅ Yes | ❌ Not available |
| Weather | ✅ Yes | ❌ Not available |
| New Load Search | ✅ Yes | ❌ Requires server |

---

## 11. ERROR HANDLING (Voice)

### Didn't Understand User
```
AI: "Sorry, samajh nahi aaya. Phir se bolo?"
     "Ya text mein likho..."
     [Show text input field]
```

### Network Unavailable
```
AI: "Internet nahi hai. Offline mode mein kaam kar raha hu."
     "Jo details phone mein saved hai, wahi dikha sakta hu."
     "Live data nahi milega."
```

### Model Not Downloaded
```
AI: "AI model download karna padega."
     "Size: 529 MB"
     "[Download Now] [Later]"
```

### Ambiguous Request
```
User: "Status batao"
AI: "Kiska status?"
     "[Trip Status] [Verification Status] [Payment Status]"
```

---

## 12. IMPLEMENTATION PRIORITY

### Phase 1: Core Voice (Week 1)
- [ ] Floating AI button with animations
- [ ] Voice input (STT)
- [ ] Voice output (TTS)
- [ ] Basic greeting + "I didn't understand"

### Phase 2: Trip Integration (Week 2)
- [ ] "Trip status" query
- [ ] "Pickup complete" command
- [ ] "Route batao" with offline data
- [ ] Cost calculations

### Phase 3: Document AI (Week 3)
- [ ] Bilty scan + OCR
- [ ] Receipt analysis
- [ ] POD upload workflow
- [ ] Image + voice combination

### Phase 4: Advanced Features (Week 4)
- [ ] Load discovery via voice
- [ ] Emergency help
- [ ] Vehicle diagnostics
- [ ] Hindi/English bilingual

---

## 13. SUCCESS METRICS

| Metric | Target |
|--------|--------|
| Voice recognition accuracy (Hindi) | >85% |
| Document OCR accuracy | >90% |
| Average response time | <2 seconds |
| User satisfaction rating | >4.0/5 |
| Daily active AI users | >30% of DAU |
| Model download completion rate | >70% |

---

*End of Voice-First AI Feature Brainstorm*
*Ready for implementation*
