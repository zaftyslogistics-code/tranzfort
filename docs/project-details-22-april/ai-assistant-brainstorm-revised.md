---
title: AI Assistant - Revised Brainstorm (Local LLM, Read-Only)
date: April 22, 2026
version: 2.0
purpose: Revised AI assistant approach using local LLM for daily task help, read-only operations, offline capability
status: DEFERRED

# AI Assistant - Revised Brainstorm (Local LLM, Read-Only)

> **⚠️ STATUS: DEFERRED (April 22, 2026)**
>
> This AI assistant brainstorm and design document is retained for reference.
>
> **Decision:** AI integration deferred due to inference time and quality not meeting expectations.
> **Reason:** On-device AI inference (flutter_gemma) produced slow responses and repetitive, low-quality answers.
> **Future Plan:** Will be revisited in a future version with a different approach (potentially cloud-based AI or improved on-device models).
>
> See `TODO-22-april.md` for complete rollback details.

## 1. PIVOT SUMMARY

### Original Plan (Now Discarded)
- Rule-based bot with 7 intents (findLoad, postLoad, myLoads, myTrips, etc.)
- Slot-filling flows for load operations
- Write operations (posting loads, booking trips)
- Risk: Shadow workflow system, maintenance burden

### New Direction
- **Local LLM-powered AI assistant** (Gemma 3/4 or similar)
- **Read-only operations only** (no write mutations)
- **100% offline capable** (works without internet)
- **General-purpose daily task helper** for truckers
- **Image processing add-on** (bilty OCR, document analysis, route suggestions)
- **Fast responses** (prioritize speed over deep reasoning)

---

## 2. RESEARCH FINDINGS: LOCAL LLM OPTIONS

### 2.1 Gemma 3 1B (Primary Candidate)

**Package**: `flutter_gemma` (https://pub.dev/packages/flutter_gemma)
- **Model Size**: 529MB (quantized int4)
- **Hardware Requirement**: Minimum 4GB RAM
- **Performance**: Up to 2,585 tokens/second (prefill)
- **Platforms**: Android, iOS, Web, Desktop
- **Backend**: CPU or GPU (user-selectable)
- **Context Length**: 2,048 tokens
- **Multimodal**: Gemma3n models support vision input
- **License**: Open weights (HuggingFace gated access required)

**Key Features**:
- Offline availability (no cloud dependency)
- No API costs
- Low latency (local inference)
- Privacy (data never leaves device)
- Fine-tunable for domain-specific use cases
- Supports LoRA weights for customization without full retraining

**Download Source**:
- HuggingFace: `litert-community/gemma-3-1b-it-int4.task`
- Requires HuggingFace token and access request

### 2.2 Gemma 4 (Next-Gen Option)

**Status**: Released April 2026, day-0 support for multiple inference engines
- **Multimodal Capabilities**: Native OCR, document parsing, object detection, pointing
- **Architecture**: Shared KV cache, per-layer embeddings (PLE), dual RoPE
- **Model Sizes**: 31B dense, 26B MoE (Mixture of Experts) with 4B active parameters
- **Performance**: LMArena score ~1,450 (text-only)
- **Use Cases**: GUI detection, video understanding, speech-to-text, function calling

**For Mobile**:
- Smaller models likely available for on-device deployment
- ONNX checkpoints for edge devices and browser
- Better OCR and document understanding than Gemma 3

### 2.3 Alternative Options

| Model | Size | RAM | Notes |
|-------|------|-----|-------|
| Phi-4 | ~3B | 4GB+ | Microsoft, strong reasoning, smaller footprint |
| Qwen 2.5 1.5B | 1.5B | 3GB+ | Alibaba, good multilingual |
| SmolLM | <1B | 2GB+ | Very small, limited reasoning |
| DeepSeek V3 | Various | 6GB+ | Strong but larger |

**Recommendation**: Start with **Gemma 3 1B** for production (battle-tested, documented). Evaluate Gemma 4 smaller variants when available for mobile.

---

## 3. HARDWARE REQUIREMENTS

### 3.1 Minimum Device Specs for Gemma 3 1B

| Component | Minimum | Recommended |
|-----------|---------|-------------|
| RAM | 4GB | 6GB |
| Storage | 1.5GB (model + app) | 2GB |
| CPU | Any modern SoC | Snapdragon Gen 6+ |
| GPU | Not required (CPU fallback) | Adreno 600+ (for GPU acceleration) |

### 3.2 Trucker Phone Reality Check

**Typical Budget Android Phones in India (₹10,000-15,000 range)**:
- RAM: 4GB (common), 3GB (older models)
- Storage: 64GB (expandable via SD card)
- CPU: MediaTek Helio G85 / Snapdragon 665
- GPU: Mali G52 / Adreno 610

**Verdict**: 4GB RAM threshold is achievable on current budget phones. 3GB devices may struggle.

### 3.3 Storage Strategy

**Model Download**:
- First-time download: 529MB (WiFi required)
- Cached locally after download
- Can be moved to SD card if supported
- App shows download progress with retry capability

**Fallback for Low Storage**:
- Offer "Lite mode" with smaller model (Gemma 3 270M at ~200MB)
- Trade-off: Reduced reasoning quality, still functional for basic tasks

---

## 4. REVISED AI ASSISTANT SCOPE (READ-ONLY)

### 4.1 Core Principle: READ-ONLY ACCESS

**What AI CAN do**:
- Read and analyze user's data (trips, loads, documents)
- Provide insights and explanations
- Suggest routes and navigation
- Extract information from images (bilty, receipts, documents)
- Answer questions about the app and logistics
- Help with daily calculations (fuel cost, distance, time)
- Translate between Hindi and English

**What AI CANNOT do**:
- Post loads to marketplace
- Accept or reject bookings
- Update trip status
- Modify user profile
- Execute any write operations to database
- Make decisions on behalf of user

### 4.2 Use Case Categories

#### Category A: Document & Image Analysis

**Use Case 1: Bilty/LR Analysis**
- User takes photo of bilty (loading receipt)
- AI extracts: origin, destination, material, weight, vehicle number
- AI explains: "This bilty shows Coal from Chandrapur to Mumbai, 25 tonnes"
- AI suggests: "Route is 900km via NH6. Estimated time: 18 hours"
- AI provides: Google Maps link or offline map suggestion

**Use Case 2: Receipt & Invoice Processing**
- User uploads fuel receipt image
- AI extracts: fuel amount, price per liter, total cost, date, station
- AI calculates: "This fill cost ₹8,500 at ₹95/liter. 89.5 liters filled"
- AI compares: "This is ₹2/l higher than average for this route"

**Use Case 3: Document Q&A**
- User uploads PDF (insurance policy, vehicle RC)
- User asks: "When does my insurance expire?"
- AI answers from document: "Your insurance expires on 15 August 2026"

#### Category B: Navigation & Route Assistance

**Use Case 4: Route Planning**
- User: "I need to go from Nagpur to Hyderabad with 30 tonnes coal"
- AI: "Best route is NH44 via Nizamabad. 500km, 12 hours. Avoid NH163 (steep sections)."
- AI: "Fuel cost estimate: ₹12,000 (assuming ₹4/km for 30T truck)"
- AI: "Toll charges: ~₹850 (5 toll plazas)"
- AI provides: Google Maps link with route

**Use Case 5: Real-time Traffic Advice**
- User: "Is there traffic on NH6 near Nagpur?"
- AI: "I don't have real-time traffic data (offline mode). Check Google Maps for live traffic."
- AI: "Typical congestion hours: 8-10 AM and 5-7 PM near Butibori industrial area."

#### Category C: Daily Task Calculations

**Use Case 6: Fuel Cost Calculator**
- User: "How much fuel for 800km with 25T truck?"
- AI: "Assuming 4 km/liter for 25T truck on highway: 200 liters needed. At ₹95/liter: ₹19,000."

**Use Case 7: Trip Profitability**
- User: "I'm getting ₹45,000 for Chandrapur-Mumbai (900km). Is this good?"
- AI: "Revenue: ₹45,000. Fuel cost: ~₹21,375 (225L × ₹95). Toll: ~₹1,200. Driver: ₹3,000. Net: ~₹19,425."
- AI: "This is ~₹21.6/km. Average market rate: ₹18-25/km. Good deal."

**Use Case 8: Time Estimation**
- User: "How long for Delhi to Jaipur with 20T?"
- AI: "Distance: 280km. Average speed: 40km/h (highway with stops). Estimated: 7 hours."

#### Category D: App & Account Queries

**Use Case 9: Trip Status**
- User: "What's my current trip status?"
- AI reads from app data: "You have 1 active trip: Coal from Chandrapur to Mumbai. Status: pickup_pending. Pickup scheduled: Tomorrow 9 AM."

**Use Case 10: Payment Status**
- User: "Did I get paid for last trip?"
- AI reads from app data: "Last trip: Nagpur-Hyderabad (completed). Payment: ₹38,000. Status: settled on 18 April 2026."

**Use Case 11: Verification Status**
- User: "Is my verification complete?"
- AI reads from app data: "Verification status: approved. Verified on: 10 March 2026. Documents: Aadhaar, PAN, Truck RC."

#### Category E: General Knowledge & Help

**Use Case 12: Weather**
- User: "What's the weather in Mumbai?"
- AI: "I don't have real-time weather data (offline mode). Check weather app before starting trip."
- AI: "General advice: Mumbai is humid year-round. Monsoon season: June-September."

**Use Case 13: Truck Maintenance**
- User: "My truck is vibrating at high speed. What should I check?"
- AI: "Common causes: 1) Wheel imbalance, 2) Tire wear, 3) Suspension issues, 4) Engine misfire. Check tires first, then visit mechanic."

**Use Case 14: Regulatory Info**
- User: "What documents do I need for inter-state transport?"
- AI: "Required: 1) Vehicle RC, 2) Valid insurance, 3) Pollution certificate, 4) Fitness certificate, 5) Driver license, 6) Consignment note (bilty)."

#### Category F: Language & Translation

**Use Case 15: Hindi-English Translation**
- User: "Translate to English: 'Mera truck Nagpur mein hai'"
- AI: "My truck is in Nagpur."

**Use Case 16: English-Hindi Translation**
- User: "Translate to Hindi: 'How much fuel do I need?'"
- AI: "Mujhe kitna fuel chahiye?"

---

## 5. TECHNICAL ARCHITECTURE

### 5.1 System Architecture

```
┌─────────────────────────────────────────────────────────┐
│                   TranZfort App                          │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  ┌──────────────────┐      ┌──────────────────────┐   │
│  │  AI Chat Screen  │      │  Image Upload UI     │   │
│  └────────┬─────────┘      └──────────┬───────────┘   │
│           │                            │                │
│           └────────────┬───────────────┘                │
│                        │                                │
│           ┌────────────▼────────────┐                   │
│           │   AI Assistant Service │                   │
│           │  (Riverpod Provider)    │                   │
│           └────────────┬────────────┘                   │
│                        │                                │
│      ┌─────────────────┼─────────────────┐             │
│      │                 │                 │             │
│      ▼                 ▼                 ▼             │
│ ┌─────────┐     ┌──────────┐    ┌─────────────┐      │
│ │ Local   │     │  Image   │    │  App Data   │      │
│ │  LLM    │     │ Processor│    │  Repository │      │
│ │(Gemma3) │     │  (OCR)   │    │  (Read-only)│      │
│ └─────────┘     └──────────┘    └─────────────┘      │
│      │                 │                 │             │
│      │                 │                 │             │
│      ▼                 ▼                 ▼             │
│ ┌─────────┐     ┌──────────┐    ┌─────────────┐      │
│ │  Model  │     │  MediaPipe│    │  Supabase   │      │
│ │  Cache  │     │  Vision  │    │  (Read-only)│      │
│ └─────────┘     └──────────┘    └─────────────┘      │
└─────────────────────────────────────────────────────────┘
```

### 5.2 Data Flow

**Text Query Flow**:
```
User types/speaks → AI Chat Screen → AI Assistant Service
→ Context Builder (loads app data) → Local LLM (Gemma 3)
→ Response → Display to User → TTS (if enabled)
```

**Image Query Flow**:
```
User uploads image → Image Upload UI → Image Processor (OCR)
→ Extracted text + metadata → AI Assistant Service
→ Context Builder → Local LLM (Gemma 3n with vision)
→ Analysis + suggestions → Display to User
```

**App Data Access (Read-Only)**:
```
AI needs trip status → Repository (read-only query) → Supabase
→ Returns trip data → AI Assistant Service → Context Builder
→ LLM analyzes → Response to user
```

### 5.3 File Structure

```
lib/src/features/ai_assistant/
├── data/
│   ├── ai_assistant_service.dart         # Main service orchestrating LLM + data
│   ├── model_loader.dart                  # Gemma model download/management
│   ├── context_builder.dart               # Builds context from app data
│   └── image_processor.dart              # OCR/vision processing
├── domain/
│   ├── ai_message.dart                    # Chat message models
│   ├── ai_session_state.dart              # Conversation state
│   └── ai_capability.dart                 # Enum of supported capabilities
├── presentation/
│   ├── ai_chat_screen.dart                # Main chat UI
│   ├── widgets/
│   │   ├── ai_message_bubble.dart          # Message bubbles
│   │   ├── ai_input_bar.dart              # Text + image input
│   │   ├── image_upload_button.dart       # Camera/gallery picker
│   │   └── capability_quick_actions.dart  # Common action chips
│   └── providers/
│       └── ai_assistant_provider.dart     # State management
```

---

## 6. IMPLEMENTATION PHASES

### Phase A: Foundation (Week 1)

**Goal**: Local LLM integration and basic chat

**Tasks**:
1. **A1**: Add `flutter_gemma` dependency
2. **A2**: Set up model download/management
   - Download Gemma 3 1B int4 model from HuggingFace
   - Cache model locally
   - Show download progress
   - Handle download failures
3. **A3**: Create basic chat UI
   - Message bubbles (user/AI)
   - Text input field
   - Simple prompt-response loop
4. **A4**: Test on target device (4GB RAM Android)
5. **A5**: Measure inference speed (tokens/sec)

**Deliverable**: Basic LLM chat working offline on device

### Phase B: Read-Only Data Integration (Week 2)

**Goal**: AI can read and explain app data

**Tasks**:
1. **B1**: Create read-only repository queries
   - `getActiveTrips()`
   - `getTripStatus(tripId)`
   - `getPaymentStatus(userId)`
   - `getVerificationStatus(userId)`
   - `getUserProfile(userId)`
2. **B2**: Create context builder
   - Inject relevant app data into LLM prompt
   - Format data as natural language summary
   - Handle missing data gracefully
3. **B3**: Implement app data use cases
   - Trip status query
   - Payment status query
   - Verification status query
   - Load listing (read-only)
4. **B4**: Add system prompt with read-only constraints
   - "You are a helpful assistant for truckers. You can READ app data but cannot WRITE or modify anything."

**Deliverable**: AI can answer questions about user's trips, payments, verification

### Phase C: Image Processing Add-On (Week 3)

**Goal**: AI can analyze images (bilty, receipts, documents)

**Tasks**:
1. **C1**: Add image upload UI (camera/gallery)
2. **C2**: Integrate OCR (MediaPipe Vision or Gemma3n)
   - Extract text from images
   - Detect document structure (bilty, receipt, etc.)
   - Extract structured data (addresses, numbers, dates)
3. **C3**: Implement bilty analysis
   - Extract origin, destination, material, weight
   - Explain in natural language
   - Suggest route with distance/time
4. **C4**: Implement receipt analysis
   - Extract fuel amount, price, total
   - Calculate cost per liter
5. **C5**: Test on real bilty/receipt images

**Deliverable**: AI can analyze bilty and receipt images, provide insights

### Phase D: Navigation & Calculations (Week 4)

**Goal**: AI provides practical routing and cost calculations

**Tasks**:
1. **D1**: Integrate offline routing data
   - Use existing `indian_cities.json` for distances
   - Calculate straight-line distance
   - Estimate highway distance (multiplier: 1.3x)
2. **D2**: Implement cost calculation logic
   - Fuel cost: distance × fuel_rate × price_per_liter
   - Toll estimation: based on route length (₹1-2/km)
   - Driver cost: per-day rate
3. **D3**: Implement route suggestions
   - Compare multiple route options
   - Provide Google Maps link
   - Suggest best route based on time/cost
4. **D4**: Add Hindi/English bilingual support
   - Detect user language from input
   - Respond in same language
   - Support mixed language queries

**Deliverable**: AI provides route suggestions, cost calculations, bilingual support

### Phase E: Polish & Optimization (Week 5)

**Goal**: Production-ready, fast, reliable

**Tasks**:
1. **E1**: Performance optimization
   - Reduce prompt size (truncate context)
   - Cache frequent queries
   - Use GPU acceleration if available
2. **E2**: Error handling
   - Model download failures
   - OCR failures
   - Network errors (for map links)
   - Out-of-memory situations
3. **E3**: UI polish
   - Loading states
   - Error messages in Hindi/English
   - Offline indicator
   - Model version display
4. **E4**: Testing
   - Unit tests for calculations
   - Integration tests for data access
   - Manual testing on target devices
5. **E5**: Documentation
   - User guide (Hindi/English)
   - FAQ
   - Troubleshooting

**Deliverable**: Production-ready AI assistant

---

## 7. MODEL SELECTION DECISION

### 7.1 Gemma 3 1B vs Gemma 3 270M

| Factor | Gemma 3 1B | Gemma 3 270M |
|--------|------------|--------------|
| Model Size | 529MB | ~200MB |
| RAM Required | 4GB | 2GB |
| Reasoning Quality | Good | Limited |
| Speed | 2,585 tok/sec | Faster |
| Multimodal | Gemma3n available | Limited |
| Recommendation | **Production** | Fallback for low-end devices |

### 7.2 Gemma 3 vs Gemma 4

| Factor | Gemma 3 | Gemma 4 |
|--------|---------|---------|
| Availability | Stable, documented | New (April 2026) |
| Mobile Support | Proven on 4GB RAM | TBD for smaller models |
| Multimodal | Gemma3n (good OCR) | Native (better OCR) |
| Flutter Plugin | flutter_gemma mature | May need update |
| Recommendation | **Start with Gemma 3** | Evaluate later |

**Decision**: Use **Gemma 3 1B int4** for V1 production. Evaluate Gemma 4 smaller variants when mobile support is confirmed.

---

## 8. IMAGE PROCESSING STRATEGY

### 8.1 OCR Options

**Option A: Gemma3n (Multimodal)**
- Integrated with LLM
- Single model for text + vision
- Good for document understanding
- Larger model size (2B+)

**Option B: MediaPipe Vision (Separate)**
- Lightweight OCR model
- Faster inference
- Separate from LLM (need to pass extracted text)
- Better for low-end devices

**Option C: Tesseract (Traditional)**
- Open-source OCR
- No AI model needed
- Good for printed text
- Poor for handwriting/damaged docs

**Recommendation**: Start with **MediaPipe Vision** for OCR (faster, lighter). Pass extracted text to Gemma 3 LLM for analysis. Evaluate Gemma3n if better document understanding is needed.

### 8.2 Bilty Analysis Workflow

```
User uploads bilty image
→ Image preprocessing (enhance contrast, deskew)
→ OCR (MediaPipe Vision) → extract all text
→ Text parsing → identify fields (origin, destination, weight, etc.)
→ Pass to LLM with context: "Analyze this bilty: {extracted_text}"
→ LLM responds with structured explanation
→ Calculate route distance from city database
→ Provide Google Maps link
```

### 8.3 Performance Considerations

- Image preprocessing: ~500ms
- OCR inference: ~1-2s
- LLM analysis: ~1-2s
- Total: ~3-5s per image
- Acceptable for occasional use, not real-time

---

## 9. SYSTEM PROMPT DESIGN

### 9.1 Base System Prompt (English)

```
You are a helpful AI assistant for Indian truckers using the TranZfort app.

Your capabilities:
- Answer questions about trips, loads, payments, and verification
- Analyze images (bilty, receipts, documents) and extract information
- Provide route suggestions and cost calculations
- Translate between Hindi and English
- Help with daily trucker tasks

Your constraints:
- You can READ app data but cannot WRITE or modify anything
- You cannot post loads, accept bookings, or update trip status
- You cannot make decisions on behalf of the user
- If you don't have real-time data (weather, traffic), say so clearly
- Keep responses concise and practical

Language:
- Respond in the same language the user uses (Hindi or English)
- Support mixed language (Hinglish)
- Be culturally appropriate for Indian truckers

Tone:
- Friendly, respectful, practical
- Use simple language
- Avoid jargon
- Focus on actionable advice
```

### 9.2 Hindi System Prompt

```
आप भारतीय ट्रक ड्राइवरों के लिए एक मददगार AI सहायक हैं जो TranZfort ऐप का उपयोग करते हैं।

आपकी क्षमताएं:
- ट्रिप, लोड, भुगतान और सत्यापन के बारे में सवालों के जवाब दें
- चित्रों (बिल्टी, रसीद, दस्तावेज) का विश्लेषण करें और जानकारी निकालें
- मार्ग के सुझाव और लागत की गणना प्रदान करें
- हिंदी और अंग्रेजी के बीच अनुवाद करें
- दैनिक ट्रकर कार्यों में मदद करें

आपकी बाधाएं:
- आप ऐप डेटा को पढ़ सकते हैं लेकिन लिख या संशोधित नहीं कर सकते
- आप लोड पोस्ट नहीं कर सकते, बुकिंग स्वीकार नहीं कर सकते या ट्रिप स्थिति अपडेट नहीं कर सकते
- आप उपयोगकर्ता की ओर से निर्णय नहीं ले सकते
- यदि आपके पास रीयल-टाइम डेटा नहीं है (मौसम, ट्रैफिक), तो स्पष्ट रूप से कहें
- प्रतिक्रियाओं को संक्षिप्त और व्यावहारिक रखें

भाषा:
- उसी भाषा में जवाब दें जिसमें उपयोगकर्ता कहता है (हिंदी या अंग्रेजी)
- मिश्रित भाषा (हिंग्लिश) का समर्थन करें
- भारतीय ट्रकरों के लिए सांस्कृतिक रूप से उपयुक्त रहें

स्वर:
- मित्रवत, सम्मानजनक, व्यावहारिक
- सरल भाषा का उपयोग करें
- जार्गन से बचें
- कार्यवाही योग्य सलाह पर ध्यान केंद्रित करें
```

---

## 10. CONTEXT BUILDING STRATEGY

### 10.1 What Data to Inject

Based on user query, inject relevant app data:

| Query Type | Data to Inject |
|------------|----------------|
| "What's my trip status?" | Active trips (origin, destination, status, scheduled time) |
| "Did I get paid?" | Recent completed trips, payment status, settlement dates |
| "Is my verification done?" | Verification status, approved documents, date |
| "How many loads posted?" | Posted loads count, active loads, recent loads |
| "Route from X to Y?" | City coordinates from database, straight-line distance |

### 10.2 Data Formatting

Convert structured data to natural language:

**Before (JSON)**:
```json
{
  "trips": [
    {
      "id": "trip-123",
      "origin": "Chandrapur",
      "destination": "Mumbai",
      "status": "pickup_pending",
      "scheduled_pickup": "2026-04-23T09:00:00Z"
    }
  ]
}
```

**After (Natural Language)**:
```
You have 1 active trip:
- Trip from Chandrapur to Mumbai
- Status: pickup_pending
- Scheduled pickup: Tomorrow at 9 AM
```

### 10.3 Context Window Management

- Gemma 3 1B context: 2,048 tokens
- System prompt: ~200 tokens
- User query: ~50 tokens
- Available for app data: ~1,800 tokens
- Limit injected data to top 3-5 most relevant items
- Truncate long lists (show "5 more trips..." instead of all)

---

## 11. OFFLINE MAP INTEGRATION

### 11.1 Options

**Option A: Google Maps (Online)**
- Best routing, real-time traffic
- Requires internet
- AI provides link, user opens in Google Maps app

**Option B: Offline Map Library**
- Use Flutter map library (flutter_map) with offline tiles
- Download map tiles for India (large storage requirement)
- Basic routing (no traffic)
- Fully offline

**Option C: Hybrid**
- AI provides Google Maps link (requires internet)
- Also shows straight-line distance and estimated time
- Fallback to offline calculation if no internet

**Recommendation**: **Option C (Hybrid)**. Provide Google Maps link as primary, show basic offline calculation as backup.

### 11.2 Distance Calculation (Offline)

```
Given: origin_city, destination_city

1. Lookup coordinates from indian_cities.json
   - origin_lat, origin_lng
   - dest_lat, dest_lng

2. Calculate straight-line distance (Haversine formula):
   distance_km = 6371 × acos(
     sin(lat1) × sin(lat2) +
     cos(lat1) × cos(lat2) × cos(lon2 - lon1)
   )

3. Estimate highway distance (multiplier):
   highway_distance = straight_distance × 1.3

4. Estimate time (average speed 40 km/h for trucks):
   time_hours = highway_distance / 40

5. Format response:
   "Distance: {highway_distance}km. Estimated time: {time_hours} hours."
```

---

## 12. SPEED OPTIMIZATION STRATEGIES

### 12.1 Model-Level Optimizations

- Use **int4 quantization** (already in Gemma 3 1B int4)
- Enable **GPU acceleration** if device supports it
- Use **CPU fallback** if GPU not available
- Cache **KV cache** (shared across layers)

### 12.2 Prompt-Level Optimizations

- Keep system prompt concise (<200 tokens)
- Limit injected context to essential data only
- Use short, direct questions from user
- Truncate long responses at 500 tokens

### 12.3 Response-Level Optimizations

- Stream responses (show tokens as they generate)
- Stop generation early if answer is complete
- Cache frequent queries (e.g., "What's my trip status?")
- Pre-compute common calculations (distances, costs)

### 12.4 Hardware-Level Optimizations

- Offer "Lite mode" with smaller model (Gemma 3 270M)
- Allow user to choose CPU vs GPU (GPU = faster, more battery)
- Show model inference time to user
- Warn if device is underpowered

---

## 13. ERROR HANDLING STRATEGY

### 13.1 Model Download Failures

**Scenario**: User has poor internet, model download fails

**Handling**:
- Show download progress with pause/resume
- Retry automatically 3 times
- If all retries fail: "Model download failed. Connect to WiFi and try again."
- Offer "Lite mode" with smaller model (200MB instead of 529MB)
- Cache partial download for resume

### 13.2 OCR Failures

**Scenario**: Image is blurry, OCR cannot extract text

**Handling**:
- Show: "I couldn't read this image clearly. Try taking a better photo."
- Suggest: "Ensure good lighting, hold camera steady, avoid glare."
- Allow user to re-upload
- Fallback: Ask user to type the information manually

### 13.3 Out of Memory

**Scenario**: Device runs out of RAM during inference

**Handling**:
- Detect OOM error from plugin
- Show: "Not enough memory. Try closing other apps."
- Offer: "Switch to Lite mode (smaller model)"
- Kill AI process gracefully
- Auto-restart with smaller model if user agrees

### 13.4 Network Errors (Map Links)

**Scenario**: Google Maps link fails to open (no internet)

**Handling**:
- Show: "Google Maps requires internet. Here's the offline estimate:"
- Display basic distance/time calculation
- Provide: "Open in Google Maps" button (disabled if offline)

### 13.5 Data Access Errors

**Scenario**: App data query fails (Supabase offline)

**Handling**:
- Show: "I can't access your trip data right now (offline)."
- Provide: "Check your internet connection and try again."
- Cache last known data locally for offline access

---

## 14. USER EXPERIENCE DESIGN

### 14.1 Onboarding Flow

**First-time AI Assistant Access**:

1. **Welcome Screen**:
   - "Meet your AI Assistant"
   - "I can help you with trips, routes, documents, and more"
   - "Works 100% offline after initial download"
   - Button: "Get Started"

2. **Model Download Screen**:
   - "Downloading AI model (529MB)"
   - Progress bar (0-100%)
   - "This happens once. Model stays on your phone."
   - "Requires WiFi for faster download"
   - Option: "Download via mobile data" (with warning)

3. **Download Complete**:
   - "AI Assistant ready!"
   - "Try asking: 'What's my trip status?'"
   - Button: "Start Chatting"

4. **Optional: Lite Mode Prompt**:
   - If device has <4GB RAM: "Your device may struggle with the full model."
   - Option: "Use Lite mode (faster, less accurate)" or "Try full model"

### 14.2 Chat Interface

**Screen Layout**:
```
┌────────────────────────────────────────┐
│ [←] AI Assistant              [Settings]│
├────────────────────────────────────────┤
│ ┌─── AI ──────────────────────────┐  │
│ │ 🤖 Namaste! Main aapka AI       │  │
│ │ assistant hoon. Aap mujhse       │  │
│ │ trip status, route, documents   │  │
│ │ ke baare mein pooch sakte hain.  │  │
│ │ 100% offline kaam karta hoon.   │  │
│ │ 10:00 AM                         │  │
│ └──────────────────────────────────┘  │
│                                        │
│ [You] Mera trip status kya hai?       │
│ 10:01 AM                               │
│                                        │
│ ┌─── AI ──────────────────────────┐  │
│ │ 🤖 Aapke 1 active trips hain:   │  │
│ │ • Chandrapur se Mumbai, Coal     │  │
│ │   Status: pickup_pending         │  │
│ │   Pickup: kal 9 baje             │  │
│ │ 10:01 AM                         │  │
│ └──────────────────────────────────┘  │
│                                        │
│ [You] [📷 Upload bilty]              │
│ [🎤 Speak] [Type _______________]     │
└────────────────────────────────────────┘
```

**Key Elements**:
- AI avatar (🤖 icon)
- User messages (right-aligned, brand color)
- AI messages (left-aligned, light surface)
- Image upload button (📷)
- Voice input button (🎤) - reuses existing STT
- Text input field
- Settings button (model info, language, TTS toggle)

### 14.3 Quick Actions

**Suggested Prompts** (chips above input):
- "What's my trip status?"
- "Check this bilty" [📷]
- "Route from X to Y"
- "Fuel cost calculator"
- "Translate to Hindi"

### 14.4 Settings Screen

**Options**:
- Model: Gemma 3 1B (529MB) / Gemma 3 270M (Lite)
- Backend: Auto / CPU / GPU
- Language: Auto / Hindi / English
- TTS: On / Off
- Clear conversation history
- Re-download model
- About AI Assistant

---

## 15. TESTING STRATEGY

### 15.1 Unit Tests

- Distance calculation (Haversine formula)
- Cost calculation formulas
- Context builder (data formatting)
- System prompt injection
- Language detection

### 15.2 Integration Tests

- LLM inference with model
- OCR with sample images
- App data repository queries (read-only)
- Image upload flow
- Model download flow

### 15.3 Manual Testing on Target Devices

**Device 1**: Budget Android (4GB RAM, ₹12k phone)
- Model download speed
- Inference speed (tokens/sec)
- Memory usage
- Battery drain
- OCR accuracy

**Device 2**: Mid-range Android (6GB RAM, ₹20k phone)
- Same tests as Device 1
- Compare performance

**Device 3**: Low-end Android (3GB RAM, older phone)
- Test Lite mode (Gemma 3 270M)
- Verify fallback behavior

### 15.4 Use Case Testing

**Test Cases**:
1. Ask trip status (Hindi and English)
2. Upload bilty image, extract info
3. Upload fuel receipt, calculate cost
4. Ask for route from Nagpur to Hyderabad
5. Calculate fuel cost for 800km
6. Translate sentence Hindi ↔ English
7. Ask about verification status
8. Ask about payment status
9. General knowledge question (weather, maintenance)
10. Test offline mode (airplane mode)

---

## 16. RISK ASSESSMENT

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Model download too large for budget phones | High | Medium | Offer Lite mode (200MB), WiFi requirement |
| Inference too slow on low-end devices | Medium | High | CPU/GPU choice, Lite mode, streaming responses |
| OCR accuracy poor on blurry/damaged bilties | Medium | Medium | Image preprocessing tips, manual fallback |
| Device runs out of RAM during inference | Medium | High | Detect OOM, auto-switch to Lite mode |
| Model hallucinates incorrect information | Low | High | System prompt constraints, read-only data only |
| User expects AI to do write operations | Medium | Medium | Clear onboarding, system prompt constraints |
| Battery drain from AI usage | Medium | Low | GPU toggle, warn user, optimize inference |
| Hindi language support weak | Low | Medium | Fine-tune on Hindi data, bilingual prompt |

---

## 17. SUCCESS CRITERIA

**Minimum Viable AI Assistant (V1 Launch)**:
- ✅ Local LLM (Gemma 3 1B) working offline on 4GB RAM device
- ✅ Basic chat UI with text input
- ✅ Can read and explain app data (trips, payments, verification)
- ✅ Image upload + OCR for bilty analysis
- ✅ Route suggestions with distance/time calculations
- ✅ Hindi/English bilingual support
- ✅ Read-only only (no write operations)
- ✅ Works 100% offline after model download
- ✅ Inference speed <3 seconds for typical queries
- ✅ Model download <5 minutes on WiFi
- ✅ No crashes or ANRs on target devices

**Nice to Have (Post-Launch)**:
- 🟡 Voice input (reuse existing STT)
- 🟡 Voice output (reuse existing TTS)
- 🟡 Gemma 4 integration (better OCR)
- 🟡 Offline map tiles (fully offline routing)
- 🟡 Fine-tuned model for trucker domain
- 🟡 Conversation history persistence
- 🟡 Analytics on AI usage patterns

---

## 18. ESTIMATED EFFORT

| Phase | Duration | Developer Focus |
|-------|----------|-----------------|
| A: Foundation | 5 days | Model integration, basic chat UI |
| B: Read-Only Data | 5 days | Repository queries, context builder |
| C: Image Processing | 5 days | OCR integration, bilty analysis |
| D: Navigation & Calc | 4 days | Distance calc, routing, bilingual |
| E: Polish & Optimize | 4 days | Performance, error handling, testing |
| **Total** | **23 days** | **~4-5 weeks for one developer** |

**Parallelizable**: Phases B, C, D can be partially parallel (different features)

---

## 19. RECOMMENDATION

**Build the local LLM AI assistant with read-only access.**

**Key Benefits**:
1. **Offline capability** - Works without internet, critical for truckers in remote areas
2. **No write operations** - Avoids shadow workflow risk, simpler maintenance
3. **General-purpose** - Helps with daily tasks, not just app-specific flows
4. **Future-proof** - Local LLMs are improving rapidly (Gemma 4, etc.)
5. **Differentiation** - Few logistics apps have local AI assistants

**Next Steps**:
1. Start with Phase A (Gemma 3 1B integration) - prove technical feasibility
2. Test on target budget device (₹12k Android with 4GB RAM)
3. If performance acceptable, proceed to Phase B (read-only data integration)
4. If performance poor, evaluate Gemma 3 270M (Lite mode)

**Critical Success Factor**: Performance on budget Android phones. If inference is too slow (>5 seconds) or OOM errors are frequent, the feature may not be viable for the target user base.

---

*End of AI Assistant - Revised Brainstorm*
*Last Updated: April 22, 2026*
