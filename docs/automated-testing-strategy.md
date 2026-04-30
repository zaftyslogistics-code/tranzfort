# Automated Testing Strategy - TranZfort

**Document Version:** 1.0  
**Created:** April 30, 2026  
**Status:** Planning  

---

## Current Testing Infrastructure Analysis

### Existing Test Files

**Unit Tests (test/):**
- `test/rpc_contract_smoke_test.dart` - RPC contract validation
- `test/features/trucker/` - 30+ trucker provider/repository tests
- `test/features/verification/` - 5 verification tests
- `test/reviews/` - 2 review tests
- `test/profile/` - 1 profile test
- `test/core/` - 11 core service tests

**Integration Tests (integration_test/):**
- `u_auth_live_test.dart` - Live auth with real credentials
- `u_verification_live_test.dart` - Verification flow
- `u_ordered_live_flow_test.dart` - Ordered flow tests
- `microscopic_trucker_verification_test.dart` - Trucker verification
- `microscopic_supplier_verification_test.dart` - Supplier verification
- `microscopic_cross_role_flow_test.dart` - Cross-role flows
- `trucker_fleet_live_flow_test.dart` - Fleet management
- `avatar_integration_test.dart` - Avatar upload
- 8 debug/integration tests

### Test Infrastructure

**Environment Files:**
- `.env` - Production Supabase credentials
- `.env.test` - Dummy values for unit tests
- Environment variables: `TZ_SUPPLIER_EMAIL`, `TZ_TRUCKER_EMAIL`, `TZ_TEST_PASSCODE`

**Test Pattern:**
- Unit tests use mock backends
- Integration tests use real Supabase
- Live tests use real credentials from env vars

---

## Testing Strategy Brainstorm

### Strategy 1: Fix & Modernize Existing Tests (Week 1)

**Goal:** Make existing tests pass with current codebase

**Steps:**

1. **Audit Broken Tests**
   ```bash
   cd C:\Users\marte\Desktop\tranzfort.com-v-1.1\TranZfort
   flutter test --no-pub 2>&1 | tee test_audit_output.txt
   flutter drive --target=test/rpc_contract_smoke_test.dart 2>&1 | tee integration_audit_output.txt
   ```

2. **Identify Common Failure Patterns**
   - Import path changes
   - Provider API changes
   - Repository method signature changes
   - Model field changes

3. **Batch Fix Strategy**
   - Fix provider tests first (dependencies)
   - Fix repository tests (data layer)
   - Fix integration tests (end-to-end)
   - Fix RPC contract tests (backend)

4. **Create Test Fix Script**
   ```bash
   # scripts/fix_tests.sh
   flutter pub get
   flutter test test/core/ --reporter expanded
   flutter test test/features/trucker/providers/ --reporter expanded
   flutter test test/features/verification/ --reporter expanded
   flutter test test/rpc_contract_smoke_test.dart --reporter expanded
   ```

**Estimated Time:** 2-3 days

---

### Strategy 2: Test Credentials Management

**Current State:**
- Hardcoded in integration tests
- Environment variables for email/passcode
- No secure storage

**Proposed Solution:**

**Option A: GitHub Secrets + Environment Variables**
```yaml
# .github/workflows/test.yml
env:
  TZ_SUPPLIER_EMAIL: ${{ secrets.TZ_SUPPLIER_EMAIL }}
  TZ_TRUCKER_EMAIL: ${{ secrets.TZ_TRUCKER_EMAIL }}
  TZ_TEST_PASSCODE: ${{ secrets.TZ_TEST_PASSCODE }}
```

**Option B: Supabase Test User Table**
```sql
CREATE TABLE test_credentials (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  role TEXT NOT NULL, -- 'trucker' or 'supplier'
  email TEXT NOT NULL UNIQUE,
  password TEXT NOT NULL,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Insert test credentials
INSERT INTO test_credentials (role, email, password) VALUES
('trucker', 'trucker-test@tranzfort.com', 'TestPass123!'),
('supplier', 'supplier-test@tranzfort.com', 'TestPass123!');
```

**Option C: Flutter Test Configuration**
```dart
// test_config.dart
class TestConfig {
  static const String truckerEmail = String.fromEnvironment('TZ_TRUCKER_EMAIL');
  static const String supplierEmail = String.fromEnvironment('TZ_SUPPLIER_EMAIL');
  static const String testPasscode = String.fromEnvironment('TZ_TEST_PASSCODE');
  
  static bool get hasCredentials => 
    truckerEmail.isNotEmpty && 
    supplierEmail.isNotEmpty && 
    testPasscode.isNotEmpty;
}
```

**Recommendation:** Option B (Supabase test user table) + Option A (GitHub Secrets for local)

---

### Strategy 3: Automated Test Suite Script

**Create:** `scripts/run_all_tests.sh`

```bash
#!/bin/bash

echo "=== TranZfort Automated Test Suite ==="
echo "Date: $(date)"
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to run test and report
run_test() {
  local name=$1
  local command=$2
  
  echo "Running: $name"
  if eval $command; then
    echo -e "${GREEN}✓ $name passed${NC}"
    return 0
  else
    echo -e "${RED}✗ $name failed${NC}"
    return 1
  fi
}

# Counters
PASSED=0
FAILED=0

# Unit Tests
echo "=== Unit Tests ==="
run_test "Core Service Tests" "flutter test test/core/ --reporter expanded" && ((PASSED++)) || ((FAILED++))
run_test "Trucker Provider Tests" "flutter test test/features/trucker/providers/ --reporter expanded" && ((PASSED++)) || ((FAILED++))
run_test "Trucker Repository Tests" "flutter test test/features/trucker/data/ --reporter expanded" && ((PASSED++)) || ((FAILED++))
run_test "Verification Tests" "flutter test test/features/verification/ --reporter expanded" && ((PASSED++)) || ((FAILED++))
run_test "Review Tests" "flutter test test/reviews/ --reporter expanded" && ((PASSED++)) || ((FAILED++))
run_test "Profile Tests" "flutter test test/profile/ --reporter expanded" && ((PASSED++)) || ((FAILED++))

# Integration Tests (only if device connected)
echo ""
echo "=== Integration Tests ==="
if adb devices | grep -q "device$"; then
  run_test "RPC Contract Tests" "flutter drive --target=test/rpc_contract_smoke_test.dart" && ((PASSED++)) || ((FAILED++))
  run_test "Auth Live Tests" "flutter drive --target=integration_test/u_auth_live_test.dart" && ((PASSED++)) || ((FAILED++))
  run_test "Verification Live Tests" "flutter drive --target=integration_test/u_verification_live_test.dart" && ((PASSED++)) || ((FAILED++))
else
  echo -e "${YELLOW}⚠ No device connected. Skipping integration tests.${NC}"
fi

# Summary
echo ""
echo "=== Test Summary ==="
echo -e "${GREEN}Passed: $PASSED${NC}"
echo -e "${RED}Failed: $FAILED${NC}"
echo "Total: $((PASSED + FAILED))"

if [ $FAILED -gt 0 ]; then
  exit 1
fi
```

**Usage:**
```bash
chmod +x scripts/run_all_tests.sh
./scripts/run_all_tests.sh
```

---

### Strategy 4: GitHub Actions CI Pipeline

**Create:** `.github/workflows/test.yml`

```yaml
name: Test Suite

on:
  push:
    branches: [main, feature/*]
  pull_request:
    branches: [main]
  workflow_dispatch:

jobs:
  unit-tests:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v4
      
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.38.7'
          cache: true
          
      - name: Install dependencies
        run: flutter pub get
        
      - name: Run unit tests
        run: flutter test --coverage
        
      - name: Upload coverage
        uses: codecov/codecov-action@v3
        with:
          files: coverage/lcov.info

  integration-tests:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v4
      
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.38.7'
          cache: true
          
      - name: Install dependencies
        run: flutter pub get
        
      - name: Run RPC contract tests
        run: flutter test test/rpc_contract_smoke_test.dart
        env:
          SUPABASE_URL: ${{ secrets.SUPABASE_URL }}
          SUPABASE_ANON_KEY: ${{ secrets.SUPABASE_ANON_KEY }}
          
      - name: Run integration tests
        run: flutter test test/integration/
        env:
          TZ_SUPPLIER_EMAIL: ${{ secrets.TZ_SUPPLIER_EMAIL }}
          TZ_TRUCKER_EMAIL: ${{ secrets.TZ_TRUCKER_EMAIL }}
          TZ_TEST_PASSCODE: ${{ secrets.TZ_TEST_PASSCODE }}

  build-check:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v4
      
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.38.7'
          cache: true
          
      - name: Install dependencies
        run: flutter pub get
        
      - name: Flutter analyze
        run: flutter analyze
        
      - name: Build APK
        run: flutter build apk --release
```

---

### Strategy 5: Test Data Management

**Problem:** Tests need consistent test data

**Solution:** Test Data Seeding Script

**Create:** `scripts/seed_test_data.sh`

```bash
#!/bin/bash

SUPABASE_URL="${SUPABASE_URL:-https://jgtgdfhdtjhidywpautk.supabase.co}"
SUPABASE_ANON_KEY="${SUPABASE_ANON_KEY}"

echo "Seeding test data..."

# Create test users via Supabase Auth
curl -X POST "$SUPABASE_URL/auth/v1/signup" \
  -H "apikey: $SUPABASE_ANON_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "trucker-test@tranzfort.com",
    "password": "TestPass123!"
  }'

curl -X POST "$SUPABASE_URL/auth/v1/signup" \
  -H "apikey: $SUPABASE_ANON_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "supplier-test@tranzfort.com",
    "password": "TestPass123!"
  }'

# Insert test loads
# Insert test trips
# Insert test reviews

echo "Test data seeded successfully"
```

---

### Strategy 6: TTS Voice Testing Automation

**Create:** `scripts/test_tts_voices.sh`

```bash
#!/bin/bash

echo "=== TTS Voice Testing ==="

# Test voice discovery
echo "Testing voice discovery..."
adb shell am instrument -w -e class com.tranzfort.tranzfort.TTSVoiceDiscoveryTest \
  com.tranzfort.tranzfort.test/androidx.test.runner.AndroidJUnitRunner

# Test voice persistence
echo "Testing voice persistence..."
adb shell am instrument -w -e class com.tranzfort.tranzfort.TTSVoicePersistenceTest \
  com.tranzfort.tranzfort.test/androidx.test.runner.AndroidJUnitRunner

# Test voice fallback
echo "Testing voice fallback..."
adb shell am instrument -w -e class com.tranzfort.tranzfort.TTSVoiceFallbackTest \
  com.tranzfort.tranzfort.test/androidx.test.runner.AndroidJUnitRunner

# Test speakSummary with persisted voice
echo "Testing speakSummary..."
adb shell am instrument -w -e class com.tranzfort.tranzfort.TTSSpeakSummaryTest \
  com.tranzfort.tranzfort.test/androidx.test.runner.AndroidJUnitRunner

echo "TTS voice tests complete"
```

---

### Strategy 7: E2E Flow Testing with Credentials

**Create:** `integration_test/e2e_trucker_flow_test.dart`

```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('E2E Trucker Flow', () {
    late SupabaseClient client;

    setUpAll(() async {
      await dotenv.load(fileName: '.env');
      
      await Supabase.initialize(
        url: dotenv.env['SUPABASE_URL']!,
        anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
      );

      client = Supabase.instance.client;
    });

    testWidgets('Complete trucker journey: login → find load → book load → view trip', (tester) async {
      // Step 1: Login as trucker
      final truckerEmail = dotenv.env['TZ_TRUCKER_EMAIL'] ?? '';
      final testPasscode = dotenv.env['TZ_TEST_PASSCODE'] ?? '';
      
      await client.auth.signInWithPassword(
        email: truckerEmail,
        password: testPasscode,
      );

      // Step 2: Navigate to marketplace
      // Step 3: Find a load
      // Step 4: Book the load
      // Step 5: View the trip
      // Step 6: Logout

      await client.auth.signOut();
    });
  });
}
```

---

### Strategy 8: Test Dashboard

**Create:** `scripts/test_dashboard.sh`

```bash
#!/bin/bash

echo "=== TranZfort Test Dashboard ==="
echo ""

# Get test results
UNIT_TESTS=$(flutter test --no-pub 2>&1 | grep "All tests passed" | wc -l)
INTEGRATION_TESTS=$(flutter test integration_test/ --no-pub 2>&1 | grep "All tests passed" | wc -l)
ANALYZE_ERRORS=$(flutter analyze 2>&1 | grep "error •" | wc -l)

# Display results
echo "Unit Tests: $UNIT_TESTS"
echo "Integration Tests: $INTEGRATION_TESTS"
echo "Analyze Errors: $ANALYZE_ERRORS"
echo ""

# Status
if [ $UNIT_TESTS -gt 0 ] && [ $INTEGRATION_TESTS -gt 0 ] && [ $ANALYZE_ERRORS -eq 0 ]; then
  echo "✅ All checks passed"
else
  echo "❌ Some checks failed"
fi
```

---

## Implementation Plan

### Phase 1: Fix Existing Tests (Week 1)
1. Audit all test files
2. Identify breaking changes
3. Fix imports and dependencies
4. Update test data models
5. Run full test suite
6. Document fixes

### Phase 2: Credential Management (Week 1)
1. Create Supabase test user table
2. Add test credentials to GitHub Secrets
3. Update .env.test with proper config
4. Create TestConfig utility
5. Update integration tests to use new config

### Phase 3: Automation Scripts (Week 2)
1. Create run_all_tests.sh
2. Create seed_test_data.sh
3. Create test_dashboard.sh
4. Create TTS voice test script
5. Test all scripts locally

### Phase 4: CI Pipeline (Week 2)
1. Create GitHub Actions workflow
2. Add secrets to GitHub
3. Test CI pipeline
4. Add coverage reporting
5. Add build verification

### Phase 5: E2E Tests (Week 3)
1. Create E2E flow tests
2. Add TTS voice E2E tests
3. Add cross-role flow tests
4. Test on real devices
5. Document test scenarios

---

## Test Categories & Priorities

### P0 - Critical (Must Pass Before Release)
- RPC contract tests
- Auth tests
- Core service tests
- Build verification

### P1 - High (Important Features)
- Trucker provider tests
- Supplier provider tests
- Verification tests
- Marketplace tests

### P2 - Medium (Nice to Have)
- UI widget tests
- Integration tests
- E2E flow tests
- TTS voice tests

### P3 - Low (Future)
- Performance tests
- Accessibility tests
- Visual regression tests
- Localization tests

---

## Success Metrics

- **Test Coverage:** Target 70%+ code coverage
- **Test Pass Rate:** Target 95%+ pass rate
- **Test Execution Time:** Unit tests < 5 min, Integration tests < 10 min
- **CI Pipeline:** All tests pass on every PR
- **Flaky Tests:** < 5% flaky test rate

---

## Test Credentials

**Supplier Test User:**
- Email: testa@example.com
- User UID: 077679ce-f53f-45a8-9f3a-90137e227d6a
- Password: Tabish%%Khan721

**Trucker Test User:**
- Email: testt@example.com
- User UID: b11b7793-0c15-459e-81dc-57ddf72f2869
- Password: Tabish%%Khan721

**Environment Variables:**
```bash
TZ_SUPPLIER_EMAIL=testa@example.com
TZ_TRUCKER_EMAIL=testt@example.com
TZ_TEST_PASSCODE=Tabish%%Khan721
TZ_SUPPLIER_UID=077679ce-f53f-45a8-9f3a-90137e227d6a
TZ_TRUCKER_UID=b11b7793-0c15-459e-81dc-57ddf72f2869
```

---

## Next Steps

1. ✅ **Share test credentials** (trucker and supplier email/passcode) - DONE
2. **Audit existing tests** to identify breaking changes
3. **Fix critical tests** first (RPC, auth, core services)
4. **Set up credential management** (GitHub Secrets + Supabase test users)
5. **Create automation scripts** for local testing
6. **Implement CI pipeline** for automated testing

---

## Questions for User

1. ✅ What are the current test credentials (trucker/supplier email and password)? - PROVIDED
2. Should we create dedicated test users in Supabase, or use existing users?
3. What is the priority - fixing existing tests or creating new automated tests?
4. Do you have a preference for CI platform (GitHub Actions, GitLab CI, CircleCI)?
5. Should we focus on unit tests, integration tests, or E2E tests first?
