# Navigation Implementation Plan

**Date:** April 20, 2026
**Branch:** feature/navigation-planc
**Commit:** fd46665
**Purpose:** Phased implementation plan for remaining navigation work (Deliverable 8.5 from TODO-16-april.md)

---

## Executive Summary

This document provides a phased implementation plan for remaining navigation enhancements. Note that **all critical work is already complete** (Plan C). This plan covers **optional low-priority enhancements** only.

**Critical Work Status:** ✅ COMPLETE
**Optional Enhancements Status:** NOT STARTED
**Overall Risk:** LOW
**Go/No-Go:** ✅ GO (for production deployment)

---

## 1. Implementation Phases

### Phase 1: Code Cleanup (Optional)

**Scope:** Remove unused code

**Tasks:**
1. Remove unused ShellDashboardScreen
2. Remove any unused navigation imports
3. Clean up commented-out navigation code

**Dependencies:** None

**Effort Estimate:** 1-2 hours

**Success Criteria:**
- Unused screen removed
- Code compiles without errors
- Flutter analyze passes

**Rollback Criteria:**
- Build fails
- Runtime errors

---

### Phase 2: PopScope Enhancement (Optional)

**Scope:** Add PopScope to screens that might have unsaved changes

**Tasks:**
1. Add PopScope to ReportIssueScreen
2. Add PopScope to CreateSupportTicketScreen
3. Add PopScope to detail screens if they have editable fields

**Dependencies:** None

**Effort Estimate:** 8-12 hours

**Success Criteria:**
- PopScope added to target screens
- Unsaved changes confirmation works
- Flutter analyze passes
- Manual testing passes

**Rollback Criteria:**
- PopScope breaks navigation
- Confirmation dialogs don't work
- User complaints

---

### Phase 3: Unit Testing (Optional)

**Scope:** Add unit tests for navigation logic

**Tasks:**
1. Add unit tests for RouteMetadataHelper
2. Add unit tests for NavigationService
3. Add unit tests for MonitoringService
4. Add unit tests for PopScope patterns

**Dependencies:** None

**Effort Estimate:** 12-16 hours

**Success Criteria:**
- Unit tests pass
- Test coverage > 80%
- CI/CD integration

**Rollback Criteria:**
- Tests are flaky
- Tests slow down CI/CD

---

### Phase 4: Navigation Analytics (Optional)

**Scope:** Add navigation analytics

**Tasks:**
1. Add navigation event tracking to MonitoringService
2. Add analytics to NavigationService
3. Create analytics dashboard
4. Document analytics metrics

**Dependencies:** Phase 3 (unit tests)

**Effort Estimate:** 8-12 hours

**Success Criteria:**
- Analytics data collected
- Dashboard displays metrics
- No performance impact

**Rollback Criteria:**
- Performance degradation
- Analytics data inaccurate

---

### Phase 5: Performance Monitoring (Optional)

**Scope:** Add navigation performance monitoring

**Tasks:**
1. Add timing metrics to NavigationService
2. Add slow navigation detection
3. Add performance alerts
4. Document performance baselines

**Dependencies:** Phase 4 (analytics)

**Effort Estimate:** 6-8 hours

**Success Criteria:**
- Performance metrics collected
- Slow navigation detected
- No false positives

**Rollback Criteria:**
- Performance monitoring degrades performance
- Too many false alerts

---

### Phase 6: Lint Rules (Optional)

**Scope:** Add lint rules for navigation patterns

**Tasks:**
1. Add lint rule for context.go vs context.push
2. Add lint rule for PopScope usage
3. Add lint rule for metadata adherence
4. Document lint rules

**Dependencies:** None

**Effort Estimate:** 4-6 hours

**Success Criteria:**
- Lint rules work correctly
- No false positives
- Developers follow rules

**Rollback Criteria:**
- Lint rules too strict
- Too many false positives
- Developer productivity impacted

---

## 2. Phase Details

### Phase 1: Code Cleanup

**Tasks Breakdown:**

**Task 1.1: Remove ShellDashboardScreen**
- File: `lib/src/features/shell/presentation/shell_dashboard_screen.dart`
- Action: Delete file
- Verification: Build succeeds
- Effort: 30 minutes

**Task 1.2: Remove unused imports**
- Search for unused navigation imports
- Action: Remove unused imports
- Verification: Flutter analyze passes
- Effort: 30 minutes

**Task 1.3: Clean up commented code**
- Search for commented navigation code
- Action: Remove commented code
- Verification: Build succeeds
- Effort: 30 minutes

**Total Effort:** 1.5 hours

**Risk Level:** LOW

---

### Phase 2: PopScope Enhancement

**Tasks Breakdown:**

**Task 2.1: Add PopScope to ReportIssueScreen**
- File: `lib/src/features/support/presentation/report_issue_screen.dart`
- Action: Add PopScope with unsaved changes confirmation
- Pattern: Pattern 2 (method call)
- Verification: Manual testing
- Effort: 2 hours

**Task 2.2: Add PopScope to CreateSupportTicketScreen**
- File: `lib/src/features/support/presentation/create_support_ticket_screen.dart`
- Action: Add PopScope with unsaved changes confirmation
- Pattern: Pattern 2 (method call)
- Verification: Manual testing
- Effort: 2 hours

**Task 2.3: Assess detail screens for PopScope**
- Screens: Load detail, trip detail (4 screens)
- Action: Assess if editable fields exist
- If yes: Add PopScope (2 hours each)
- If no: Document as read-only
- Verification: Manual testing
- Effort: 4-8 hours

**Total Effort:** 8-12 hours

**Risk Level:** LOW

---

### Phase 3: Unit Testing

**Tasks Breakdown:**

**Task 3.1: RouteMetadataHelper tests**
- File: `test/core/navigation/route_metadata_helper_test.dart`
- Action: Add unit tests for all methods
- Coverage: getType, shouldShowBackArrow, requirePopScope, getTestId
- Effort: 4 hours

**Task 3.2: NavigationService tests**
- File: `test/core/navigation/navigation_service_test.dart`
- Action: Add unit tests for navigation methods
- Coverage: navigate, push, pop, replace, goNamed
- Effort: 4 hours

**Task 3.3: MonitoringService tests**
- File: `test/core/services/monitoring_service_test.dart`
- Action: Add unit tests for event tracking
- Coverage: logRouteTransition, logBackButtonPress, etc.
- Effort: 4 hours

**Task 3.4: PopScope pattern tests**
- File: Create widget tests for PopScope patterns
- Action: Test both patterns (state variable, method call)
- Effort: 4 hours

**Total Effort:** 16 hours

**Risk Level:** LOW

---

### Phase 4: Navigation Analytics

**Tasks Breakdown:**

**Task 4.1: Add analytics to MonitoringService**
- Action: Add analytics event type
- Action: Add analytics logging
- Effort: 3 hours

**Task 4.2: Add analytics to NavigationService**
- Action: Track navigation patterns
- Action: Track navigation performance
- Effort: 3 hours

**Task 4.3: Create analytics dashboard**
- Action: Create simple analytics view
- Action: Display key metrics
- Effort: 4 hours

**Task 4.4: Document analytics metrics**
- Action: Document what metrics are tracked
- Action: Document how to interpret metrics
- Effort: 2 hours

**Total Effort:** 12 hours

**Risk Level:** LOW

---

### Phase 5: Performance Monitoring

**Tasks Breakdown:**

**Task 5.1: Add timing metrics**
- Action: Track navigation duration
- Action: Track route transition time
- Effort: 3 hours

**Task 5.2: Add slow navigation detection**
- Action: Alert if navigation > 500ms
- Action: Log slow navigation events
- Effort: 2 hours

**Task 5.3: Add performance alerts**
- Action: Alert on performance degradation
- Action: Alert on error rate increase
- Effort: 2 hours

**Task 5.4: Document baselines**
- Action: Document performance baselines
- Action: Document alert thresholds
- Effort: 1 hour

**Total Effort:** 8 hours

**Risk Level:** LOW

---

### Phase 6: Lint Rules

**Tasks Breakdown:**

**Task 6.1: Add context.go vs context.push lint rule**
- Action: Create custom lint rule
- Action: Warn on incorrect usage
- Effort: 2 hours

**Task 6.2: Add PopScope usage lint rule**
- Action: Create custom lint rule
- Action: Warn on missing PopScope where needed
- Effort: 2 hours

**Task 6.3: Add metadata adherence lint rule**
- Action: Create custom lint rule
- Action: Warn on metadata mismatches
- Effort: 2 hours

**Task 6.4: Document lint rules**
- Action: Document all lint rules
- Action: Document how to fix violations
- Effort: 1 hour

**Total Effort:** 7 hours

**Risk Level:** LOW

---

## 3. Implementation Schedule

### 3.1 Recommended Schedule

**Week 1:** Phase 1 (Code Cleanup)
- Effort: 1.5 hours
- Risk: LOW
- Priority: LOW

**Week 2-3:** Phase 2 (PopScope Enhancement)
- Effort: 8-12 hours
- Risk: LOW
- Priority: LOW

**Week 4-5:** Phase 3 (Unit Testing)
- Effort: 16 hours
- Risk: LOW
- Priority: MEDIUM

**Week 6:** Phase 4 (Navigation Analytics)
- Effort: 12 hours
- Risk: LOW
- Priority: LOW

**Week 7:** Phase 5 (Performance Monitoring)
- Effort: 8 hours
- Risk: LOW
- Priority: LOW

**Week 8:** Phase 6 (Lint Rules)
- Effort: 7 hours
- Risk: LOW
- Priority: LOW

**Total Schedule:** 8 weeks
**Total Effort:** 52.5-56.5 hours

---

### 3.2 Alternative: Minimal Implementation

**Option:** Only implement Phase 1 (Code Cleanup)

**Effort:** 1.5 hours
**Risk:** LOW
**Priority:** LOW
**Timeline:** 1 day

**Rationale:**
- Critical work is complete
- Optional enhancements can wait
- Code cleanup is quick win

---

## 4. Success Criteria

### 4.1 Overall Success Criteria

**For Production Deployment (Current State):**
- ✅ All critical navigation features working
- ✅ No breaking changes
- ✅ No critical bugs
- ✅ Documentation complete
- ✅ Rollback strategy in place

**For Optional Enhancements:**
- ✅ Flutter analyze passes
- ✅ Manual testing passes
- ✅ No performance degradation
- ✅ No user complaints

---

### 5. Rollback Criteria

### 5.1 Per-Phase Rollback Criteria

**Phase 1 Rollback:**
- Build fails
- Runtime errors
- Flutter analyze fails

**Phase 2 Rollback:**
- PopScope breaks navigation
- Confirmation dialogs don't work
- User complaints

**Phase 3 Rollback:**
- Tests are flaky
- Tests slow down CI/CD

**Phase 4 Rollback:**
- Performance degradation
- Analytics data inaccurate

**Phase 5 Rollback:**
- Performance monitoring degrades performance
- Too many false alerts

**Phase 6 Rollback:**
- Lint rules too strict
- Too many false positives
- Developer productivity impacted

---

### 5.2 Overall Rollback Strategy

**If multiple phases fail:**
1. Rollback to last known good checkpoint
2. Re-evaluate priorities
3. Adjust implementation plan
4. Get team approval before proceeding

**Available Checkpoints:**
- `checkpoint-audit-tasks-before` - Before audit tasks
- `checkpoint-bug-fixes-after` - After bug fixes
- `v1-planc-week3-complete` - After Plan C

**Primary Fallback:** `feature/codebase-refactoring` at commit `0587f23`

---

## 6. Resource Requirements

### 6.1 Team Requirements

**For Production Deployment (Current State):**
- 0 developers (already complete)

**For Optional Enhancements:**
- 1 developer (part-time)
- 2-3 developers (full-time) if parallel implementation

---

### 6.2 Infrastructure Requirements

**For Production Deployment (Current State):**
- No additional infrastructure needed

**For Optional Enhancements:**
- Analytics dashboard (if Phase 4 implemented)
- CI/CD for tests (if Phase 3 implemented)

---

## 7. Recommendations

### 7.1 Immediate Actions

**Recommended:** Deploy to production as-is

**Rationale:**
- All critical work complete
- Navigation working correctly
- No critical issues
- Low risk profile
- Good documentation
- Rollback strategy in place

---

### 7.2 Future Actions (Optional)

**Option A:** Implement Phase 1 only (code cleanup)
- Quick win
- Low risk
- 1.5 hours

**Option B:** Implement all phases
- Comprehensive enhancement
- 8 weeks timeline
- Low risk
- 52-56 hours

**Option C:** Defer all optional work
- Focus on other features
- Revisit navigation later
- Zero risk

**Recommendation:** Option A (implement Phase 1 only)

---

## 8. Conclusion

### 8.1 Implementation Plan Summary

**Status:** READY FOR PRODUCTION ✅

**Critical Work:** COMPLETE
- ✅ Route metadata system
- ✅ Shell PopScope
- ✅ Form screen PopScope
- ✅ Back arrow system
- ✅ Navigation service
- ✅ Monitoring service
- ✅ Documentation
- ✅ Bug fixes

**Optional Work:** NOT STARTED
- Phase 1: Code cleanup (1.5 hours)
- Phase 2: PopScope enhancement (8-12 hours)
- Phase 3: Unit testing (16 hours)
- Phase 4: Analytics (12 hours)
- Phase 5: Performance monitoring (8 hours)
- Phase 6: Lint rules (7 hours)

**Total Optional Effort:** 52.5-56.5 hours

---

### 8.2 Go/No-Go Decision

**Recommendation:** ✅ GO FOR PRODUCTION

**Rationale:**
- All critical work complete
- Navigation working correctly
- No breaking changes
- Low risk profile
- Good documentation
- Rollback strategy in place
- Optional work can be done later

---

## Sign-off

**Plan Date:** April 20, 2026
**Plan Status:** ✅ COMPLETE (Section 8.5 - Implementation Plan)
**Go/No-Go:** ✅ GO FOR PRODUCTION
**Next Steps:** Deploy to production, defer optional work
