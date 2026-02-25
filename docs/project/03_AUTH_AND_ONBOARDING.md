# 03: Auth & Onboarding Funnel

**Status:** LOCKED  
**Audience:** All Developers  
**Objective:** Define every screen, widget, edge case, error state, and state transition in the authentication and onboarding funnel. A junior developer should be able to build the entire auth flow from this document alone.

---

## 1. Core Philosophy

- **Rule 1:** There is NO email/password login or signup. Google-first, Phone OTP fallback.
- **Rule 2:** There are NO separate "Login" and "Signup" screens. There is only one "Continue" screen. The backend handles both cases (new user → creates profile, existing user → signs in).
- **Rule 3:** The marketplace requires a verified phone number. Google accounts provide email only, so we MUST capture phone during onboarding.
- **Rule 4:** No user reaches any dashboard without: (a) authenticated session, (b) phone number on profile, (c) role selected. This is the **Profile Completeness Gate**.

---

## 2. Screen-by-Screen Flow

### 2.1 Splash Screen (`/splash`)
```
┌────────────────────────────────────┐
│          (no AppBar)               │
│                                    │
│         [App Logo - 120x120]       │
│          "TranZfort"               │
│    (headlineLarge, primary)        │
│                                    │
│   [CircularProgressIndicator]      │
│                                    │
└────────────────────────────────────┘
```

**Logic (runs in `initState`):**
1. Wait 1.5 seconds (branding moment).
2. Check `Supabase.instance.client.auth.currentSession`.
3. If `null` → navigate to `/auth`.
4. If session exists → fetch `profiles` row → run Profile Completeness Gate (§3).

**TTS:** On FIRST ever app open (check `SharedPreferences('has_seen_splash')`):
- Speak: "Namaste, TranZfort mein aapka swagat hai."

**Edge Cases:**
- **Session exists but expired:** Supabase auto-refreshes tokens. If refresh fails → `AuthException` → catch → navigate to `/auth`.
- **Session exists but user is banned:** After fetching profile, check `is_banned`. If `true` → show "Your account has been suspended" dialog → sign out → navigate to `/auth`.

---

### 2.2 Auth Continue Screen (`/auth`)
```
┌────────────────────────────────────┐
│          (no AppBar)               │
│                                    │
│         [App Logo - 80x80]         │
│                                    │
│     "Namaste! Welcome to"          │
│         "TranZfort"                │
│    (headlineMedium, center)        │
│                                    │
│     "India ka trusted load         │
│      matching platform"            │
│    (bodyMedium, gray, center)      │
│                                    │
│  ┌──────────────────────────────┐  │
│  │ [G logo] Continue with Google│  │
│  │  (PrimaryButton, full width) │  │
│  └──────────────────────────────┘  │
│         SizedBox(height: 16)       │
│  ┌──────────────────────────────┐  │
│  │ [📱] Continue with Phone     │  │
│  │  (OutlineButton, full width) │  │
│  └──────────────────────────────┘  │
│                                    │
│  "By continuing, you agree to"     │
│  "our Terms of Service"            │
│  (bodySmall, gray, tappable link)  │
│                                    │
└────────────────────────────────────┘
```

**TTS:** Auto-speak: "Google se continue karein ya phone number se."

**Google Flow (Tap "Continue with Google"):**
1. Button shows `CircularProgressIndicator`. Both buttons disabled.
2. `authEntryProvider.continueWithGoogle()` called.
3. Native Google Sign-In dialog appears.
4. User selects Google account → `idToken` returned.
5. `AuthRepository.signInWithGoogle(idToken)` → Supabase `signInWithIdToken()`.
6. Supabase creates `auth.users` row (if new) → profile trigger fires → `profiles` row created.
7. On success → Profile Completeness Gate decides next screen.
8. On failure → Snackbar with `AppFailureType`-mapped message.

**Phone Flow (Tap "Continue with Phone"):**
1. Navigate to `/auth/phone-entry`.

**Error States:**
| Error | AppFailureType | User Message |
|-------|---------------|-------------|
| Google cancelled by user | (no error, just return) | No message |
| Google sign-in network error | `network` | "Please check your internet connection." |
| Google account already linked to different phone | `conflict` | "This Google account is already registered. Try signing in." |
| Unknown Supabase error | `serverError` | "Something went wrong. Please try again." |

---

### 2.3 Phone Entry Screen (`/auth/phone-entry`)
```
┌────────────────────────────────────┐
│ [←]  Enter Your Phone Number       │
├────────────────────────────────────┤
│                                    │
│     "We'll send you a              │
│      verification code"            │
│    (bodyMedium, gray)              │
│                                    │
│  ┌──────────────────────────────┐  │
│  │ [+91 ▼] [__________]        │  │
│  │  Country   10-digit number   │  │
│  └──────────────────────────────┘  │
│                                    │
│  ┌──────────────────────────────┐  │
│  │      Send OTP                │  │
│  │  (PrimaryButton, full width) │  │
│  └──────────────────────────────┘  │
│                                    │
└────────────────────────────────────┘
```

**Validation (client-side):**
- Phone must be exactly 10 digits (Indian mobile).
- Must start with 6, 7, 8, or 9.
- Country code locked to `+91` for V1.

**Flow:**
1. User enters phone number.
2. Tap "Send OTP" → `authEntryProvider.requestOtp('+91' + phone)`.
3. Repository calls Supabase `signInWithOtp(phone: phone)` (which triggers Fast2SMS).
4. On success → navigate to `/auth/otp-verify` with phone number as parameter.
5. On failure → Snackbar.

**Error States:**
| Error | Message |
|-------|---------|
| Invalid phone format | "Please enter a valid 10-digit mobile number." (client-side, red border) |
| Phone already registered (conflict) | "This number is already registered. OTP sent — verify to sign in." |
| SMS delivery failed | "Could not send OTP. Please try again." |
| Rate limited | "Too many attempts. Please wait 60 seconds." |

---

### 2.4 OTP Verification Screen (`/auth/otp-verify`)
```
┌────────────────────────────────────┐
│ [←]  Verify OTP                    │
├────────────────────────────────────┤
│                                    │
│     "Enter the 6-digit code        │
│      sent to +91 98765XXXXX"       │
│    (bodyMedium, gray)              │
│                                    │
│  ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐        │
│  │_│ │_│ │_│ │_│ │_│ │_│         │
│  (6 individual digit boxes,        │
│   auto-focus, auto-advance)        │
│                                    │
│  ┌──────────────────────────────┐  │
│  │      Verify                  │  │
│  │  (PrimaryButton, full width) │  │
│  └──────────────────────────────┘  │
│                                    │
│  "Didn't receive code?"            │
│  [Resend OTP] (text button,        │
│   disabled for 60s countdown)      │
│  "Resend in 45s"                   │
│                                    │
└────────────────────────────────────┘
```

**Flow:**
1. User enters 6-digit OTP (auto-submit on 6th digit, or tap "Verify").
2. `authOtpProvider.verifyOtp(phone, code)`.
3. Repository calls `Supabase.auth.verifyOTP(phone: phone, token: code, type: OtpType.sms)`.
4. On success → session established → Profile Completeness Gate.
5. On failure → shake animation on digit boxes + error message.

**Resend Logic:**
- "Resend OTP" button disabled for 60 seconds after last send.
- Countdown timer shown: "Resend in 45s".
- After countdown → button enabled, blue text.
- Maximum 3 resend attempts per session.

**Error States:**
| Error | Message |
|-------|---------|
| Wrong OTP | "Invalid code. Please check and try again." (shake animation) |
| OTP expired (>5 minutes) | "Code expired. Tap Resend OTP." |
| Max attempts exceeded | "Too many failed attempts. Please request a new code." |

---

### 2.5 Phone Capture Screen — Google Users (`/onboarding/phone`)
This screen appears ONLY when a Google-authenticated user has no phone number on their profile.

```
┌────────────────────────────────────┐
│          (no AppBar — no back)     │
│                                    │
│     [Phone icon - 48x48]          │
│                                    │
│     "One Last Step!"               │
│    (headlineMedium, center)        │
│                                    │
│     "We need your phone number     │
│      to connect you with loads."   │
│    (bodyMedium, gray, center)      │
│                                    │
│  ┌──────────────────────────────┐  │
│  │ [+91 ▼] [__________]        │  │
│  └──────────────────────────────┘  │
│                                    │
│  ┌──────────────────────────────┐  │
│  │      Verify Phone            │  │
│  │  (PrimaryButton, full width) │  │
│  └──────────────────────────────┘  │
│                                    │
└────────────────────────────────────┘
```

**No back button.** User CANNOT skip this step. It's a gate.

**Flow:**
1. User enters phone → Send OTP → Verify OTP (inline or navigate to OTP screen).
2. On OTP verified → `AuthRepository.updateProfile(userId, mobile: phone)`.
3. If success → Profile Completeness Gate continues (likely to Role Selection).
4. If `conflict` → Snackbar: "This number is already linked to another account. Please use that account or try a different number."

**Edge Case — Duplicate Phone:**
- User A signs up via Phone OTP (+91 98765...).
- User B signs up via Google, then tries to add +91 98765... as their phone.
- DB throws UNIQUE violation → `AppFailureType.conflict`.
- UI shows: "This number is already linked to another account."
- User must use a different phone number OR sign in via Phone OTP with that number.

---

### 2.6 Role Selection Screen (`/onboarding/role`)
```
┌────────────────────────────────────┐
│          (no AppBar — no back)     │
│                                    │
│     "What describes you best?"     │
│    (headlineMedium, center)        │
│                                    │
│  ┌──────────────────────────────┐  │
│  │ [🏭 Factory icon]            │  │
│  │  "I am a Supplier"          │  │
│  │  "I have loads to ship"     │  │
│  │  (Card, tappable, 120px h)  │  │
│  └──────────────────────────────┘  │
│         SizedBox(height: 16)       │
│  ┌──────────────────────────────┐  │
│  │ [🚛 Truck icon]              │  │
│  │  "I am a Trucker"           │  │
│  │  "I have trucks to fill"    │  │
│  │  (Card, tappable, 120px h)  │  │
│  └──────────────────────────────┘  │
│                                    │
└────────────────────────────────────┘
```

**TTS:** Auto-speak: "Aap supplier hain ya trucker? Chunein."

**No back button.** User CANNOT skip this step.

**Flow:**
1. User taps one of the two cards.
2. Card gets a blue border (selected state). Short haptic feedback.
3. Confirmation dialog: "You are selecting [Supplier/Trucker]. This cannot be changed later. Continue?"
4. On confirm → `authRoleProvider.selectRole(role)`.
5. Provider calls `AuthRepository.updateProfile(userId, role: role)`.
6. Provider also creates the role extension record:
   - Supplier → `INSERT INTO suppliers (id) VALUES (userId)`.
   - Trucker → `INSERT INTO truckers (id) VALUES (userId)`.
7. On success → navigate to respective dashboard.
8. On failure → Snackbar.

**IMPORTANT:** Role selection is **permanent** in V1. There is no "Switch Role" feature. The confirmation dialog makes this clear.

---

## 3. The Profile Completeness Gate (GoRouter Guard)

Implemented as a `redirect` function in `app_router.dart`. Runs on EVERY navigation.

```
┌─────────────────────────────────────────────┐
│ Is user authenticated (session exists)?     │
│   NO → /auth                                │
│   YES ↓                                     │
├─────────────────────────────────────────────┤
│ Is user banned (profiles.is_banned)?        │
│   YES → Show ban dialog → sign out → /auth  │
│   NO ↓                                      │
├─────────────────────────────────────────────┤
│ Does profile have mobile?                   │
│   NO → /onboarding/phone                    │
│   YES ↓                                     │
├─────────────────────────────────────────────┤
│ Does profile have user_role_type?           │
│   NO → /onboarding/role                     │
│   YES ↓                                     │
├─────────────────────────────────────────────┤
│ Route to role-appropriate dashboard:         │
│   supplier → /supplier-dashboard             │
│   trucker → /find-loads                      │
└─────────────────────────────────────────────┘
```

### GoRouter Singleton Rule
- GoRouter is created ONCE and never recreated.
- Auth state changes trigger `router.refresh()` via a `_RouterNotifier` that uses `ref.listen()`.
- Redirect closure uses `ref.read()` (not `ref.watch()`) to get current auth/role values.
- This prevents the bug where `ref.watch()` rebuilds the GoRouter on every auth change, destroying the navigation stack.

### Provider Invalidation on Login/Logout
After successful auth:
1. `invalidateAllUserProviders()` — clears stale data from previous user session.
2. Fetch fresh profile from DB.
3. `ref.invalidate(userRoleProvider)`.
4. `await Future.delayed(Duration(milliseconds: 100))` — allow providers to settle.
5. Navigate explicitly to correct destination.

On sign out:
1. `Supabase.auth.signOut()`.
2. `invalidateAllUserProviders()`.
3. Navigate to `/auth`.

---

## 4. State Management (Riverpod)

### 4.1 Provider Map
| Provider | State | Intents |
|----------|-------|---------|
| `authSessionProvider` | `Stream<User?>` | Read-only. GoRouter listens. |
| `authEntryProvider` | `{isGoogleLoading, isPhoneLoading, lastError}` | `continueWithGoogle()`, `requestOtp(phone)` |
| `authOtpProvider` | `{isVerifying, isResending, lastError}` | `verifyOtp(phone, code)`, `resendOtp(phone)` |
| `authRoleProvider` | `{isUpdating, lastError}` | `selectRole(role)` |
| `userProfileProvider` | `AsyncValue<Profile?>` | Fetches current user's profile from DB |
| `userRoleProvider` | `UserRole?` | Derived from `userProfileProvider` |

### 4.2 Repository Contract
```dart
abstract class AuthRepository {
  Future<Result<void>> signInWithGoogle();
  Future<Result<void>> sendOtp(String phone);
  Future<Result<void>> verifyOtp(String phone, String code);
  Future<Result<void>> updateProfile(String userId, {String? mobile, UserRole? role});
  Future<Result<void>> createSupplierRecord(String userId);
  Future<Result<void>> createTruckerRecord(String userId);
  Future<Result<Profile>> fetchProfile(String userId);
  Future<Result<void>> signOut();
  Future<Result<void>> recordPrivacyConsent(String userId, String version);
}
```

---

## 5. Privacy Consent

On first sign-up (not returning login), after auth but before dashboard:
- Record privacy consent: `INSERT INTO user_consents (profile_id, consent_type, consent_version)`.
- Update `profiles.privacy_consent_at` and `profiles.privacy_consent_version`.
- This happens silently — no separate screen. The "By continuing, you agree to our Terms" link on the auth screen constitutes consent.

---

## 6. Ban Check Wrapper

Every authenticated screen must be wrapped in a `BanCheckWrapper` widget:
1. On screen build, check `profiles.is_banned` from the user profile provider.
2. If `true` → show full-screen dialog: "Your account has been suspended. Reason: {ban_reason}. Contact support at support@tranzfort.com."
3. Single CTA: "Sign Out" → clears session → navigates to `/auth`.
4. This wrapper is placed in the shell route of GoRouter so it applies to ALL authenticated screens.

---

## 7. Admin Auth (Separate App)

The Admin App uses a different auth flow:
- **Email + Password** login (no Google, no Phone OTP).
- Admin accounts created via `admin-promote-invite` Edge Function by a Super Admin.
- On first login: check `admin_users.auth_user_id` matches current `auth.uid()`.
- If no `admin_users` row → "You are not authorized. Contact your administrator."
- Admin role is read from `admin_users.role` (not from profile or JWT metadata).
- **Single source of truth:** `admin_users.role` column. Not JWT claims, not `raw_user_meta_data`.
