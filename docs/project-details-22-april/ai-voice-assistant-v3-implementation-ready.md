---
title: Nancy AI Assistant V3 - Implementation-Ready Plan
date: April 22, 2026
version: 3.2
purpose: Grounded in existing codebase audit. Voice-first AI for truckers with on-demand model download, camera integration, guard rails, temporary storage, Nancy bot branding, and comprehensive image usage strategy.
branch: feature/nancy-ai-assistant
status: DEFERRED

# Nancy AI Assistant V3 — Implementation-Ready Plan

> **⚠️ STATUS: DEFERRED (April 22, 2026)**
>
> This AI assistant feature was implemented but **not released** due to inference time and quality not meeting expectations.
>
> **Decision:** Complete rollback of AI integration from production codebase.
> **Reason:** On-device AI inference (flutter_gemma) produced slow responses and repetitive, low-quality answers that did not meet user experience standards.
> **Future Plan:** AI assistant will be revisited in a future version with a different approach (potentially cloud-based AI or improved on-device models).
>
> **What Was Removed:**
> - AI assistant code (Nancy bot)
> - AI inference service (flutter_gemma integration)
> - Model storage manager and download functionality
> - AI-related dependencies (flutter_gemma, AI-specific TTS/STT)
> - AI model files and assets
> - AI settings UI and configuration
>
> **What Was Retained:**
> - Accessibility TTS service (for reading summaries, not AI voice chat)
> - TTS action button (for accessibility)
> - General STT service (for non-AI use cases)
>
> **Documentation Purpose:** This file is retained for reference when AI integration is revisited in the future.

> **Principle**: Zero risk to existing app. New git branch `feature/nancy-ai-assistant`.
> All AI code lives in an isolated `lib/src/features/ai_assistant/` module.
> No existing file is modified until Phase E (entry points), and even then changes are minimal additive-only.

---

## 0. EXISTING CODEBASE AUDIT

### 0.1 What We Already Have (Reusable)

| Capability | Existing File | Provider | Notes |
|-----------|--------------|----------|-------|
| **TTS (Text-to-Speech)** | `core/services/contextual_tts_service.dart` | `contextualTtsServiceProvider` | Uses `flutter_tts`. Supports hi-IN/en-IN. Sanitizes emoji, truncates to 500 chars. Mute toggle via `tts_muted` SharedPreferences key. |
| **TTS State** | `core/providers/tts_state_provider.dart` | `ttsSpeakingProvider`, `ttsMutedProvider`, `ttsPlaybackControllerProvider` | Full playback controller with play/stop. Speaking state tracked globally. |
| **TTS Settings** | `core/providers/tts_settings_provider.dart` | `ttsSettingsProvider` | Speech rate (0.0-1.0, default 0.5), language mode (auto/hi/en). Persisted in SharedPreferences. |
| **STT (Speech-to-Text)** | `core/services/stt_service.dart` | `sttServiceProvider` | Uses `speech_to_text`. Hindi (hi_IN) and English (en_IN). Partial results, 15s silence timeout, 1 min listen window. Permission handling. |
| **Image Picker** | `core/services/image_upload_service.dart` | N/A (static workflow) | `ImageUploadWorkflow.pickCompressAndUpload()`. Pick from camera/gallery, compress to 1200px JPEG@85%. |
| **Image Source Picker UI** | `verification/presentation/components/document_upload_box.dart` | N/A | `ImageSourcePicker` widget — Camera/Gallery bottom sheet. |
| **Camera Permissions** | `verification/data/verification_document_upload_service.dart` | N/A | `_ensureImageAccessPermission()` — handles camera + gallery permissions with proper denied/restricted states. |
| **Trip Costing** | `trucker/data/trip_costing_service.dart` | `tripCostingServiceProvider` | Diesel ₹90/L, mileage 2.5 km/L, toll ₹11/km, driver ₹5/km, misc ₹2/km. Dynamic mileage based on load weight. |
| **Google Places API** | `supplier/data/supplier_location_services.dart` | `supplierLocationServiceProvider` | City autocomplete, place details (lat/lng), route preview via `RouteSnapshotService`. |
| **Offline City Search** | `trucker/data/trucker_city_search_service.dart` | `truckerCitySearchServiceProvider` | Falls back to `indian_cities.json` asset when Google API unavailable. |
| **Maps Launcher** | `core/services/maps_launcher_service.dart` | `mapsLauncherServiceProvider` | Opens Google Maps directions via deep link. |
| **Route Snapshot** | `core/services/route_snapshot_service.dart` | N/A | `RouteSnapshot` model: distanceKm, durationMinutes, source, polyline. |
| **App Shell + Bottom Nav** | `features/shell/presentation/user_app_shell.dart` | N/A | `UserAppShell` with `NavigationBar`. Role-based tabs (trucker: Home, Find, Messages, Trips; supplier: Home, Loads, Messages, Trips). |
| **App Routes** | `core/navigation/app_routes.dart` | N/A | GoRouter with `ShellRoute`. All paths defined centrally. |
| **Connectivity** | `connectivity_plus` package | N/A | Already in pubspec for offline detection. |

### 0.2 Current Bottom Nav Tabs (Trucker)

```
[Home] [Find Loads] [Messages] [Trips]
  │         │            │         │
  ├─ trucker-dashboard   │         ├─ trips
  ├─ trucker-verification│         ├─ trip-detail
  ├─ verification        │         └─ raise-dispute
  └─ fleet               │
                         ├─ find-loads
                         ├─ load-detail
                         └─ route-preview
```

### 0.3 Packages Already in pubspec.yaml

```yaml
flutter_tts: ^4.2.0          # TTS ✅
speech_to_text: ^7.0.0       # STT ✅
just_audio: ^0.9.43          # Audio playback ✅
record: ^5.2.1               # Audio recording ✅
image_picker: ^1.1.2         # Camera/Gallery ✅
image: ^4.5.3                # Image compression ✅
permission_handler: ^11.4.0  # Permissions ✅
geolocator: ^13.0.2          # GPS location ✅
connectivity_plus: ^7.0.0    # Network status ✅
flutter_map: ^7.0.2          # Map rendering ✅
latlong2: ^0.9.1             # Coordinates ✅
shared_preferences: ^2.5.3   # Local prefs ✅
```

### 0.4 New Packages Needed

```yaml
# --- AI / LLM ---
google_generative_ai: ^0.4.0   # Gemini Nano / Gemma via Google AI SDK
# OR
flutter_gemma: ^0.4.0          # Direct Gemma model inference on-device

# --- Utilities ---
path_provider: ^2.1.0          # Already implicitly available, but needed for model storage
dio: ^5.4.0                    # Robust HTTP for model download with resume
crypto: ^3.0.0                 # SHA256 checksum for model verification
```

### 0.5 Nancy Bot Asset

**File:** `assets/images/nancy-bot.png`
- **Status:** ✅ Already exists in TranZfort/assets/images/
- **Description:** Humanoid robot, head-to-chest portrait with TranZfort logo on chest
- **Format:** Transparent PNG
- **Usage:** FAB background, chat screen avatar, download prompt illustration
- **No action needed:** Asset is already in the correct location for Flutter asset loading

---

## 1. LLM MODEL DECISION

### 1.1 Model Comparison

| Model | Size | RAM | Flutter Support | Offline | Vision | Hindi | Use Case |
|-------|------|-----|-----------------|---------|--------|-------|----------|
| **Gemma 3n (E2B)** | 2.92 GB | 2GB+ | `flutter_gemma` | ✅ Full | ✅ Yes | ✅ Excellent (140+ languages) | Main model for high-spec phones |
| **FastVLM 0.5B** | 1.08 GB | 1GB+ | `flutter_gemma` | ✅ Full | ✅ Yes (specialized) | ⚠️ Need to test | Fallback for low-spec phones |
| Gemma 3 1B | 529MB | 4GB+ | `flutter_gemma` | ✅ Full | ✅ Yes | ✅ Good | Alternative if FastVLM Hindi is weak |
| Gemini Nano (on-device) | Built-in | — | `google_generative_ai` | ✅ | ❌ No | ✅ | Not suitable (no vision) |
| Phi-3 Mini | 2.3GB | 4GB+ | ONNX Runtime | ✅ | ❌ No | ⚠️ Weak | Not suitable (no vision, Hindi weak) |

### 1.2 Final Decision: Dual-Model Approach

**Why Dual-Model Strategy:**
- **Gemma 3n E2B (Main)**: Best Hindi, best vision, official Google model
  - 2.92 GB size (actual downloaded)
  - Requires 4GB+ RAM and 4GB free storage
  - Supports 140+ languages including Hindi/Hinglish
  - Multimodal: text, image, video, audio
  - Used for high-spec phones (4GB+ RAM)

- **FastVLM 0.5B (Fallback)**: Compact, fast, vision-capable
  - 1.08 GB size (actual downloaded)
  - Requires 1GB+ RAM and 2GB free storage
  - Specialized vision model (85x faster encoding)
  - Used for low-spec phones (<4GB RAM)
  - Hindi support needs verification

**Device Selection Logic:**
```dart
if (totalRAM >= 4GB && freeStorage >= 4GB) {
  downloadModel = Gemma3nE2B;  // Full version
} else {
  downloadModel = FastVLM05B;  // Lite version
}
```

**Manual Override:**
- Low-spec users can manually choose to download full version with warning
- High-spec users can choose lite version to save storage
- User choice respected over auto-selection

### 1.3 Model Hosting Strategy

```
Option A: Host on your Hostinger server (RECOMMENDED)
  Gemma 3n E2B: https://tranzfort.com/ai-models/gemma-3n-E2B-it-int4.task
  FastVLM 0.5B: https://tranzfort.com/ai-models/fastvlm-0.5b.task
  - You already have Hostinger hosting
  - Upload model files to /public/ai-models/
  - Free bandwidth (within hosting plan limits)
  - Full control over versioning

Option B: Direct Hugging Face Download (ALTERNATIVE)
  Gemma 3n E2B: https://huggingface.co/google/gemma-3n-E2B-it-litert-preview/resolve/main/gemma-3n-E2B-it-int4.task
  FastVLM 0.5B: https://huggingface.co/litert-community/FastVLM-0.5B/resolve/main/model.task
  - No hosting cost
  - Hugging Face provides CDN
  - Requires Hugging Face authentication token
  - flutter_gemma handles download automatically with token

Decision: Start with Option A (Hostinger) for reliability, fallback to Option B (Hugging Face) if needed.
```

### 1.4 Device Detection & Model Selection

**Device Spec Service:**
```dart
class DeviceSpecService {
  Future<int> getTotalRAM() async;        // Total RAM in MB
  Future<int> getAvailableStorage() async; // Free storage in MB
  Future<bool> isHighSpecDevice() async {
    final ram = await getTotalRAM();
    final storage = await getAvailableStorage();
    return ram >= 4096 && storage >= 5120; // 4GB RAM, 5GB storage
  }
}
```

**Model Selection Strategy:**
```dart
enum AiModel {
  gemma3nE2B,  // 3.14 GB, high-spec
  fastVLM05B,  // ~500 MB, low-spec
}

class ModelSelectionStrategy {
  Future<AiModel> selectBestModel(DeviceSpecs specs) async {
    if (specs.isHighSpec) {
      return AiModel.gemma3nE2B;
    } else {
      return AiModel.fastVLM05B;
    }
  }

  Future<AiModel> allowManualOverride(DeviceSpecs specs, AiModel userChoice) async {
    // Allow user to override auto-selection with warning
    if (specs.isLowSpec && userChoice == AiModel.gemma3nE2B) {
      // Show warning: "Your phone may struggle with full version"
    }
    return userChoice;
  }
}
```

**Download Prompt UI (Per Model):**
```dart
// Gemma 3n E2B (High-Spec)
title: "Download Nancy AI (Full Version)"
subtitle: "Best Hindi support • Image analysis • 2.92 GB"
warning: "Requires 4GB+ RAM and 4GB free storage"
downloadTime: "20-40 minutes on 4G"

// FastVLM 0.5B (Low-Spec)
title: "Download Nancy AI (Lite Version)"
subtitle: "Fast • Good Hindi • 1.08 GB"
note: "Optimized for your device"
downloadTime: "8-15 minutes on 4G"
```

---

## 2. VOICE-FIRST UI/UX DESIGN

### 2.1 Core Interaction Model

```
PRIMARY INPUT:  🎙️ Voice (hold-to-speak or tap-to-toggle)
SECONDARY INPUT: ⌨️ Text (expandable input bar, collapsed by default)
OUTPUT:         🔊 Voice (TTS) + 📱 Visual card (for data-rich responses)
```

### 2.2 AI Voice Screen — Idle State

```
┌─────────────────────────────────────────┐
│ [←]  Nancy AI Assistant    [⚙️] [🔇]   │  ← AppBar with settings + mute
├─────────────────────────────────────────┤
│                                         │
│                                         │
│         ┌─────────────┐                │
│         │             │                │
│         │             │  ← Nancy bot  │
│         │   🤖 Nancy  │    image       │
│         │   (head to  │    (static)    │
│         │   chest)    │                │
│         │             │                │
│         └─────────────┘                │
│                                         │
│    "Namaste! Bolo, kya madad chahiye?" │  ← Greeting text
│                                         │
│                                         │
│  ┌────────┐ ┌────────┐ ┌────────┐     │
│  │ 🚛     │ │ 📄     │ │ ⛽     │     │  ← Quick action
│  │ Find   │ │ Bilty  │ │ Fuel   │     │    chips
│  │ Loads  │ │ Scan   │ │ Calc   │     │
│  └────────┘ └────────┘ └────────┘     │
│  ┌────────┐ ┌────────┐ ┌────────┐     │
│  │ 🗺️     │ │ 🛞     │ │ 💰     │     │
│  │ Route  │ │ Tyre   │ │ Trip   │     │
│  │ Plan   │ │ Check  │ │ Cost   │     │
│  └────────┘ └────────┘ └────────┘     │
│                                         │
│  ┌─────────────────────────────────┐   │
│  │ [📷] [🎙️  Tap to Speak  ] [⌨️] │   │  ← Input bar
│  └─────────────────────────────────┘   │
│                                         │
└─────────────────────────────────────────┘
```

### 2.3 AI Voice Screen — Listening State

```
┌─────────────────────────────────────────┐
│ [←]  Nancy AI Assistant    [⚙️] [🔇]   │
├─────────────────────────────────────────┤
│                                         │
│         ┌─────────────┐                │
│         │             │  ← Nancy bot   │
│         │   🤖 Nancy  │    image       │
│         │  (head to  │    with        │
│         │   chest)    │    pulsing     │
│         │             │    rings       │
│         │  ○  ○  ○   │    animation   │
│         └─────────────┘                │
│                                         │
│    ▁▃▅▇▇▅▃▁▃▅▇▅▃▁▃▅                   │  ← Realtime
│                                         │    waveform
│    "Chandrapur se Mumbai..."           │  ← Live partial
│                                         │    transcript
│                                         │
│                                         │
│                                         │
│                                         │
│                                         │
│                                         │
│  ┌─────────────────────────────────┐   │
│  │     [🔴  Tap to Stop  ]        │   │  ← Big stop
│  └─────────────────────────────────┘   │    button
│                                         │
└─────────────────────────────────────────┘
```

### 2.4 AI Voice Screen — Processing State

```
┌─────────────────────────────────────────┐
│ [←]  Nancy AI Assistant    [⚙️] [🔇]   │
├─────────────────────────────────────────┤
│                                         │
│         ┌─────────────┐                │
│         │             │  ← Nancy bot   │
│         │   🤖 Nancy  │    image       │
│         │  (head to  │    with        │
│         │   chest)    │    thinking    │
│         │             │    dots        │
│         │             │                │
│         │     ○●○     │    bouncing    │
│         └─────────────┘    animation   │
│                                         │
│    "Soch raha hu..."                   │  ← Hindi text
│    (Thinking...)                       │  ← English fallback
│                                         │
│                                         │
│                                         │
│                                         │
│                                         │
└─────────────────────────────────────────┘
```

### 2.5 AI Voice Screen — Response with Data Card

```
┌─────────────────────────────────────────┐
│ [←]  Nancy AI Assistant    [⚙️] [🔇]   │
├─────────────────────────────────────────┤
│                                         │
│  ┌─ You ────────────────────────────┐  │
│  │ "Chandrapur se Mumbai ka route   │  │  ← User message
│  │  batao"                          │  │    (collapsed)
│  └──────────────────────────────────┘  │
│                                         │
│  ┌─ Nancy ───────────────────────────┐  │
│  │ 🔊 Speaking...                   │  │  ← TTS playing
│  │                                   │  │
│  │ Route: Chandrapur → Mumbai        │  │  ← Visual card
│  │ ┌─────────────────────────────┐  │  │
│  │ │ Via NH6 (Nagpur, Amravati)  │  │  │
│  │ │ Distance: 890 km            │  │  │
│  │ │ Time: ~17.5 hours           │  │  │
│  │ │ Toll: ₹847 (6 plazas)      │  │  │
│  │ │ Fuel: ₹22,500              │  │  │
│  │ │ Total Cost: ₹27,350        │  │  │
│  │ └─────────────────────────────┘  │  │
│  │                                   │  │
│  │ [📍 Open in Maps] [💰 Cost Detail]│  │  ← Action buttons
│  └──────────────────────────────────┘  │
│                                         │
│  ┌─────────────────────────────────┐   │
│  │ [📷] [🎙️  Tap to Speak  ] [⌨️] │   │
│  └─────────────────────────────────┘   │
│                                         │
└─────────────────────────────────────────┘
```

### 2.6 Text Input — Expandable (Collapsed by Default)

```
DEFAULT (Collapsed):
┌─────────────────────────────────┐
│ [📷] [🎙️  Tap to Speak  ] [⌨️] │  ← Tap ⌨️ to expand
└─────────────────────────────────┘

EXPANDED:
┌─────────────────────────────────┐
│ Type your question here...   [↗]│  ← Text field + send
│ [📷] [🎙️] [⌨️ Collapse]        │
└─────────────────────────────────┘
```

---

## 3. TTS/STT STRATEGY

### 3.1 Reuse Existing TTS

**No new TTS model needed.** The existing `ContextualTtsService` using `flutter_tts` is solid:
- On-device TTS engine (Android built-in, no download needed)
- Hindi (hi-IN) and English (en-IN) voice support
- Emoji sanitization, 500-char truncation
- Mute toggle persisted in SharedPreferences
- Speaking state tracked globally

**Enhancement for AI responses:**
- Split long AI responses into paragraphs
- Speak one paragraph at a time
- Allow user to interrupt mid-speech (tap mic to ask follow-up)

```dart
// New: AI-specific TTS wrapper that chunks long responses
class AiTtsController {
  final ContextualTtsService _ttsService;
  final TtsPlaybackController _playbackController;

  /// Speak a long AI response, splitting by paragraphs
  Future<void> speakResponse(String response, {required String languageCode}) async {
    final paragraphs = response.split('\n\n').where((p) => p.trim().isNotEmpty);
    for (final paragraph in paragraphs) {
      if (_cancelled) break;
      await _ttsService.speakSummary(
        languageCode: languageCode,
        message: paragraph.trim(),
      );
    }
  }

  void cancel() {
    _cancelled = true;
    _ttsService.stop();
  }
}
```

### 3.2 Reuse Existing STT

**No new STT model needed.** The existing `SttService` using `speech_to_text` is solid:
- On-device STT engine (Android built-in, works offline)
- Hindi (hi_IN) and English (en_IN) locale support
- Partial results for live transcript
- 15-second silence timeout, 1-minute listen window
- Permission handling (denied/unavailable/busy states)

**Enhancement for AI:**
- Extend listen window for longer questions (e.g., 2 minutes)
- Auto-restart if user pauses briefly then continues
- Show partial transcript in real-time on screen

```dart
// New: AI-specific STT wrapper with extended listening
class AiSttController {
  final SttService _sttService;

  Future<SttStartOutcome> startListening({
    required String languageCode,
    required ValueChanged<String> onPartialResult,
    required ValueChanged<String> onFinalResult,
  }) {
    return _sttService.startListening(
      languageCode: languageCode,
      onPartialResult: onPartialResult,
      onFinalResult: onFinalResult,
    );
  }
}
```

### 3.3 Why Not a Better Voice Model?

| Option | Pros | Cons | Verdict |
|--------|------|------|---------|
| **Android built-in TTS/STT** (current) | 0 bytes download, instant, offline | Voice quality varies by device | ✅ USE THIS |
| Google Cloud Speech API | Best quality | Needs internet, costs money | ❌ Breaks offline |
| Whisper (on-device) | Excellent STT | +500MB download, slow on budget phones | ❌ Too heavy |
| Piper TTS (on-device) | Natural voice | +200MB, complex setup | ⚠️ Future upgrade |
| Coqui TTS | Open source | Deprecated, unstable | ❌ Dead project |

**Decision: Use existing Android TTS/STT.** Zero additional download. Works offline. Good enough for Indian Hindi/English. Can upgrade to Piper TTS in future if users want better voice quality.

### 3.5 Nancy Bot Image Usage Strategy

**Image Asset:** `assets/images/nancy-bot.png`
- **Description:** Humanoid robot, head-to-chest portrait
- **Brand element:** TranZfort logo on chest
- **Style:** Clean, modern, approachable design
- **Background:** Transparent PNG for flexible compositing

#### 3.5.1 Where Nancy Bot Image Appears

| Screen/Component | Usage | Size | Crop/Transform | State Variations |
|------------------|-------|------|----------------|------------------|
| **Floating FAB** (Dashboard) | Circular clipped image as FAB background | 56x56 | CircleClipper | Pulse animation when idle, no badge when model downloaded, red dot badge when model missing |
| **AI Chat Screen - Idle** | Large centered avatar in greeting area | 200x200 | Full image (no crop) | Static, no animation |
| **AI Chat Screen - Listening** | Nancy with pulsing rings around | 200x200 | Full image | Pulsing rings (2-3 concentric circles, fade in/out) |
| **AI Chat Screen - Processing** | Nancy with "thinking" dots animation | 200x200 | Full image | Three dots (○○○) below Nancy, bouncing animation |
| **AI Chat Screen - Responding** | Nancy in message header (small) | 48x48 | CircleClipper | Static, appears as avatar in "Nancy" message card |
| **Model Download Screen** | Nancy in download prompt illustration | 150x150 | Full image | Static, welcoming context |
| **Settings - AI Section** | Small avatar for AI toggle | 32x32 | CircleClipper | Static |

#### 3.5.2 Visual Design Principles

**Voice-First Context:**
Since the AI chat screen is primarily voice-based, the Nancy bot image serves as:
1. **Visual anchor** — Gives a face to the voice, making the interaction more human
2. **State indicator** — Different visual states (idle, listening, processing, responding) provide feedback without requiring user to read text
3. **Brand reinforcement** — Logo on chest reinforces TranZfort identity in every interaction

**Animation Strategy:**
- **Idle:** Gentle breathing animation (scale 1.0 → 1.02 → 1.0, 3s loop) — subtle, not distracting
- **Listening:** Pulsing rings (2-3 concentric circles, expanding outward, opacity fade) — indicates microphone is active
- **Processing:** Bouncing dots below Nancy (○○○ → ○●○ → ○○● → ●○○, 1s loop) — indicates AI is "thinking"
- **Responding:** Static, Nancy appears as avatar in message card — TTS provides audio feedback

**Accessibility:**
- All animations respect user's "Reduce Motion" system setting
- Nancy image has high contrast against app background
- Screen readers announce state changes (e.g., "Nancy is listening", "Nancy is thinking")

#### 3.5.3 Implementation Specs

```dart
// ai_avatar.dart — Nancy bot image widget
class NancyAvatar extends StatelessWidget {
  final NancyState state;
  final double size;

  const NancyAvatar({
    super.key,
    required this.state,
    this.size = 200,
  });

  @override
  Widget build(BuildContext context) {
    final baseImage = Image.asset(
      'assets/images/nancy-bot.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
    );

    return switch (state) {
      NancyState.idle => _buildIdle(baseImage),
      NancyState.listening => _buildListening(baseImage),
      NancyState.processing => _buildProcessing(baseImage),
      NancyState.responding => _buildResponding(baseImage),
    };
  }

  Widget _buildIdle(Widget image) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 1.0, end: 1.02),
      duration: const Duration(seconds: 3),
      curve: Curves.easeInOut,
      builder: (context, scale, child) {
        return Transform.scale(scale: scale, child: child);
      },
      child: image,
    );
  }

  Widget _buildListening(Widget image) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Pulsing rings
        for (int i = 0; i < 3; i++)
          _PulsingRing(delay: i * 300, size: size),
        image,
      ],
    );
  }

  Widget _buildProcessing(Widget image) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        image,
        const SizedBox(height: 16),
        _BouncingDots(),
      ],
    );
  }

  Widget _buildResponding(Widget image) {
    return ClipOval(child: image); // Circle clip for message avatar
  }
}

enum NancyState { idle, listening, processing, responding }
```

#### 3.5.4 Floating Nancy Bot on Dashboard

**Design Rationale:**
The floating Nancy bot on the trucker dashboard serves as:
1. **Always-available entry point** — One tap to access Nancy AI assistant
2. **Brand presence** — Reinforces TranZfort identity with logo on Nancy's chest
3. **Visual cue** — Indicates AI capability is available in the app

**Interaction:**
- **Tap:** Opens Nancy AI assistant screen
- **Long press:** Shows quick action menu (Find Loads, Route Plan, Cost Calc)
- **Badge:** Red dot appears if AI model not downloaded (first-time prompt)

**Position:**
- Bottom-right corner, 16px from right edge, 80px from bottom (above bottom nav)
- Does not overlap with existing dashboard content
- Consistent across all screens where FAB is visible

---

## 4. FLOATING AI BUTTON DESIGN

### 4.1 Placement Rules

| Screen | FAB Visible | Position |
|--------|------------|----------|
| Trucker Dashboard | ✅ Yes | Bottom-right, above bottom nav |
| Find Loads | ✅ Yes | Bottom-right, above bottom nav |
| Messages | ❌ No | Conflicts with chat UI |
| Trips | ✅ Yes | Bottom-right, above bottom nav |
| Trip Detail | ✅ Yes | Bottom-right, above any buttons |
| Load Detail | ✅ Yes | Bottom-right |
| Settings/Profile | ❌ No | Not relevant |
| AI Chat Screen | ❌ No | Already on AI screen |
| Supplier (all) | ❌ No (Phase 1 trucker-only) | Future phase |

### 4.2 Visual Specs

```dart
// ai_floating_button.dart
class AiFloatingButton extends ConsumerWidget {
  // Image: assets/images/nancy-bot.png (head-to-chest humanoid, brand logo on chest)
  // Size: 56x56 (Material FAB standard)
  // Shape: CircleClipper to crop Nancy bot image to circular FAB
  // Elevation: 6.0
  // Animation: Gentle scale pulse (1.0 → 1.05 → 1.0, 2s loop)
  // Badge: Red dot if model not downloaded (first-time prompt)
  // Position: Positioned(bottom: 80, right: 16) inside Stack
}
```

### 4.3 Integration into UserAppShell

**Minimal change to existing file.** Add `AiFloatingButton` as a Stack overlay:

```dart
// In user_app_shell.dart — body property
body: Stack(
  children: [
    widget.child,
    if (topLevel)
      TtsScreenSummaryEffect(
        summary: currentTab.title,
        screenKey: '${widget.role.name}:${currentTab.route}',
      ),
    // NEW: AI floating button (trucker only, feature-flagged)
    if (widget.role == AppUserRole.trucker && aiFeatureEnabled)
      const AiFloatingButton(),
  ],
),
```

This is **3 lines added** to one existing file. That's it.

---

## 5. AI CHAT SCREEN ARCHITECTURE

### 5.1 Screen States

```
AiAssistantScreen
├── ModelNotDownloaded → AiModelDownloadView
│   ├── InitialPrompt (show size, explain, ask permission)
│   ├── Downloading (progress bar, speed, pause/cancel)
│   ├── Error (retry, check storage, check network)
│   └── Complete (auto-transition to chat)
│
├── ModelReady → AiVoiceChatView
│   ├── Idle (greeting, quick actions, input bar)
│   ├── Listening (waveform, partial transcript, stop button)
│   ├── Processing (thinking animation, "Soch raha hu...")
│   ├── Responding (TTS playing, visual card, action buttons)
│   └── Error (retry, explain limitation)
│
└── ModelCorrupted → AiModelRedownloadView
    └── Offer to delete and re-download
```

### 5.2 Conversation Flow (State Machine)

```
     ┌──────────────────────────────────┐
     │             IDLE                  │
     │  (Greeting, quick chips visible) │
     └────────────┬─────────────────────┘
                  │ User taps mic / chip / types
                  ▼
     ┌──────────────────────────────────┐
     │           LISTENING               │
     │  (STT active, waveform,          │
     │   partial transcript)            │
     └────────────┬─────────────────────┘
                  │ Final result received
                  ▼
     ┌──────────────────────────────────┐
     │          PROCESSING               │
     │  (Build context → Gemma 3n       │
     │   inference → Parse response)    │
     └────────────┬─────────────────────┘
                  │ Response ready
                  ▼
     ┌──────────────────────────────────┐
     │          RESPONDING               │
     │  (TTS speaks, visual card shown, │
     │   action buttons appear)         │
     └────────────┬─────────────────────┘
                  │ TTS done / user taps mic
                  ▼
                IDLE (loop)
```

---

## 6. FEATURE SET FOR TRUCKERS

### 6.1 Priority Features (Phase 1-2)

| # | Feature | Voice Command | Uses Existing |
|---|---------|--------------|---------------|
| 1 | **Load Discovery** | "Aas paas load dhoondo" | `get_trucker_loads` RPC, `truckerCitySearchServiceProvider` |
| 2 | **Profit Calculator** | "45,000 mein Mumbai profit?" | `TripCostingService.estimate()` |
| 3 | **Route Planning** | "Chandrapur se Mumbai rasta" | `supplierLocationServiceProvider.fetchRoutePreview()`, Google Maps API, offline cities |
| 4 | **Open in Maps** | "Maps mein kholo" | `MapsLauncherService.launchDirectionsUri()` |
| 5 | **Trip Status** | "Mera trip kya hai?" | Existing trip providers (read-only) |
| 6 | **General Q&A** | "Truck ka insurance kab expire?" | Gemma 3n general knowledge |
| 7 | **Hindi/English Chat** | Automatic detection | Existing TTS/STT locale support |

### 6.2 Camera-Powered Features (Phase 3)

| # | Feature | Voice Trigger | Camera Mode |
|---|---------|--------------|-------------|
| 1 | **Bilty Scan** | "Bilty scan karo" | Document overlay, OCR via Gemma 3n vision |
| 2 | **Receipt Analysis** | "Receipt check karo" | Auto-crop, amount extraction |
| 3 | **Tyre Life Check** | "Tyre kitna chalega?" | Close-up guide, tread analysis |
| 4 | **Cargo Damage** | "Damage photo lo" | Multi-photo, AI assessment |
| 5 | **Vehicle Check** | "Truck ki photo dekho" | General condition report |

### 6.3 Day-to-Day Help (Phase 4)

| # | Feature | Voice Command | Online/Offline |
|---|---------|--------------|----------------|
| 1 | **Nearby Petrol Pump** | "Petrol pump dhoondo" | Online (Google Places) |
| 2 | **Food Stop Finder** | "Khana kahan milega?" | Online (Google Places) |
| 3 | **Emergency Help** | "Mechanic chahiye" | Online + offline contacts |
| 4 | **Break Reminders** | Proactive | Offline (timer-based) |
| 5 | **Weather Check** | "Weather kaisa hai?" | Online only |
| 6 | **General Knowledge** | "Overloading ka fine?" | Offline (Gemma 3n) |

---

## 7. GUARD RAILS — READ-ONLY AI

### 7.1 Architecture Enforcement

The AI module gets its own **read-only data layer** — a thin facade that wraps existing repositories but exposes ONLY read methods:

```dart
// ai_assistant/data/ai_data_reader.dart
class AiDataReader {
  final TruckerMarketplaceRepository _marketplaceRepo;
  final TruckerTripRepository _tripRepo;
  final TripCostingService _costingService;
  final TruckerCitySearchService _citySearch;
  final MapsLauncherService _mapsLauncher;

  // ✅ READ OPERATIONS ONLY
  Future<List<MarketplaceLoad>> getAvailableLoads() { ... }
  Future<TripDetail?> getActiveTrip() { ... }
  TripCostEstimate? estimateCost({...}) { ... }
  Future<List<TruckerCitySuggestion>> searchCities(String query) { ... }
  Uri? buildMapsUri({...}) { ... }

  // ❌ NO WRITE METHODS EXPOSED
  // No postLoad, no acceptBooking, no updateTrip, no sendMessage
}
```

### 7.2 System Prompt (Baked into Every Inference Call)

```
You are Nancy, a helpful voice assistant for Indian truck drivers.
You work inside the TranZfort logistics app.

STRICT RULES:
1. You can ONLY READ and DISPLAY information. NEVER modify data.
2. You CANNOT accept bookings, post loads, update trips, or send messages.
3. If asked to perform a write action, politely explain you cannot, then offer to
   navigate the user to the correct screen.
4. Respond in the same language the user speaks (Hindi, English, or Hinglish).
5. Keep responses SHORT — truckers are driving. Max 3-4 sentences spoken.
6. For data-heavy responses (routes, costs), speak a summary and show details in a card.
7. Always prioritize SAFETY — remind about breaks, speed limits when relevant.
8. You are a companion, not a decision maker. Suggest, don't decide.
```

### 7.3 Blocked Action Responses

```
User: "Booking accept karo"
Nancy: "Sorry bhai, main booking accept nahi kar sakta.
       Ye aapko app mein manually karna padega.
       Booking detail dikhata hu — [Open Booking Screen]"

User: "Load post karo"
Nancy: "Main load post nahi kar sakta.
       Lekin details fill karne mein help karunga.
       Kaunsa material hai? Route kya hai?
       [Open Post Load Screen]"
```

---

## 8. MODEL DOWNLOAD FLOW

### 8.1 First-Time Experience

```
User taps AI button (FAB or bottom nav)
    │
    ├── Check: Does model file exist?
    │   Path: getApplicationDocumentsDirectory()/ai_models/gemma3n.task
    │
    ├── [EXISTS + SIZE OK] → Open AI Chat Screen
    │
    └── [MISSING or PARTIAL] → Show Download Prompt
        │
        ├── "AI Assistant needs a one-time download"
        ├── "Size: ~400 MB"
        ├── "Works offline after download"
        ├── "Your APK stays the same size"
        │
        ├── Check free storage (need 500MB+)
        ├── Check network (WiFi recommended)
        │
        ├── [Download Now (WiFi)] → Start download with progress
        ├── [Use Mobile Data] → Warn about data usage, then download
        └── [Maybe Later] → Close, return to app
```

### 8.2 Download with Resume

```dart
// ai_assistant/data/model_download_service.dart
class ModelDownloadService {
  static const modelUrl = 'https://tranzfort.com/ai-models/gemma3n_e2b.task';
  static const expectedSizeBytes = 400000000; // ~400MB
  static const checksumSha256 = '...'; // Verify integrity

  Future<void> downloadModel({
    required String destinationPath,
    required void Function(double progress, int bytesDownloaded) onProgress,
    required VoidCallback onComplete,
    required void Function(String error) onError,
  }) async {
    // Uses dio for:
    // - Range header support (resume partial downloads)
    // - Progress callback
    // - Cancellation token
    // - Timeout handling
  }

  Future<bool> verifyModel(String path) async {
    // Check file size
    // Compute SHA256 checksum
    // Return true if valid
  }
}
```

---

## 9. TEMPORARY STORAGE — DEVICE-CLEAN DESIGN

### 9.1 Storage Rules

| Data Type | Storage | Lifetime | Cleanup |
|-----------|---------|----------|---------|
| **Gemma 3n model** | `app_flutter/ai_models/` | Persistent (until user deletes) | Manual "Delete AI" button |
| **Model version info** | `ai_models/version.json` | Persistent | With model |
| **Conversation messages** | In-memory `List<AiMessage>` | Session only | Session end |
| **Voice recordings** | In-memory bytes | Single-use | After STT processes |
| **Photo for analysis** | Temp file (auto-deleted) | Single-use | After Gemma processes |
| **Route calculation** | In-memory | Session only | Session end |
| **AI preferences** | SharedPreferences | Persistent (tiny) | With app uninstall |

### 9.2 Session Lifecycle

```dart
// ai_assistant/presentation/providers/ai_session_provider.dart
class AiSessionNotifier extends StateNotifier<AiSessionState> {
  // Session starts when user opens AI screen
  // Session ends when:
  //   - User navigates away (GoRouter pop)
  //   - App goes to background for >5 minutes
  //   - User explicitly taps "End Session"

  @override
  void dispose() {
    // Clear all in-memory conversation data
    // Release STT/TTS resources
    // Delete any temp files (photos being analyzed)
    super.dispose();
  }
}
```

### 9.3 What Is NOT Stored

- ❌ Previous conversation history
- ❌ User voice recordings
- ❌ Photos after analysis
- ❌ AI response cache
- ❌ User behavior patterns
- ❌ Analytics data (no tracking)

---

## 10. FILE STRUCTURE

```
lib/src/features/ai_assistant/
│
├── data/
│   ├── ai_data_reader.dart              # Read-only facade over existing repos
│   ├── ai_inference_service.dart        # Gemma 3n model loading + inference
│   ├── ai_context_builder.dart          # Build prompt context from app data
│   ├── model_download_service.dart      # Download model with progress/resume
│   └── model_storage_manager.dart       # Check/verify/delete model file
│
├── domain/
│   ├── ai_message.dart                  # Chat message model (user/ai/system)
│   ├── ai_session_state.dart            # Session state enum + data
│   ├── ai_command_type.dart             # READ_QUERY, READ_ANALYZE, etc.
│   └── ai_quick_action.dart             # Quick action chip definitions
│
├── presentation/
│   ├── ai_assistant_screen.dart         # Main screen (model check → chat)
│   ├── ai_model_download_view.dart      # Download prompt + progress
│   ├── ai_voice_chat_view.dart          # Voice-first chat UI
│   │
│   ├── widgets/
│   │   ├── ai_floating_button.dart      # Dashboard FAB
│   │   ├── ai_avatar.dart               # Nancy bot image (static, head-to-chest)
│   │   ├── ai_waveform.dart             # Voice input waveform
│   │   ├── ai_message_card.dart         # Chat message bubble
│   │   ├── ai_data_card.dart            # Route/cost/load detail card
│   │   ├── ai_input_bar.dart            # Mic + camera + text input
│   │   ├── ai_quick_chips.dart          # Quick action chips grid
│   │   ├── download_progress_card.dart  # Model download progress UI
│   │   └── ai_camera_overlay.dart       # Camera with document/tyre guide
│   │
│   └── providers/
│       ├── ai_session_provider.dart     # Session state management
│       ├── ai_chat_provider.dart        # Chat messages + inference
│       ├── ai_model_status_provider.dart # Model downloaded/missing/corrupted
│       ├── ai_stt_controller.dart       # STT wrapper for AI
│       ├── ai_tts_controller.dart       # TTS wrapper for AI (paragraph split)
│       └── ai_feature_flag_provider.dart # Feature flag (SharedPreferences)
│
└── ai_assistant_routes.dart             # GoRoute definitions
```

**Note:** Nancy bot image asset `assets/images/nancy-bot.png` is already in the TranZfort project and will be loaded by Flutter's asset system. No additional asset configuration needed.

---

## 11. INTEGRATION POINTS (Minimal Changes to Existing Code)

### 11.1 Files Modified (ONLY these)

| Existing File | Change | Lines Added |
|--------------|--------|-------------|
| `pubspec.yaml` | Add `flutter_gemma`, `dio`, `path_provider` | 3 lines |
| `core/navigation/app_routes.dart` | Add `aiAssistant` path | 2 lines |
| `core/navigation/app_router.dart` | Add GoRoute for `/ai-assistant` | 6 lines |
| `features/shell/presentation/user_app_shell.dart` | Add `AiFloatingButton` in Stack | 3 lines |

**Total: 4 existing files touched. ~14 lines added. Zero lines modified/deleted.**

### 11.2 New Files Created

All new files go in `lib/src/features/ai_assistant/` — completely isolated module.
Estimated: ~20 new files, ~3,000 lines total.

---

## 12. GIT BRANCH STRATEGY

```
main (current stable app)
  │
  └── feature/nancy-ai-assistant (ALL AI work here)
        │
        ├── Phase A: Model infrastructure (download, storage, verification)
        ├── Phase B: AI screen skeleton (model check → download → chat shell)
        ├── Phase C: Voice integration (STT input → TTS output loop)
        ├── Phase D: Gemma 3n inference (model loading, prompt, response)
        ├── Phase E: Entry points (FAB in shell, route in router) ← ONLY phase touching existing files
        ├── Phase F: Camera features (bilty scan, tyre check)
        ├── Phase G: Data features (loads, routes, costs via AiDataReader)
        └── Phase H: Polish (error handling, offline graceful, edge cases)

Merge strategy:
  - Feature flag OFF by default
  - Merge to main only after full testing on device
  - Feature flag ON for beta testers first
  - Gradual rollout to all users
```

---

## 13. FEATURE FLAG

```dart
// Simple SharedPreferences flag (no Firebase Remote Config needed for now)
final aiFeatureEnabledProvider = Provider<bool>((ref) {
  // Phase 1: Hardcoded true during development
  // Phase 2: SharedPreferences toggle in settings
  // Phase 3: Remote config (if/when added)
  return true; // Feature flag
});
```

**Why not Firebase Remote Config?** Your app is distributed via Hostinger APK download, not Play Store. Remote config requires Google Play Services which may not be reliable on all trucker phones. A simple in-app toggle is safer and simpler.

---

## 14. IMPLEMENTATION TIMELINE

| Phase | Duration | Deliverable | Files Touched (Existing) |
|-------|----------|-------------|-------------------------|
| **A** | 2 days | Model download infrastructure | 0 existing files |
| **B** | 2 days | AI screen skeleton + download UI | 0 existing files |
| **C** | 2 days | Voice loop (STT → TTS) | 0 existing files |
| **D** | 3 days | Gemma 3n inference integration | 0 existing files |
| **E** | 1 day | FAB + route in shell | 4 existing files (~14 lines) |
| **F** | 3 days | Camera features (bilty, tyre, receipt) | 0 existing files |
| **G** | 3 days | Data features (loads, routes, costs) | 0 existing files |
| **H** | 2 days | Polish + error handling + testing | 0 existing files |
| **Total** | **18 days** | **Production-ready AI assistant** | **4 files, ~14 lines** |

---

## 15. DEVICE REQUIREMENTS

| Requirement | Minimum | Recommended |
|-------------|---------|-------------|
| Android version | 8.0 (API 26) | 12+ |
| RAM | 3 GB | 4+ GB |
| Free storage | 600 MB (model + buffer) | 1+ GB |
| Internet | Required for first download only | WiFi for download |

### Device Capability Check

```dart
// Before showing AI button, check device
Future<bool> canRunAi() async {
  final info = await DeviceInfoPlugin().androidInfo;
  final totalRam = info.totalMemory ?? 0;
  final freeStorage = await getFreeStorage();

  return totalRam >= 3 * 1024 * 1024 * 1024 && // 3GB RAM minimum
         freeStorage >= 600 * 1024 * 1024;        // 600MB free storage
}
```

---

## 16. RISK ASSESSMENT

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|
| AI breaks existing app | Very Low | High | Isolated module, feature flag, separate branch |
| Model too large for user's phone | Medium | Medium | Check storage before download, explain size |
| Gemma 3n slow on budget phones | Medium | Low | Show "Thinking..." animation, timeout at 30s |
| STT doesn't understand Hindi accent | Low | Medium | Text input fallback always available |
| User downloads model on mobile data | Low | Low | Warn about data usage, suggest WiFi |
| Model file corrupted | Low | Low | SHA256 checksum verification, re-download option |

---

---

## 17. MULTI-MODEL ARCHITECTURE - FUTURE-PROOF DESIGN (UPDATED April 23, 2026)

### 17.1 Architecture Overview

**PRINCIPLE: Zero risk to existing app. User-controlled model selection. Future-proof for additional models.**

```
┌─────────────────────────────────────────────────────────────┐
│                    User Interface Layer                      │
│  - Model Selection Screen (all available models)             │
│  - Download/Manage Models                                    │
│  - Inference Mode Toggle (Placeholder vs Real AI)            │
│  - Active Model Indicator                                    │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                  Model Management Layer                       │
│  - Model Registry (metadata for all available models)        │
│  - Model Storage Manager (download/delete/verify)             │
│  - Model Selection Strategy (recommendations)                │
│  - User Preferences (active model, inference mode)           │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                  Inference Layer                              │
│  - Inference Mode Switcher                                   │
│  - Placeholder Inference Service                            │
│  - Real AI Inference Service (flutter_gemma)                │
│  - Model-specific adapters                                   │
└─────────────────────────────────────────────────────────────┘
```

### 17.2 Model Registry System

```dart
class ModelInfo {
  final String id;
  final String name;
  final String displayName;
  final String description;
  final String fileName;
  final String downloadUrl;
  final int sizeBytes;
  final int minRamGB;
  final List<ModelCapability> capabilities;
  final ModelFormat format;
  final bool isRecommended;
}

enum ModelCapability {
  textGeneration,
  vision,
  audio,
  functionCalling,
  hindiSupport,
}

enum ModelFormat {
  task,      // MediaPipe-optimized
  litertlm,  // LiteRT-LM format
  gguf,      // llama.cpp format (future)
  tflite,    // TensorFlow Lite (future)
}

class ModelRegistry {
  static const List<ModelInfo> availableModels = [
    ModelInfo(
      id: 'gemma_3n_e2b',
      name: 'gemma-3n-E2B-it-int4',
      displayName: 'Gemma 3n (Full)',
      description: 'Best quality, supports Hindi, vision, audio. Requires 4GB+ RAM.',
      fileName: 'gemma-3n-E2B-it-int4.task',
      downloadUrl: 'https://tranzfort.com/ai-models/gemma-3n-E2B-it-int4.task',
      sizeBytes: 2920000000, // 2.92 GB
      minRamGB: 4,
      capabilities: [ModelCapability.textGeneration, ModelCapability.vision, ModelCapability.audio, ModelCapability.hindiSupport],
      format: ModelFormat.task,
      isRecommended: false, // Only for high-end devices
    ),
    ModelInfo(
      id: 'fastvlm_0.5b',
      name: 'fastvlm-0.5b.litertlm',
      displayName: 'FastVLM (Lite)',
      description: 'Fast and efficient, good vision, acceptable Hindi. Requires 1GB+ RAM.',
      fileName: 'fastvlm-0.5b.litertlm',
      downloadUrl: 'https://tranzfort.com/ai-models/fastvlm-0.5b.litertlm',
      sizeBytes: 1080000000, // 1.08 GB
      minRamGB: 1,
      capabilities: [ModelCapability.textGeneration, ModelCapability.vision, ModelCapability.hindiSupport],
      format: ModelFormat.litertlm,
      isRecommended: true, // Good balance
    ),
    // Future models can be added here
    // ModelInfo(id: 'gemma_3_270m', ...),
    // ModelInfo(id: 'smollm_135m', ...),
  ];
}
```

### 17.3 User Preferences System

```dart
class AIUserPreferences {
  // Which model is currently active
  String? activeModelId;

  // Inference mode: placeholder vs real AI
  InferenceMode inferenceMode = InferenceMode.placeholder;

  // Auto-select model based on device specs
  bool autoSelectModel = true;

  // Downloaded models list
  List<String> downloadedModelIds = [];
}

enum InferenceMode {
  placeholder,  // Fast, simulated responses (CURRENT DEFAULT)
  realAI,       // Slower, uses downloaded model
}
```

### 17.4 Dual-Mode Inference Service (SAFE, NON-BREAKING)

```dart
class AiInferenceService {
  final ModelStorageManager _storageManager;
  final AIUserPreferences _preferences;
  RealAIInferenceService? _realAIService;

  Future<String?> runInference(String prompt) async {
    switch (_preferences.inferenceMode) {
      case InferenceMode.placeholder:
        // SAFE: Existing placeholder logic continues to work
        return await _runPlaceholderInference(prompt);

      case InferenceMode.realAI:
        if (_preferences.activeModelId == null) {
          // FALLBACK: No model selected, use placeholder
          return await _runPlaceholderInference(prompt);
        }

        try {
          return await _runRealInference(prompt);
        } catch (e) {
          // SAFE FALLBACK: Real AI failed, use placeholder
          print('Real AI failed, falling back to placeholder: $e');
          return await _runPlaceholderInference(prompt);
        }
    }
  }

  Future<String?> _runRealInference(String prompt) async {
    final modelId = _preferences.activeModelId!;
    final modelInfo = ModelRegistry.getModelById(modelId);
    final modelPath = await _storageManager.getModelFilePath(
      modelFileName: modelInfo.fileName,
    );

    // Initialize real AI service with selected model
    _realAIService ??= RealAIInferenceService();
    await _realAIService!.loadModel(modelPath, modelInfo.format);

    return await _realAIService!.generateResponse(prompt);
  }

  Future<String?> _runPlaceholderInference(String prompt) async {
    // EXISTING: Current placeholder logic (keyword matching)
    // This ensures existing app continues to work
  }
}
```

### 17.5 Implementation Phases (SAFE, NON-BREAKING)

**Phase 1: Core Infrastructure (3-4 hours) - ZERO RISK**
- Create ModelRegistry with current models
- Create AIUserPreferences system
- Update ModelSettingsSheet to show all models
- Add model switching capability
- Add inference mode toggle
- **NO CHANGES to existing inference logic**
- **Placeholder remains default**

**Phase 2: Real AI Integration (2-3 hours) - SAFE WITH FALLBACK**
- Add flutter_gemma dependency
- Implement RealAIInferenceService
- Add fallback mechanism (placeholder on error)
- Test on device with placeholder mode (default)
- Switch to real AI mode and test
- **Placeholder fallback prevents crashes**

**Phase 3: Future Models (As needed)**
- Add new models to registry
- Support additional formats (gguf, tflite)
- Add model updates/versioning
- Add capability-based recommendations

### 17.6 Safety Guarantees

**NON-BREAKING GUARANTEES:**
1. ✅ Placeholder mode remains DEFAULT
2. ✅ Real AI has automatic fallback to placeholder
3. ✅ User can choose which mode to use
4. ✅ Model download is optional (user decision)
5. ✅ Existing app continues to work without any AI models
6. ✅ All changes are additive, no deletions
7. ✅ Feature flag can disable entire AI module
8. ✅ Separate git branch for all AI work

**TESTING STRATEGY:**
1. Test with placeholder mode (default) - ensures existing app works
2. Test with real AI mode - validates new functionality
3. Test fallback mechanism - ensures safety net works
4. Test on target device (8GB RAM Android) - validates performance
5. Monitor for stability issues - catch problems early

### 17.7 Updated Implementation Timeline

| Phase | Duration | Deliverable | Risk Level | Existing App Impact |
|-------|----------|-------------|------------|---------------------|
| **Phase 1** | 3-4 hours | Model registry, preferences, UI | ZERO | NONE - placeholder default |
| **Phase 2** | 2-3 hours | flutter_gemma integration, fallback | LOW | NONE - fallback to placeholder |
| **Phase 3** | As needed | Future models | LOW | NONE - additive only |
| **Total** | **5-7 hours** | **Full multi-model system** | **LOW** | **ZERO IMPACT** |

---

*End of AI Voice Assistant V3 — Implementation-Ready Plan*
*Ready to create branch and start Phase A.*
*Multi-model architecture added April 23, 2026 - Zero risk to existing app.*

---

## 18. APRIL 23 (Evening) — CURRENT STATE vs PLAN (Post-Implementation Audit)

> Companion section to `docs/TODO-22-april.md` §"April 23 (Evening) — Code Review". This section reconciles *what the plan asked for* with *what is actually in the codebase* after Phases A–E + the multi-model retrofit. The intent is to keep this V3 document as the design source of truth while calling out the small set of divergences that are producing the visible bugs.

### 18.1 Plan vs Reality Matrix

| Plan Area | Plan Expectation | Actual in Code | Status |
|-----------|------------------|----------------|--------|
| Module isolation | All AI code in `lib/src/features/ai_assistant/` | Yes | ✅ |
| Existing files touched | 4 files, ~14 lines | `pubspec.yaml`, `app_routes.dart`, `app_router.dart`, `user_app_shell.dart` all touched; within budget | ✅ |
| Model choice | Dual: Gemma 3n (chat+vision) primary, FastVLM (vision fallback) | Both downloaded & downloadable, but **both exposed for chat** | ⚠️ Divergent |
| Inference package | `flutter_gemma ^0.4.0` or `google_generative_ai` | `flutter_gemma: ^0.13.6` (API changed mid-flight) | ⚠️ Upgraded |
| TTS | Reuse `ContextualTtsService`, add `AiTtsController` wrapper for paragraph-split + interrupt | Direct calls to `ContextualTtsService.speakSummary` (500-char truncation kicks in) | ❌ Wrapper not built |
| STT | Reuse `SttService` with Hindi + English | Reused, but language hard-coded to `'en'` | ❌ Language not wired |
| Nancy avatar | `NancyAvatar` widget with idle/listening/processing/responding states | `ai_avatar.dart` exists with all 4 states, but not wired into `AiVoiceChatView` (static 80×80 `Image.asset` is used instead) | ⚠️ Built, not used |
| Read-only data facade | `AiDataReader` wrapping trip costing, city search, maps launcher, active trip | **Not implemented** | ❌ Missing (Phase G) |
| Guard-rail system prompt | System prompt baked into every inference call | `AiContextBuilder` / `PromptBuilder` both exist, **neither is called** from `voice_chat_provider` | ❌ Dead code |
| Conversation history | `aiChatProvider` manages last-5 turns; history fed into prompt | `aiChatProvider` exists and compiles, **never written to or read from** | ❌ Dead wiring |
| Session lifecycle | Clear in-memory data on session end | `AiSessionProvider` exists; `VoiceChatProvider.dispose` over-reaches and tears down shared STT/TTS | ❌ Over-dispose bug |
| Model verification | SHA-256 checksum verification; corrupt state routes to redownload | `ModelStorageManager.*ChecksumSha256 = ''` → verification is a no-op; `ModelVerificationResult.corrupted` unused | ❌ Not enforced |
| Model hosting | `https://tranzfort.com/ai-models/...` (plan) | Constants use tranzfort.com; live URL in notes is `srv662-files.hstgr.io/...` | ⚠️ Confirm domain |
| Storage check | Detect real free storage, block if insufficient | Hard-coded 5 GB fallback in `getFreeStorageSpace()` | ❌ Stubbed |
| Feature flag | OFF by default, gradual rollout | `ai_feature_flag_provider` defaults to `true` | ⚠️ Reverse before release |
| FAB entry | `AiFloatingButton` in `user_app_shell` body Stack (trucker only) | Present, but navigates via `Navigator.pushNamed` in a GoRouter app → tap swallowed | ❌ Router mismatch |
| Camera features (Phase F) | Bilty / tyre / receipt / cargo via vision model | Not started | ⛔ Not scheduled yet |
| Data features (Phase G) | Load discovery, route plan, cost calc via `AiDataReader` | Not started | ⛔ Not scheduled yet |

### 18.2 Why Chat Quality Is Broken Right Now

The single user-visible failure ("junk output") is a chain of four small deviations from this plan:

1. **Model selection (§1.2):** Plan says FastVLM is a *fallback for low-spec devices* with *vision* as its main strength. In code, FastVLM is offered (and was actively used during testing) as a general chat model. FastVLM 0.5B has no instruction-tuning and no Gemma chat template; `flutter_gemma` loads it under `ModelType.general` which sends raw text with no template wrapper. The model then emits Gemma special tokens (`<start_of_turn>model_10…`) it saw in training data.
2. **System prompt (§7.2):** The V3 plan mandates a baked-in system prompt. The code never injects one.
3. **Chat template (§5.2 implicit):** `ModelType.general` bypasses templates; only `ModelType.gemmaIt` (for Gemma 3n `.task` file) applies the correct turn markers.
4. **History (§5.2):** Conversation context is never passed, so every turn is a cold start.

The combination: cold-start raw text → vision-only base model → no template → special-token soup.

**Fix locked in §18.5 and mirrored as P0-1 + P1-1 in the TODO.**

### 18.3 Why the FAB Does Nothing

Plan §4.3 shows the FAB as an overlay inside `UserAppShell`'s Stack (present and correct). Plan §11.1 lists `app_router.dart` as the route integration point (present, GoRoute correct). The bug is purely the call-site: `Navigator.of(context).pushNamed(...)` is a Navigator-1 API that doesn't know about GoRouter routes unless `onGenerateRoute` is set up. Replace with `context.goNamed(AppRoutes.aiAssistant)` and the FAB starts working instantly — no redesign needed.

### 18.4 Updated Module File Inventory (as-built)

```
lib/src/features/ai_assistant/
├── data/
│   ├── ai_context_builder.dart       ✅ built   (duplicate of prompt_builder.dart — pick one)
│   ├── ai_inference_service.dart     ✅ built   (chat template/system-prompt not applied)
│   ├── device_spec_service.dart      ✅ built
│   ├── model_download_service.dart   ✅ built   (no checksum / size verify call)
│   └── model_storage_manager.dart    ✅ built   (checksum constants empty)
│   │
│   └── ai_data_reader.dart           ❌ NOT BUILT (Phase G)
│
├── domain/
│   ├── ai_message.dart               ✅ built
│   ├── model_download_state.dart     ✅ built
│   ├── model_selection_strategy.dart ✅ built
│   ├── prompt_builder.dart           ⚠️ duplicate of ai_context_builder — remove
│   └── voice_enums.dart              ✅ built
│
├── presentation/
│   ├── ai_assistant_screen.dart      ✅ built   (does not route to redownload on corruption)
│   ├── ai_model_download_view.dart   ✅ built   (routes to non-existent /ai-chat)
│   ├── ai_voice_chat_view.dart       ✅ built   (Text subtitle not returned; static avatar)
│   │
│   ├── providers/
│   │   ├── ai_chat_provider.dart     ⚠️ built but UNUSED by voice flow
│   │   └── ai_session_provider.dart  ⚠️ built but not invoked on nav
│   │
│   └── widgets/
│       ├── ai_avatar.dart            ⚠️ built but UNUSED in chat view
│       ├── ai_floating_button.dart   ⚠️ uses wrong router API
│       ├── ai_quick_chips.dart       ⚠️ built but not surfaced
│       ├── download_progress_card.dart ✅ built
│       └── voice_recording_widget.dart ✅ built
│
├── providers/
│   ├── ai_feature_flag_provider.dart ⚠️ default = true (should be false in release)
│   ├── ai_user_preferences_provider.dart ✅ built
│   ├── model_status_provider.dart    ⚠️ never refreshed after download/delete
│   └── voice_chat_provider.dart      ❌ disposes shared services; language hard-coded
│
└── (no routes file — using core/navigation/app_router.dart as planned)
```

Legend: ✅ as designed · ⚠️ built but deviates from plan · ❌ planned but missing / broken · ⛔ out of scope for current phase.

### 18.5 Amendments to Sections 1, 3, 5, 7 (binding)

These are edits to the design — not just the implementation — and should be followed on re-implementation:

**§1.2 amendment (Final Model Decision):**
- Gemma 3n E2B is the **exclusive chat model**. FastVLM 0.5B is **vision-only** (bilty, tyre, receipt, cargo). Never route chat intents to FastVLM.
- Exposure: in `ModelSettingsSheet`, FastVLM's "Set Active" action should tag it `vision-only`; toggling *Use Real AI* for chat with FastVLM active must fail fast with an explanatory snackbar.

**§3.1 amendment (AI TTS):**
- Must ship `AiTtsController` (paragraph-split, interruptible, mute-aware). Direct calls to `ContextualTtsService.speakSummary` are prohibited for AI responses because the 500-char cap truncates answers.

**§5.2 amendment (Conversation Flow):**
- PROCESSING step must invoke this pipeline (in order): `detectLanguage(transcript)` → `aiChatProvider.addUserMessage` → `AiContextBuilder.buildCompletePrompt({history: aiChatProvider.getHistory(5)})` → `RealAIInferenceService.generateFromPrompt(systemPrompt, userTurn)` → `aiChatProvider.addAiMessage(response)` → `AiTtsController.speakResponse`.
- On RESPONDING exit (user taps mic again, or back), call `AiTtsController.cancel()`; do **not** dispose shared services.

**§7.1 amendment (Guard Rails):**
- Until `AiDataReader` lands (Phase G), the guard rails are enforced **only** by the system prompt. This is acceptable for placeholder mode. For real-AI mode, `AiDataReader` must be on the critical path before any Phase G feature is exposed to users.

**§8.1 amendment (Model Download):**
- Integrity pipeline is mandatory: size (±1 %) + SHA-256. `ModelVerificationResult.corrupted` must route `AiAssistantScreen` to a Redownload view (currently scaffolded but orphaned).

**New §7.4 — Shared Service Ownership Rule:**
- Feature-level providers (`VoiceChatProvider`, `AiSessionProvider`, etc.) are forbidden from calling `dispose()` on services obtained via `ref.watch`/`ref.read` on a shared Riverpod provider (`sttServiceProvider`, `contextualTtsServiceProvider`, `aiInferenceServiceProvider`). They may call `stop*()` / `cancel*()` methods only. Disposal is the provider's responsibility (via `ref.onDispose` inside the provider definition).

**New §4.4 — Router Rule:**
- All navigation inside the `ai_assistant` module must use GoRouter (`context.goNamed` / `context.pushNamed` / `GoRouter.of(context).go`). `Navigator.pushNamed` / `Navigator.pushReplacementNamed` are banned because the app's root navigator is configured through `MaterialApp.router`, not `MaterialApp.onGenerateRoute`.

### 18.6 Open Follow-ups Tracked in TODO (cross-reference)

All concrete task-level items are maintained in `docs/TODO-22-april.md` → *"April 23 (Evening) — Code Review: Diagnosis & Prioritized Roadmap"* under P0 / P1 / P2 / P3. This V3 document captures only the *design* impact of those fixes; the TODO captures the *work*.

| Section edited here | TODO items realising it |
|---------------------|-------------------------|
| §1.2 (FastVLM = vision only) | P0-1 |
| §3.1 (`AiTtsController`)     | P2-7 |
| §5.2 (pipeline order)        | P1-1, P1-2, P1-3, P1-4 |
| §7.1 (guard rails via prompt until G) | P1-1, P2-4 |
| §8.1 (verification)          | P2-1, P2-2, P2-3 |
| §7.4 (shared services)       | P0-5 |
| §4.4 (router)                | P0-3, P0-4 |

*End of V3 plan amendments — April 23, 2026 evening.*

---

## 19. MODEL REPLACEMENT — Drop FastVLM, Adopt Gemma 3 Family (April 23 Late Evening)

> Companion to `docs/TODO-22-april.md` § *"April 23 (Late Evening) — Strategic Pivot"*. This section rewrites §1.2 and §5.1 of the original V3 plan. The earlier dual-model design (Gemma 3n E2B + FastVLM 0.5B) is replaced by a **three-tier Gemma-only registry** driven by device capability.

### 19.1 Why the Pivot

Product constraints evolved: we must ship a usable chat experience on **2–3 GB RAM** Indian Android phones, 100 % offline, with strong Hindi. FastVLM is a vision base model (no chat tuning, no Gemma template) and produced token-soup on chat intents (see §18.2). Gemma 3n E2B at ~2.92 GB is too large to be the *default* install for low-end phones. We need something in the middle — and Google shipped exactly that: **Gemma 3 1B IT int4 QAT**, a 529 MB `.task` file officially packaged for MediaPipe / `flutter_gemma`, multilingual across 140+ languages including Hindi.

### 19.2 The Three-Tier Registry (replaces §1.2)

| Tier | Model | File | Int4 Size | Runtime RAM | Target Device | Role |
|------|-------|------|-----------|-------------|---------------|------|
| **Tiny** | Gemma 3 270M IT | `gemma3-270m-it-int4.task` | ≈ 200 MB | ≈ 0.5 GB | 2 GB RAM / <1 GB storage | Fallback for lowest-end phones. Short intents / routing replies only. |
| **Small** ⭐ | Gemma 3 1B IT | `gemma3-1b-it-int4.task` | ≈ 529 MB | ≈ 1.1 GB | 2.5–4 GB RAM | **Default.** Full Hindi/English chat; instruction-tuned; official chat template. |
| **Big** | Gemma 3n E2B IT | `gemma-3n-E2B-it-int4.task` | ≈ 2.92 GB | ≈ 3–4 GB | 4+ GB RAM | Opt-in flagship; best quality; future vision/audio. |

All three share:
- `ModelType.gemmaIt` + `ModelFileType.task`
- Same Gemma chat template (applied automatically by `flutter_gemma`)
- Same system-prompt priming pathway (see §5.2 amendment in §18.5)
- Same history trimming logic (see §18.5 amendment to §5.2)

Result: the `RealAIInferenceService` collapses to a single code path — no more `ModelFormat.task` vs `ModelFormat.litertlm` branching.

**FastVLM is removed from the chat registry.** If vision ships, it uses Gemma 3n E2B's built-in vision (`supportImage: true` on chat creation). FastVLM may return in a future phase as a pure caption model, but that is *not* on the launch path.

### 19.3 Rejected Alternatives

| Candidate | Why Rejected |
|-----------|--------------|
| **Qwen3 0.6B Instruct** | Multilingual (100+ languages) and `flutter_gemma`-supported, but different chat template family would double our template-handling code; Hindi quality ≈ Gemma 3 1B, so no quality reason to switch. Kept as documented alternative should Gemma quality disappoint in field tests. |
| **SmolLM 135M / SmolLM2-360M** | English-centric; Hindi quality insufficient for trucker use. |
| **Phi-4 Mini (3.8B)** | ≈ 2 GB int4; comparable size to Gemma 3n E2B but without Google's official LiteRT Android tooling and weaker on Hindi. |
| **Llama 3.2 1B Instruct** | Multilingual but not in the `flutter_gemma` supported list yet; would require a separate runtime. |
| **FastVLM 0.5B** | Vision base model, no chat tuning, no Gemma template. Root cause of current bug. |
| **Gemma 4 E2B** | Newer; not yet bundled as `.task` for Android (Oct 2025 LiteRT-LM `.litertlm` form). Re-evaluate when `.task` packaging lands — at that point Gemma 4 E2B likely replaces Gemma 3n E2B as the Big tier. |

### 19.4 Recommendation Logic (replaces `ModelSelectionStrategy.getRecommendedModel`)

```
function getRecommendedModel(deviceSpecs):
  if ram >= 4 GB and freeStorage >= 4 GB and userOptedIn:
      return Big (Gemma 3n E2B)
  if ram >= 2.5 GB and freeStorage >= 1 GB:
      return Small (Gemma 3 1B)    ← default path
  if ram >= 2 GB and freeStorage >= 0.5 GB:
      return Tiny (Gemma 3 270M) + banner("basic replies only")
  return DeviceNotSupported
```

- Big tier is never auto-installed. It is always surfaced as an opt-in upgrade ("Download Nancy Pro — 2.92 GB, better answers, ~30 min").
- Small is the recommended default for 80 % of the trucker base (3 GB RAM phones).
- Tiny exists to ensure *some* AI is available on the bottom 20 % of the fleet. Expectations are set honestly in the UI.

### 19.5 Hosting & Integrity

- Host all three `.task` files on the Hostinger bucket (same pattern as today).
- Compute and bake SHA-256 for each file before release. `ModelStorageManager.*ChecksumSha256` constants must be populated (resolves §18.5 §8.1 amendment).
- Size tolerance tightened from ±5 % to ±1 %. A 529 MB file off by 5 % is 26 MB — enough to corrupt the tokenizer.
- On any verification failure: delete file, route to `AiModelRedownloadView`, log reason.

### 19.6 Module Changes Required

```
lib/src/features/ai_assistant/
├── domain/
│   └── model_selection_strategy.dart    ← update AiModel enum, thresholds, ModelInfo
├── data/
│   ├── ai_inference_service.dart        ← collapse to single gemmaIt path
│   └── model_storage_manager.dart       ← add gemma3_1b_* + gemma3_270m_* constants, drop fastVLM_* (or mark deprecated)
└── presentation/
    └── ai_model_download_view.dart      ← rebuilt as tier-picker (see §21)
```

FastVLM files are *not* deleted from the codebase yet — left in place behind a `ModelCapability.vision` check for Phase F revival. UI hides them.

---

## 20. VOICE STACK OVERHAUL — Hindi-First STT + TTS

> Rewrites §3.1 (TTS) and adds companion §3.0 (STT) to the original V3 plan.

### 20.1 Design Principles

1. **Hindi and English are co-equal defaults.** Language is never hard-coded; every turn resolves a locale from: *per-session override → user AI-language preference → app locale → device locale → `en-IN` fallback*.
2. **Auto-detect the user's language from what they actually say.** Unicode Devanagari heuristic switches STT/TTS for the next turn. User always has a manual override chip.
3. **TTS is a pluggable backend.** Default is free / installed (`flutter_tts` + Google TTS engine). A premium backend (Piper) is an **opt-in 65 MB download** — never forced.
4. **Shared services (`ContextualTtsService`, `SttService`) are reused, not replaced.** Nancy's voice lifecycle is managed by a new `AiTtsController` *on top of* the existing TTS service — we never own the raw `FlutterTts` instance (see §7.4 shared-service rule).

### 20.2 STT (§3.0 — new)

**Package:** `speech_to_text` (already present in pubspec).
**Engine:** Google STT on Android (works offline once the Hindi speech pack is installed in Google-app settings, which happens automatically on Play-Services phones).

**Locale resolution (per `startListening` call):**

```
AiLanguageResolver.resolveSttLocale() → String localeId
  1. if voiceChat.sessionLocale != null → return it           (manual toggle)
  2. if aiLanguagePreference.override != null → return it      (user preference)
  3. if appLocale == 'hi' → return 'hi-IN'
  4. if appLocale == 'en' → return 'en-IN'
  5. if device locale in (hi, hi-IN, hi-IN-*) → return 'hi-IN'
  6. return 'en-IN'
```

**Auto-detect:** on every `onFinalResult`, compute:
```
devanagariRatio = count(chars in U+0900..U+097F) / totalLetters(transcript)
if devanagariRatio >= 0.30 and currentLocale != 'hi-IN':
    sessionLocale = 'hi-IN'
    showToast("Hindi detect kiya. ⇄ se badal sakte hain.")  // one-time per session
```

**Fallback chain:** if `hi-IN` unavailable at runtime (non-GMS phone), package returns `notAvailable`; we surface an error toast *"Hindi voice recognition not installed — using English"* and fall back to `en-IN`. Whisper-tiny ONNX fallback is a Phase H item, not launch-blocking.

### 20.3 TTS (§3.1 rewrite)

**New abstraction:** `AiTtsController` (feature-level, in `ai_assistant/domain/`) — owns AI-specific speech lifecycle, delegates to a pluggable backend.

```dart
abstract class AiTtsBackend {
  Future<void> init();
  Future<void> speak(String text, {required String languageCode, double? rate});
  Future<void> stop();
  Future<void> pause();
  Future<void> resume();
  bool get isSpeaking;
  Stream<TtsLifecycleEvent> get events;
}

// Implementations:
class FlutterTtsBackend implements AiTtsBackend { ... }   // default, 0 MB
class PiperTtsBackend   implements AiTtsBackend { ... }   // opt-in, ~65 MB
```

`AiTtsController` wraps whichever backend is active plus:
- **Sentence splitting** via Unicode-aware regex (`[.।!?]+\s+` + en/hi punctuation) so long Nancy responses are spoken incrementally and can be interrupted cleanly.
- **Streaming queue:** as tokens arrive from the LLM (§18.5 P1-5), sentences are enqueued; once a sentence is complete, it is dispatched to the backend while the LLM continues to generate.
- **Barge-in:** public `cancel()` method called on mic tap; stops current and clears the queue.
- **Mute-aware:** reads `ttsMutedProvider` before speaking; mutes swallow output silently, never error.

**Default backend — `FlutterTtsBackend`:**

```dart
await tts.setLanguage(languageCode);              // 'hi-IN' or 'en-IN'
await tts.setSpeechRate(languageCode == 'hi-IN' ? 0.50 : 0.52);
await tts.setPitch(1.0);
// Voice preference (best-effort):
final voices = await tts.getVoices();
final preferred = voices.firstWhere(
  (v) => v['locale'] == languageCode && v['name'].toString().contains('network'),
  orElse: () => voices.firstWhere((v) => v['locale'] == languageCode, orElse: () => null),
);
if (preferred != null) await tts.setVoice(preferred);
```

On Google TTS engine (99 % of Play phones), `hi-IN` maps to `hi-in-x-hid-network` / `hi-in-x-hie-local` / `hi-in-x-hic-local` — the same voices Google Maps uses for Hindi navigation. Quality is acceptable as a launch default; users who want better can install Piper.

**Opt-in backend — `PiperTtsBackend`:**

- Voice: `rhasspy/piper-voices/hi/hi_IN/rohan/medium/` (ONNX 63 MB + config ~1 MB + espeak-ng assets ~10 MB).
- Plugin: `flutter_offline_piper_tts` (Nov 2025); if the plugin proves unstable we own the integration via `onnxruntime` + espeak-ng FFI. Decision gate documented in the TODO NP2-3.
- Storage: `<appDocs>/ai_voices/piper_hi_rohan/`.
- Lifecycle identical to the Flutter TTS backend.

**When user has Piper installed but speaks English:** `AiTtsController` routes to `FlutterTtsBackend` (Google en-IN voice) because Piper was downloaded only as a Hindi pack. We do not force English-through-Piper; the English Google voice is already good.

### 20.4 Message Flow (replaces §5.2 PROCESSING/RESPONDING pipeline)

```
STT finalResult (transcript + localeId)
  │
  ▼
aiChatProvider.addUserMessage(transcript)
  │
  ▼
AiLanguageResolver.detectLanguage(transcript)  → sessionLocale
  │
  ▼
AiContextBuilder.buildCompletePrompt({
    systemPrompt: withLanguageHint(sessionLocale),
    history: aiChatProvider.getHistory(5),
    userQuery: transcript,
})
  │
  ▼
RealAIInferenceService.generateStream(prompt)     // tokens stream out
  │                                                │
  ▼                                                ▼
aiChatProvider.addAiMessage(finalText)      AiTtsController.speakIncremental(tokens, sessionLocale)
                                                   │
                                                   ▼
                                             FlutterTtsBackend or PiperTtsBackend
                                                   │
                                                   ▼
                                             audio playback (mute-aware, interruptible)
```

On `VoiceChatProvider` leave (back/close):
- `AiTtsController.cancel()` (stops current and clears queue)
- `SttService.stopListening()`
- **Never** `dispose()` any shared service (§7.4).

---

## 21. UX REDESIGN — Hindi-First, Tier-Based Install, Barge-In Chat

> Rewrites §4 (UI/UX) of the original V3 plan. The previous design was desktop-like (dense tables, English-only copy, single-screen settings sheet). Replaced with an Indian-mobile-first, Hindi-first flow.

### 21.1 Design Principles (replaces §4.1)

1. **Devanagari first.** Hindi copy is primary; Latin Hinglish is secondary. All strings routed through `AppLocalizations`.
2. **Icon-heavy.** Every actionable row has an emoji or icon. Trucker users scan icons faster than text.
3. **Concrete units.** File sizes in MB, download time in minutes on "4G", RAM in GB, NOT technical units ("int4", "Q4_0", "tokens/s").
4. **One decision per screen.** Model picker shows one recommended card, not a dense comparison by default.
5. **Big touch targets.** Minimum 48 dp, mic button 96 dp. Works with gloves (truckers in winter).
6. **Progressive disclosure.** "Compare versions" drawer and "Why this?" panels for users who want detail.

### 21.2 Screen 1 — First-Run Install (replaces onboarding in §4.2)

Entry point: first tap on Nancy FAB *when no model is installed*, OR after trucker onboarding if feature flag is on.

- Hero: `NancyAvatar` (idle animation) + 1-line Hindi tagline *"Aapki apni bolne wali saathi"*.
- Two short proof-points: *"100% offline"*, *"Internet band bhi chalta"*.
- Recommended tier card (chosen by `ModelSelectionStrategy`):
  - ⭐ Badge "RECOMMENDED"
  - Tier name (localised) + size in MB
  - Install time estimate on 4G (~8 min for 529 MB at 1 MB/s)
  - 3–4 bullet-point benefits in Hindi
  - Primary button: *"Install Nancy"*
- Secondary:
  - `Compare versions ▾` — expands a 3-row drawer (see §21.3)
  - `Later karenge` — dismiss and return to app

### 21.3 Compare Drawer (replaces dense model table)

Tappable row-per-tier, each with **icon + name + size + 1-line trade-off**:

```
🪶  Tiny      200 MB   "Purane phone ke liye"
⭐  Small     529 MB   "Recommended — smooth Hindi chat"
🚀  Big     2.92 GB   "Best — but 30 min download"
```

Tapping any row opens a detail sheet with:
- RAM required
- Hindi quality (Basic / Full / Full+)
- Languages supported
- Camera support (Yes only on Big)
- Primary CTA: *"Yeh version install karein"*
- Secondary: *"Wapas jaayein"*

### 21.4 Screen 2 — Download Progress (replaces §4.3 progress card)

- Full-screen, centred.
- Large circular progress (80 dp) with MB / total overlay in centre.
- Below: download speed (KB/s or MB/s), ETA ("5 min bache hain").
- Pause + Cancel as outlined buttons. Resume uses existing `ModelDownloadService` Range header.
- Error state shows cause in Hindi ("Internet dheema hai — Wifi chalu karein") + Retry button.
- On success: transition (no dialog) to §21.5.

### 21.5 Post-Download Upsell — Premium Hindi Voice

- Small card offering Piper hi_IN voice: *"Nancy ki Hindi aawaz aur better banayein? Ek baar aur 65 MB download karna hoga."*
- Buttons: *"Haan, install karein"* (downloads Piper pack, then chat) / *"Abhi nahi"* (skip to chat).
- Skippable; preference saved — don't re-prompt for 7 days.

### 21.6 Screen 3 — AI Settings (replaces `ModelSettingsSheet` bottom-sheet)

Promote from bottom-sheet to **full-screen route** `/ai-settings` (GoRoute). Sheet was too cramped for the new surface area.

Sections (in order, all localised):
1. **Active Version** — radio-row for Tiny / Small / Big. Shows *[Downloaded ✓] / [Install 200 MB]*.
2. **Language** — dropdown main language (Hindi/English) + auto-detect toggle.
3. **Voice** — dropdown "Default Hindi (Google) / Nancy Premium Hindi (Piper)". Piper row disabled if not installed, with inline install CTA.
4. **Response mode** — Real AI / Simulated switch (existing), with the **actual subtitle fix** from §18.5 P0-2.
5. **Storage** — per-model size + "Clear all AI data" destructive action.

### 21.7 Screen 4 — Voice Chat (replaces §4.4 chat UI)

Replaces the current near-empty `AiVoiceChatView`:

- **AppBar:** back arrow, title "Nancy" (localised), mute toggle (wired to `ttsMutedProvider`, fixing §18.4 P3-4), settings icon.
- **Hero (top 30 %):** `NancyAvatar(state: idle|listening|processing|speaking)` — state-driven animation (pulses when listening, rotates dots when processing, mouth animates when speaking). Replaces the static 80 × 80 Image.asset.
- **Quick chips (below avatar, idle state only):** scrollable row with emoji + Hindi label:
  - *📦 Load dhundo*
  - *🗺 Rasta batao*
  - *💰 Kharcha nikalo*
  - *📞 Help*
  Tap appends template query and auto-submits to inference.
- **Conversation history (middle):** scrollable list bound to `aiChatProvider.messages` (fixes §18.4 §P1-2 "dead wiring"). User turns right-aligned; Nancy turns left-aligned with streaming text. Auto-scroll to bottom on new message.
- **Language toggle (persistent, above mic):** `HI ⇄ EN` chip, always visible, tap to cycle, shows current active locale.
- **Mic (bottom):** 96 dp pulsing button.
  - **Short tap:** toggle listen / stop.
  - **Long-press (lock mode):** starts listening with haptic feedback; release = stop.
  - **Mic tap during Nancy speaking:** **barge-in** — `AiTtsController.cancel()` + start listening in one gesture.
- **Status line:** localised, driven off `VoiceChatState`:
  - idle → "Ready" / "Suniye"
  - listening → "Sun rahi hoon…" / "Listening…"
  - processing → "Soch rahi hoon…" / "Thinking…"
  - speaking → "Bol rahi hoon…" / "Speaking…"
  - error → localised error string

### 21.8 Micro-Interactions

- **Haptics:** light tap on mic press, medium on STT started, success on Nancy response complete.
- **Sounds:** optional earcon on listen-start (user setting, default off).
- **Barge-in responsiveness budget:** mic press → TTS cancelled ≤ 150 ms (requires calling `stop()` on the native TTS engine before starting STT; wire this in `AiTtsController.cancel()`).
- **Streaming latency:** first Nancy audible sentence should start within 2 s of user finishing their utterance on a 3 GB RAM phone with Small tier (design target; verify in device lab).

### 21.9 Accessibility & Low-End Device Care

- Minimum contrast AA on all text.
- No animations above 60 fps requirement on Nancy avatar; all avatar states use low-cost transforms (scale / rotation), no per-frame rasterisation.
- Hindi font: `NotoSansDevanagari` bundled in `assets/fonts/` to guarantee glyph coverage on Android 7/8 where system Hindi font may be missing/cut.
- Screen-reader labels in both languages.
- Works in portrait only (simplifies layout on small screens).

---

## 22. LOCALISATION, STRINGS & ASSETS

> New section. The V3 plan was English-only in its strings appendix; this section establishes the Hindi-first string catalogue Nancy needs.

### 22.1 String Catalogue (representative subset)

Add the following keys to `lib/src/l10n/app_en.arb` and `app_hi.arb` (all existing project localisation infrastructure reused):

| Key | English | Hindi (Devanagari) |
|-----|---------|--------------------|
| `ai.appBar.title` | Nancy | नैंसी |
| `ai.greeting.primary` | Hello! How can I help? | नमस्ते! मैं आपकी क्या मदद कर सकती हूँ? |
| `ai.greeting.subtitle` | Tap the microphone to speak | माइक दबाकर बोलिए |
| `ai.status.idle` | Ready | तैयार हूँ |
| `ai.status.listening` | Listening… | सुन रही हूँ… |
| `ai.status.processing` | Thinking… | सोच रही हूँ… |
| `ai.status.speaking` | Speaking… | बोल रही हूँ… |
| `ai.status.error` | Error | त्रुटि |
| `ai.chip.findLoad` | 📦 Find loads | 📦 लोड ढूँढो |
| `ai.chip.route` | 🗺 Plan route | 🗺 रास्ता बताओ |
| `ai.chip.cost` | 💰 Trip cost | 💰 खर्चा निकालो |
| `ai.chip.help` | 📞 Help | 📞 मदद |
| `ai.install.tagline` | Your own voice companion | आपकी अपनी बोलने वाली साथी |
| `ai.install.proof.offline` | 100% offline | 100% ऑफलाइन |
| `ai.install.proof.noInternet` | Works without internet | बिना इंटरनेट चलती है |
| `ai.install.recommended` | RECOMMENDED | सुझाव |
| `ai.install.cta` | Install Nancy | नैंसी इंस्टॉल करें |
| `ai.install.later` | Maybe later | बाद में |
| `ai.install.compare` | Compare versions | वर्ज़न की तुलना करें |
| `ai.tier.tiny.name` | Tiny Nancy | छोटी नैंसी |
| `ai.tier.tiny.tagline` | For older phones | पुराने फ़ोन के लिए |
| `ai.tier.small.name` | Nancy | नैंसी |
| `ai.tier.small.tagline` | Recommended — smooth Hindi chat | सुझाव — अच्छी हिंदी बातचीत |
| `ai.tier.big.name` | Nancy Pro | नैंसी प्रो |
| `ai.tier.big.tagline` | Best quality, larger download | बेहतरीन, लेकिन बड़ा डाउनलोड |
| `ai.download.timeOn4G` | {minutes} min on 4G | 4G पर लगभग {minutes} मिनट |
| `ai.download.speed` | {speed}/s | {speed}/सेकंड |
| `ai.download.eta` | {minutes} min left | {minutes} मिनट बाकी |
| `ai.download.pause` | Pause | रोकें |
| `ai.download.cancel` | Cancel | रद्द करें |
| `ai.download.retry` | Retry | फिर कोशिश करें |
| `ai.download.errorSlow` | Internet is slow — try Wi-Fi | इंटरनेट धीमा है — Wi-Fi चालू करें |
| `ai.upsell.voice.title` | Better Hindi voice? | बेहतर हिंदी आवाज़ चाहिए? |
| `ai.upsell.voice.body` | Download 65 MB voice pack for richer Hindi speech. | 65 MB डाउनलोड करके नैंसी की आवाज़ और बेहतर बनाएँ। |
| `ai.upsell.voice.install` | Yes, install | हाँ, इंस्टॉल करें |
| `ai.upsell.voice.later` | Not now | अभी नहीं |
| `ai.settings.title` | Nancy Settings | नैंसी सेटिंग्स |
| `ai.settings.activeVersion` | Active version | सक्रिय वर्ज़न |
| `ai.settings.language` | Language | भाषा |
| `ai.settings.autoDetect` | Auto-detect Hindi/English | हिंदी/अंग्रेज़ी अपने आप पहचाने |
| `ai.settings.voice` | Voice | आवाज़ |
| `ai.settings.voice.default` | Default (Google) | डिफ़ॉल्ट (Google) |
| `ai.settings.voice.piper` | Nancy Premium Hindi | नैंसी प्रीमियम हिंदी |
| `ai.settings.responseMode` | Response mode | जवाब का तरीका |
| `ai.settings.responseMode.realAi` | Real AI | असली AI |
| `ai.settings.responseMode.simulated` | Simulated | सिम्युलेटेड |
| `ai.settings.storage` | Storage | स्टोरेज |
| `ai.settings.clearData` | Clear all AI data | सारा AI डेटा हटाएँ |
| `ai.languageSwitch.toast.toHindi` | Switched to Hindi. Tap ⇄ to change. | हिंदी पर आ गई। बदलने के लिए ⇄ दबाएँ। |
| `ai.languageSwitch.toast.toEnglish` | Switched to English. Tap ⇄ to change. | English पर आ गई। बदलने के लिए ⇄ दबाएँ। |
| `ai.error.sttHindiNotInstalled` | Hindi voice recognition not installed — using English. | हिंदी वॉइस पहचान इंस्टॉल नहीं — अंग्रेज़ी इस्तेमाल हो रही है। |
| `ai.error.modelCorrupted` | Nancy files corrupted — please redownload. | नैंसी की फ़ाइल खराब है — फिर से डाउनलोड करें। |
| `ai.deviceNotSupported.title` | Device Not Supported | डिवाइस सपोर्ट नहीं करता |
| `ai.deviceNotSupported.body` | Nancy needs at least 2 GB RAM and 2 GB storage. | नैंसी के लिए कम-से-कम 2 GB RAM और 2 GB स्टोरेज चाहिए। |

Localisation rule: no English string is rendered in AI UI without a matching Hindi key. Code review gate.

### 22.2 Assets to Add

```
assets/
├── fonts/
│   └── NotoSansDevanagari-Regular.ttf   ← bundle for low-end Android font coverage
│   └── NotoSansDevanagari-Bold.ttf
├── images/
│   ├── nancy-bot.png                    ← existing (hero)
│   ├── nancy-bot-icon.png               ← existing (FAB)
│   └── nancy-avatar-states/             ← new, for animated avatar
│       ├── idle.png
│       ├── listening.png
│       ├── processing.png
│       └── speaking.png
└── (model + voice pack files stay server-side on Hostinger, downloaded to app docs)
```

Register Noto Sans Devanagari in `pubspec.yaml` under `flutter > fonts`, and add it as a fallback to the `AppTypography` theme.

### 22.3 System-Prompt Localisation (addendum to §7.2)

The Nancy system prompt gains a language hint line at build time:

```dart
final hint = sessionLocale == 'hi-IN'
  ? 'The user prefers Hindi (Devanagari). Respond in Hindi unless explicitly asked to switch.'
  : 'The user prefers English. You may use Hinglish if the question is asked in Hinglish.';
```

This is appended to `AiContextBuilder.buildSystemPrompt()` output. The persona / rules / trucking vocabulary remain unchanged from §7.2.

### 22.4 Cross-Reference Table

| Section edited here | Supersedes in the original V3 plan | Tracked TODO items |
|---------------------|-----------------------------------|--------------------|
| §19 Model registry | §1.2, §5.1 | NP0-1 … NP0-8 |
| §20.2 STT locale   | §3.0 (new)     | NP1-1, NP1-2, NP1-6 |
| §20.3 TTS backends | §3.1          | NP1-3, NP1-4, NP1-5; NP2-1…NP2-5 |
| §20.4 Pipeline     | §5.2          | §18.5 §5.2 amendment + P1-1 … P1-5 |
| §21 UX             | §4            | NP3-1 … NP3-7 |
| §22 Strings/assets | §4.1 sidebar  | NP3-5 |

---

*End of V3 plan sections §19–22 — April 23, 2026 late evening.*
*The earlier V3 plan (§1–17) remains the long-form design narrative; §18 is the audit; §19–22 are the binding revisions driven by the "drop FastVLM, Hindi-first voice, UX redesign" pivot.*


