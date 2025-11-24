# Nlaabo - Detailed Fix Guide

## Quick Reference

| Issue | File | Line | Severity | Time |
|-------|------|------|----------|------|
| Duplicate Match Type Field | create_match_screen.dart | ~380 | 🔴 Critical | 5 min |
| Missing Route | main.dart | - | 🔴 Critical | 10 min |
| Missing Import | main.dart | - | 🔴 Critical | 2 min |
| Missing Navigation | main_layout.dart | - | 🔴 Critical | 10 min |
| Missing Translation Keys | assets/translations/*.json | - | 🟡 High | 15 min |
| Error Handling | match_requests_screen.dart | - | 🟡 High | 20 min |
| Loading States | match_requests_screen.dart | - | 🟡 High | 15 min |

---

## FIX #1: Add Missing Import (2 minutes)

**File:** `lib/main.dart`

**Add this import at the top with other screen imports:**
```dart
import 'package:nlaabo/screens/match_requests_screen.dart';
```

**Location:** After line 30 (with other screen imports)

---

## FIX #2: Add Missing Route (10 minutes)

**File:** `lib/main.dart`

**Add this route in the GoRouter configuration (after `/notifications` route):**
```dart
GoRoute(
  path: '/match-requests',
  builder: (context, state) => const MainLayout(child: MatchRequestsScreen()),
  pageBuilder: (context, state) => CustomTransitionPage(
    key: state.pageKey,
    child: const MainLayout(child: MatchRequestsScreen()),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return PageTransitions.slideFadeTransition(
        context: context,
        animation: animation,
        child: child,
      );
    },
  ),
),
```

**Also update the `_isValidRoute` function to include:**
```dart
'/match-requests'
```

---

## FIX #3: Fix Duplicate Match Type Field (5 minutes)

**File:** `lib/screens/create_match_screen.dart`

**Around line 380, change:**
```dart
Text(
  'Match Type',  // ❌ WRONG - This is the second "Match Type"
  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
    fontWeight: FontWeight.w600,
    color: context.colors.textPrimary,
  ),
),
```

**To:**
```dart
Text(
  'Match Recurrence',  // ✅ CORRECT
  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
    fontWeight: FontWeight.w600,
    color: context.colors.textPrimary,
  ),
),
```

**Also update the dropdown label:**
```dart
decoration: InputDecoration(
  labelText: 'One-time or Recurring',  // ✅ More descriptive
  border: InputBorder.none,
  prefixIcon: Icon(Icons.repeat, color: context.colors.primary),
  // ... rest of decoration
),
```

---

## FIX #4: Add Navigation to Match Requests (10 minutes)

**File:** `lib/widgets/main_layout.dart`

**Add a navigation item for match requests in the bottom navigation or drawer:**

```dart
// In the navigation menu/drawer, add:
ListTile(
  leading: const Icon(Icons.mail),
  title: const Text('Match Requests'),
  onTap: () {
    context.go('/match-requests');
    Navigator.pop(context); // Close drawer if applicable
  },
),
```

**Or in bottom navigation bar:**
```dart
BottomNavigationBarItem(
  icon: const Icon(Icons.mail),
  label: 'Requests',
),
```

---

## FIX #5: Add Missing Translation Keys (15 minutes)

**Files:** 
- `assets/translations/en.json`
- `assets/translations/fr.json`
- `assets/translations/ar.json`

**Add these keys to each file:**

### English (en.json)
```json
{
  "errorLoadingRequests": "Failed to load match requests",
  "errorAcceptingRequest": "Failed to accept match request",
  "errorRejectingRequest": "Failed to reject match request",
  "team_1_required": "Please select Team 1",
  "team_2_required": "Please select Team 2",
  "teams_must_be_different": "Team 1 and Team 2 must be different",
  "create_teams_first_message": "Create teams first to organize matches",
  "match_information": "Match Information",
  "enter_match_title": "Enter match title",
  "number_of_players_required": "Number of players required",
  "match_type_required": "Please select a match type"
}
```

### French (fr.json)
```json
{
  "errorLoadingRequests": "Impossible de charger les demandes de match",
  "errorAcceptingRequest": "Impossible d'accepter la demande de match",
  "errorRejectingRequest": "Impossible de rejeter la demande de match",
  "team_1_required": "Veuillez sélectionner l'équipe 1",
  "team_2_required": "Veuillez sélectionner l'équipe 2",
  "teams_must_be_different": "L'équipe 1 et l'équipe 2 doivent être différentes",
  "create_teams_first_message": "Créez d'abord des équipes pour organiser des matchs",
  "match_information": "Informations sur le match",
  "enter_match_title": "Entrez le titre du match",
  "number_of_players_required": "Nombre de joueurs requis",
  "match_type_required": "Veuillez sélectionner un type de match"
}
```

### Arabic (ar.json)
```json
{
  "errorLoadingRequests": "فشل تحميل طلبات المباراة",
  "errorAcceptingRequest": "فشل قبول طلب المباراة",
  "errorRejectingRequest": "فشل رفض طلب المباراة",
  "team_1_required": "يرجى تحديد الفريق 1",
  "team_2_required": "يرجى تحديد الفريق 2",
  "teams_must_be_different": "يجب أن يكون الفريق 1 والفريق 2 مختلفين",
  "create_teams_first_message": "أنشئ فرقًا أولاً لتنظيم المباريات",
  "match_information": "معلومات المباراة",
  "enter_match_title": "أدخل عنوان المباراة",
  "number_of_players_required": "عدد اللاعبين المطلوبين",
  "match_type_required": "يرجى تحديد نوع المباراة"
}
```

---

## FIX #6: Improve Match Requests Screen (20 minutes)

**File:** `lib/screens/match_requests_screen.dart`

**Replace the entire file with:**

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/match.dart';
import '../services/api_service.dart';
import '../services/localization_service.dart';
import '../constants/translation_keys.dart';
import '../widgets/directional_icon.dart';

class MatchRequestsScreen extends StatefulWidget {
  const MatchRequestsScreen({super.key});

  @override
  State<MatchRequestsScreen> createState() => _MatchRequestsScreenState();
}

class _MatchRequestsScreenState extends State<MatchRequestsScreen> {
  final ApiService _apiService = ApiService();
  List<Match> _pendingRequests = [];
  bool _isLoading = true;
  final Map<String, bool> _processingIds = {};

  @override
  void initState() {
    super.initState();
    _loadPendingRequests();
  }

  Future<void> _loadPendingRequests() async {
    setState(() => _isLoading = true);
    try {
      final requests = await _apiService.getMyPendingMatchRequests();
      if (mounted) {
        setState(() {
          _pendingRequests = requests;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              LocalizationService().translate('errorLoadingRequests') ?? 
              'Failed to load match requests: $e'
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleAccept(Match match) async {
    setState(() => _processingIds[match.id] = true);
    try {
      await _apiService.acceptMatchRequest(match.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Match request accepted!'),
            backgroundColor: Colors.green,
          ),
        );
        _loadPendingRequests();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              LocalizationService().translate('errorAcceptingRequest') ?? 
              'Failed to accept request: $e'
            ),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _processingIds[match.id] = false);
      }
    }
  }

  Future<void> _handleReject(Match match) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Match Request'),
        content: const Text('Are you sure you want to reject this match request?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reject', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _processingIds[match.id] = true);
    try {
      await _apiService.rejectMatchRequest(match.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Match request declined'),
            backgroundColor: Colors.orange,
          ),
        );
        _loadPendingRequests();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              LocalizationService().translate('errorRejectingRequest') ?? 
              'Failed to reject request: $e'
            ),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _processingIds[match.id] = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Match Requests'),
        leading: IconButton(
          icon: const DirectionalIcon(icon: Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _pendingRequests.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.mail_outline,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No pending match requests',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Match requests from other teams will appear here',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadPendingRequests,
                  child: ListView.builder(
                    itemCount: _pendingRequests.length,
                    itemBuilder: (context, index) {
                      final match = _pendingRequests[index];
                      final isProcessing = _processingIds[match.id] ?? false;
                      
                      return Card(
                        margin: const EdgeInsets.all(8),
                        child: ListTile(
                          title: Text(
                            'Match vs ${match.team1Name ?? "Unknown Team"}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 8),
                              Text(
                                'Date: ${match.matchDate.toLocal().toString().split('.')[0]}',
                              ),
                              Text(
                                'Location: ${match.location}',
                              ),
                            ],
                          ),
                          trailing: isProcessing
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.check, color: Colors.green),
                                      onPressed: () => _handleAccept(match),
                                      tooltip: 'Accept',
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.close, color: Colors.red),
                                      onPressed: () => _handleReject(match),
                                      tooltip: 'Reject',
                                    ),
                                  ],
                                ),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadPendingRequests,
        tooltip: 'Refresh',
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
```

---

## FIX #7: Add Hardcoded String Fixes (5 minutes)

**File:** `lib/screens/create_match_screen.dart`

**Replace hardcoded strings with translation keys:**

```dart
// Before:
ElevatedButton.icon(
  onPressed: () => context.go('/teams/create'),
  icon: const Icon(Icons.add),
  label: Text(LocalizationService().translate('create_team') ?? 'Create Team'),
  // ...
),

// After:
ElevatedButton.icon(
  onPressed: () => context.go('/create-team'),
  icon: const Icon(Icons.add),
  label: Text(LocalizationService().translate('create_team')),
  // ...
),
```

---

## VERIFICATION CHECKLIST

After applying all fixes, verify:

- [ ] Application compiles without errors
- [ ] Match requests screen is accessible from navigation
- [ ] No duplicate "Match Type" fields in create match screen
- [ ] All translation keys are present in all language files
- [ ] Match requests can be accepted/rejected
- [ ] Loading states show during operations
- [ ] Error messages display properly
- [ ] Navigation works correctly
- [ ] All screens render without crashes

---

## TESTING COMMANDS

```bash
# Check for compilation errors
flutter analyze

# Run the app
flutter run

# Run tests
flutter test

# Build APK
flutter build apk --release
```

---

## ESTIMATED TIME

- **Total Time to Fix:** ~1.5 hours
- **Testing Time:** ~30 minutes
- **Total:** ~2 hours

---

## NOTES

- All fixes are backward compatible
- No database migrations needed
- No breaking changes to existing functionality
- All fixes follow the existing code style and patterns
