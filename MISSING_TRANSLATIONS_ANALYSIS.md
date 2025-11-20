# Missing Translation Keys Analysis

## Summary
This document lists all hardcoded English strings found in screen files that need translation keys.

---

## 1. **admin_dashboard_screen.dart**

### Missing Keys:
- `failed_to_load_data` - "Failed to load data"
- `user_deleted_successfully` - "User deleted successfully"
- `failed_to_delete_user` - "Failed to delete user"
- `match_closed_successfully` - "Match closed successfully"
- `failed_to_close_match` - "Failed to close match"
- `admin_dashboard` - "Admin Dashboard" (already exists)
- `no_users_found` - "No users found"
- `position_label` - "Position:" (for "Position: {position}")
- `no_matches_found` - "No matches found" (already exists)
- `delete_user` - "Delete User"
- `close_match` - "Close Match"

---

## 2. **auth_callback_screen.dart**

### Missing Keys:
- `authentication_error` - "Authentication error"

---

## 3. **auth_landing_screen.dart**

### Status: ✅ All translated
- Uses language names directly (English, Français, العربية) which is correct

---

## 4. **create_match_screen.dart**

### Missing Keys:
- ✅ `loading_teams` - Already exists

---

## 5. **create_team_screen.dart**

### Missing Keys:
- `error_picking_image` - "Error picking image"
- `logo_selected_upload_disabled` - "Logo selected (upload disabled)"
- `logo_uploaded_successfully` - "Logo uploaded successfully"
- `error_uploading_image` - "Error uploading image"
- `team_name_already_exists` - "You already have a team with this name"

---

## 6. **edit_profile_screen.dart**

### Missing Keys:
- `failed_to_load_profile_data` - "Failed to load profile data. Please try again."

---

## 7. **home_screen.dart**

### Missing Keys:
- `location_picker_coming_soon` - "Location picker coming soon"
- `category_picker_coming_soon` - "Category picker coming soon"

---

## 8. **matches_screen.dart**

### Missing Keys:
- `select_match_type` - "Select Match Type"
- `select_duration` - "Select Duration"
- `select_status` - "Select Status"
- `select_city` - "Select City"

---

## 9. **match_requests_screen.dart**

### Missing Keys:
- `match_request_accepted` - "Match request accepted!"
- `match_request_declined` - "Match request declined"
- `match_requests` - "Match Requests"
- `no_pending_match_requests` - "No pending match requests"
- `match_vs` - "Match vs" (for "Match vs {team}")
- `unknown_team` - "Unknown Team"

---

## 10. **my_matches_screen.dart**

### Missing Keys:
- `failed_to_load_matches` - "Failed to load matches"

---

## 11. **notifications_screen.dart**

### Missing Keys:
- `failed_to_mark_as_read` - "Failed to mark as read"

---

## 12. **profile_screen.dart**

### Missing Keys:
- ✅ `loading` - Already exists
- ✅ `retry` - Already exists
- `using_cached_profile_data` - "Using cached profile data. Some information may be outdated."

---

## 13. **signup_screen.dart**

### Missing Keys:
- `connection_issue` - "Connection Issue"
- `technical_details` - "Technical Details"
- `save_for_later` - "Save for Later"
- `debug` - "Debug"
- `signup_info_saved_offline` - "Signup information saved! We'll process it when you're back online."
- `account_created_welcome_short` - "Account created successfully! Welcome!"
- `already_signed_in` - "Already Signed In"
- `continue_to_app` - "Continue to App"
- `logout_and_create_new` - "Logout and Create New Account"
- ✅ `male` - Already exists
- ✅ `female` - Already exists

---

## 14. **team_details_screen.dart**

### Missing Keys:
- `error_accepting_request` - "Error accepting request"
- `error_rejecting_request` - "Error rejecting request"

---

## 15. **settings_screen.dart**

### Status: ✅ Needs verification (not in search results)

---

## Translation Keys Summary

### Total Missing Keys: **42**

### Priority Levels:

#### 🔴 HIGH PRIORITY (User-facing errors and messages):
1. `failed_to_load_data`
2. `authentication_error`
3. `failed_to_load_profile_data`
4. `failed_to_load_matches`
5. `error_accepting_request`
6. `error_rejecting_request`
7. `failed_to_mark_as_read`

#### 🟡 MEDIUM PRIORITY (Success messages and labels):
8. `user_deleted_successfully`
9. `match_closed_successfully`
10. `logo_uploaded_successfully`
11. `match_request_accepted`
12. `match_request_declined`
13. `account_created_welcome_short`

#### 🟢 LOW PRIORITY (Admin, debug, and coming soon features):
14. `admin_dashboard`
15. `no_users_found`
16. `no_matches_found`
17. `delete_user`
18. `close_match`
19. `location_picker_coming_soon`
20. `category_picker_coming_soon`
21. `debug`
22. `technical_details`

---

## Recommended Action Plan

1. **Add all missing keys to translation files** (en.json, fr.json, ar.json)
2. **Update screen files** to use `LocalizationService().translate(key)`
3. **Test each screen** in all three languages
4. **Verify error messages** display correctly in production

---

## Notes

- Some keys like `loading`, `retry`, `male`, `female` already exist
- Admin dashboard may need separate translation file if it's admin-only
- Consider adding context to generic keys (e.g., `error_accepting_request` vs `error`)
