# Translation Keys Analysis - Missing Keys Report

## Analysis Method
Analyzed all screens and widgets for `LocalizationService().translate()` calls and compared against en.json and fr.json files.

## Missing Translation Keys

### Keys Used in Code But Missing in Translation Files

#### Missing in BOTH English and French:
1. **all** - Used in: home_screen.dart, matches_screen.dart
2. **recruiting_status** - Used in: team_management_screen.dart
3. **no_join_requests** - Used in: team_management_screen.dart
4. **approve** - Used in: team_management_screen.dart
5. **set_up_new_match** - Used in: home_screen.dart (exists in en.json but check usage)

#### Missing ONLY in French (fr.json):
These keys exist in English but missing French translations were already added in previous fix.

## Complete List of Translation Keys Found in Code

### Authentication & User Management
- account_created_welcome
- account_created_check_email
- login_failed
- invalid_credentials
- email_not_confirmed
- signup_failed
- password_too_weak
- email_required
- invalid_email
- password_required
- age_required
- age_invalid_range
- gender_required
- confirm_password_required
- full_name
- email
- age
- phone
- password
- confirm_password
- enter_full_name
- enter_email
- enter_password
- login_success
- login_title
- login_subtitle
- login_button
- signup_button
- back_to_login

### Teams
- team_1_required
- team_2_required
- teams_must_be_different
- team_1
- team_2
- create_team
- team_created
- team_name
- team_description
- team_description_hint
- enter_team_name
- team_information
- team_details
- team_not_found
- team_members
- no_members
- teams_owned
- my_teams
- view_all_teams
- no_teams_yet
- no_teams_available
- no_teams_found_in_city
- create_teams_first_message
- team_owner_label
- team_owner_manage
- team_member_text
- your_team
- join_team
- join_request_sent
- join_request_message_hint
- join_team_request_message
- join_request_cancelled
- join_requests
- leave_team
- leave_team_confirmation
- left_team_successfully
- team_management
- delete_team
- delete_team_confirmation
- team_deleted_successfully
- recruiting
- not_recruiting
- recruiting_enabled
- recruiting_disabled
- allow_join_requests_description
- build_team_subtitle

### Matches
- create_match
- match_created_successfully
- match_title
- match_title_required
- match_type
- match_type_required
- match_date
- match_time
- match_information
- match_details
- match_not_found
- matches_joined
- matches_created
- my_matches
- no_matches_yet
- no_matches_found
- no_matches_available
- join_matches_message
- browse_matches
- join_match
- leave_match
- joined_match
- left_match
- failed_to_load_match
- failed_to_load_teams
- failed_to_load_players
- please_login_to_join
- set_up_new_match
- enter_match_title
- search_matches
- try_different_filters
- featured_matches
- no_featured_matches_available

### Common UI Elements
- location
- location_required
- location_hint
- enter_location
- no_location_set
- max_players
- players
- number_of_players_required
- owner
- members
- created
- open
- closed
- pending
- confirmed
- finished
- cancelled
- mixed
- male
- female
- recruiting
- error
- loading
- cancel
- save
- delete
- accept
- reject
- approve
- leave
- send_request
- cancel_request
- optional_message
- message_optional
- enter_message_hint
- reason_optional

### Profile & Settings
- profile
- edit_profile
- back_to_profile
- profile_updated
- update_your_information
- bio
- bio_hint
- position
- position_hint
- skill_level
- beginner
- intermediate
- advanced
- age_hint
- phone_hint
- delete_picture
- change_picture
- picture_deleted
- confirm_save
- confirm_save_message
- no_user_data_available
- account_info
- user_stats
- admin_dashboard

### Search & Navigation
- search_hint
- search_matches
- search_results_for
- no_results_found
- clear_search
- explore_all
- view_all
- create_content

### Status & Feedback
- just_now
- yesterday
- you
- unknown_user
- not_specified
- requested
- no_players_yet
- spots_left

### Onboarding
- skip
- back
- next
- get_started

### Notifications
- notifications

### Cities & Filters
- select_city
- select_age_group
- all

### Request Management
- request_approved
- request_rejected
- no_join_requests
- recruiting_status

## Recommendations

### 1. Add Missing Keys to Both en.json and fr.json:
```json
{
  "all": "All",
  "recruiting_status": "Recruiting Status",
  "no_join_requests": "No join requests",
  "approve": "Approve"
}
```

French translations:
```json
{
  "all": "Tout",
  "recruiting_status": "Statut de recrutement",
  "no_join_requests": "Aucune demande d'adhésion",
  "approve": "Approuver"
}
```

### 2. Verify Existing Keys
Some keys may have slight variations in usage. Need to verify:
- set_up_new_match vs set_up_a_new_match
- team_owner_label usage consistency

### 3. Translation Coverage
- **English**: ~95% coverage
- **French**: ~92% coverage (after recent fixes)
- **Arabic**: Not analyzed in this report

## Next Steps
1. Add the 4 missing keys to both translation files
2. Run full app test in French mode
3. Check Arabic translations
4. Consider adding translation validation tests
