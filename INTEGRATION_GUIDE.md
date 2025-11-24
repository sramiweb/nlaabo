# Integration Guide - New Screens

## Quick Integration Steps

### Step 1: Add Routes to main.dart

Add these routes to the GoRouter configuration (after `/match-requests`):

```dart
GoRoute(
  path: '/team/:id/members',
  builder: (context, state) {
    final teamId = state.pathParameters['id'];
    return MainLayout(child: TeamMembersManagementScreen(teamId: teamId));
  },
  pageBuilder: (context, state) {
    final teamId = state.pathParameters['id'];
    return CustomTransitionPage(
      key: state.pageKey,
      child: MainLayout(child: TeamMembersManagementScreen(teamId: teamId)),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return PageTransitions.slideFadeTransition(
          context: context,
          animation: animation,
          child: child,
        );
      },
    );
  },
),
GoRoute(
  path: '/match-history',
  builder: (context, state) => const MainLayout(child: MatchHistoryScreen()),
  pageBuilder: (context, state) => CustomTransitionPage(
    key: state.pageKey,
    child: const MainLayout(child: MatchHistoryScreen()),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return PageTransitions.slideFadeTransition(
        context: context,
        animation: animation,
        child: child,
      );
    },
  ),
),
GoRoute(
  path: '/search',
  builder: (context, state) => const MainLayout(child: AdvancedSearchScreen()),
  pageBuilder: (context, state) => CustomTransitionPage(
    key: state.pageKey,
    child: const MainLayout(child: AdvancedSearchScreen()),
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

### Step 2: Update _isValidRoute()

Add these routes to the valid routes list:

```dart
const validRoutes = [
  // ... existing routes ...
  '/match-history',
  '/search',
];
```

### Step 3: Add Imports to main.dart

```dart
import 'package:nlaabo/screens/team_members_management_screen.dart';
import 'package:nlaabo/screens/match_history_screen.dart';
import 'package:nlaabo/screens/advanced_search_screen.dart';
```

### Step 4: Add Navigation in main_layout.dart

In the navigation menu/drawer, add:

```dart
ListTile(
  leading: const Icon(Icons.history),
  title: const Text('Match History'),
  onTap: () {
    context.go('/match-history');
    Navigator.pop(context); // Close drawer if applicable
  },
),
ListTile(
  leading: const Icon(Icons.search),
  title: const Text('Advanced Search'),
  onTap: () {
    context.go('/search');
    Navigator.pop(context); // Close drawer if applicable
  },
),
```

### Step 5: Add Team Members Link in team_details_screen.dart

```dart
ListTile(
  leading: const Icon(Icons.people),
  title: const Text('Team Members'),
  onTap: () => context.push('/team/${widget.teamId}/members'),
),
```

---

## API Methods Already Available

### Team Operations
```dart
// Delete team (soft delete)
await _apiService.deleteTeam(teamId);

// Remove team member
await _apiService.removeTeamMember(teamId, userId);

// Leave team
await _apiService.leaveTeam(teamId);

// Get team members
await _apiService.getTeamMembers(teamId);
```

### Match Operations
```dart
// Close match
await _apiService.closeMatch(matchId);

// Update match status
await _apiService.updateMatchStatus(matchId, 'cancelled');

// Get my matches
await _apiService.getMyMatches();

// Get all matches
await _apiService.getMatches();
```

### Search Operations
```dart
// Search teams
await _apiService.searchTeams(query);

// Get all teams
await _apiService.getAllTeams();
```

---

## Testing Checklist

- [ ] Routes are accessible from navigation
- [ ] Team members screen loads correctly
- [ ] Can remove team members
- [ ] Match history displays past matches
- [ ] Advanced search finds matches and teams
- [ ] Error handling works properly
- [ ] Loading states display correctly
- [ ] Refresh functionality works
- [ ] Navigation back works

---

## Translation Keys to Add (if needed)

Add to all translation files (en.json, fr.json, ar.json):

```json
{
  "team_members": "Team Members",
  "match_history": "Match History",
  "advanced_search": "Advanced Search",
  "no_members_yet": "No members yet",
  "no_match_history": "No match history",
  "search_matches_teams": "Search matches or teams..."
}
```

---

## Performance Notes

- Team members screen uses RefreshIndicator for manual refresh
- Match history filters past matches client-side
- Advanced search uses real-time filtering
- All screens have proper error handling and loading states

---

**Ready to integrate!**
