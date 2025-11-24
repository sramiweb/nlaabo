# Nlaabo - Quick Reference: Issues & Fixes

## 🔴 CRITICAL ISSUES (Fix First!)

### Issue #1: Missing MatchRequestsScreen Import
```
File: lib/main.dart
Line: ~30
Fix: Add import 'package:nlaabo/screens/match_requests_screen.dart';
Time: 2 min
```

### Issue #2: Missing Route for Match Requests
```
File: lib/main.dart
Location: GoRouter routes array
Fix: Add route for '/match-requests'
Time: 10 min
```

### Issue #3: Duplicate "Match Type" Field
```
File: lib/screens/create_match_screen.dart
Line: ~380
Fix: Change label from "Match Type" to "Match Recurrence"
Time: 5 min
```

### Issue #4: No Navigation to Match Requests
```
File: lib/widgets/main_layout.dart
Fix: Add navigation button/menu item for match requests
Time: 10 min
```

### Issue #5: Missing Translation Keys
```
Files: assets/translations/en.json, fr.json, ar.json
Fix: Add 11 missing translation keys
Time: 15 min
```

### Issue #6: Poor Error Handling in Match Requests
```
File: lib/screens/match_requests_screen.dart
Fix: Add try-catch, error messages, retry logic
Time: 20 min
```

### Issue #7: Missing Loading States
```
File: lib/screens/match_requests_screen.dart
Fix: Add loading indicators on buttons
Time: 15 min
```

### Issue #8: Hardcoded Strings
```
File: lib/screens/create_match_screen.dart
Fix: Replace hardcoded strings with translation keys
Time: 5 min
```

**Total Critical Fix Time: ~1.5 hours**

---

## 🟡 HIGH PRIORITY FEATURES

| # | Feature | File | Effort | Status |
|---|---------|------|--------|--------|
| 1 | Team Member Management | team_members_management_screen.dart | 4-6h | Missing |
| 2 | Match History & Results | match_history_screen.dart | 5-7h | Missing |
| 3 | Match Cancellation/Reschedule | match_details_screen.dart | 3-4h | Partial |
| 4 | Push Notifications | push_notification_service.dart | 6-8h | Missing |
| 5 | Advanced Search | advanced_search_screen.dart | 4-5h | Missing |
| 6 | Admin Dashboard | admin_dashboard_screen.dart | 6-8h | Partial |
| 7 | Report Management | report_screen.dart | 4-5h | Missing |
| 8 | Notification Center | notifications_screen.dart | 3-4h | Partial |

---

## 📋 MISSING TRANSLATION KEYS

Add these to en.json, fr.json, and ar.json:

- errorLoadingRequests
- errorAcceptingRequest
- errorRejectingRequest
- team_1_required
- team_2_required
- teams_must_be_different
- create_teams_first_message
- match_information
- enter_match_title
- number_of_players_required
- match_type_required

---

## 🔧 FILES TO MODIFY

### Priority 1 (Today)
- lib/main.dart - Add import and route
- lib/screens/create_match_screen.dart - Fix duplicate field
- lib/widgets/main_layout.dart - Add navigation
- assets/translations/*.json - Add keys
- lib/screens/match_requests_screen.dart - Improve error handling

### Priority 2 (This Week)
- lib/screens/team_members_management_screen.dart - Create new
- lib/screens/match_history_screen.dart - Create new
- lib/screens/advanced_search_screen.dart - Create new
- lib/services/push_notification_service.dart - Create new

---

## ✅ VERIFICATION CHECKLIST

After fixes:
- App compiles without errors
- Match requests screen is accessible
- No duplicate fields in create match
- All translation keys present
- Error messages display properly
- Loading states show during operations
- Navigation works correctly

---

## 📊 SUMMARY

| Category | Count | Time |
|----------|-------|------|
| Critical Issues | 8 | 1.5h |
| High Priority Features | 8 | 20-25h |
| Medium Priority Features | 7 | 20-25h |
| Low Priority Features | 4 | 15-20h |
| TOTAL | 27 | 56-71h |

---

**Total Issues Found:** 39
**Total Features Missing:** 19
**Estimated Total Time:** 72-94 hours
