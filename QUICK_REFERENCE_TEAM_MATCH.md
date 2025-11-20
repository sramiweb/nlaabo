# Quick Reference: Team & Match Logic

## 🎯 Business Rules (Quick View)

| Rule | Limit | Enforced By |
|------|-------|-------------|
| Teams per user | 2 max | Database trigger |
| Active matches per user | 1 max | Database trigger |
| Teams required to create match | 1 min | Application logic |
| Match approval required | Yes | Match request system |

## 🔄 Match Status Flow

```
CREATE MATCH
    ↓
[pending] ← Match request sent to Team 2
    ↓
Team 2 decides
    ↓
Accept? → [confirmed] → [open] → [in_progress] → [completed]
    ↓
Reject? → [cancelled]
```

## 📞 API Methods (Quick Reference)

### Team Service
```dart
// Get user's teams (max 2)
List<Team> teams = await teamService.getMyTeams();

// Create team (enforces 2-team limit)
Team team = await teamService.createTeam(
  name: 'Team Name',
  location: 'City',
);
```

### Match Service
```dart
// Create match request (enforces 1-match limit)
Match match = await matchService.createMatch(
  team1Id: myTeamId,      // Auto-assigned
  team2Id: opponentTeamId,
  matchDate: DateTime.now().add(Duration(days: 7)),
  location: 'Stadium',
);

// Get pending requests for my teams
List<Match> requests = await matchService.getPendingMatchRequests();

// Accept match request (Team 2 owner only)
Match accepted = await matchService.acceptMatchRequest(matchId);

// Reject match request (Team 2 owner only)
await matchService.rejectMatchRequest(matchId);
```

## 🚨 Error Messages

| Error | Meaning | Solution |
|-------|---------|----------|
| "User can own maximum 2 teams" | Trying to create 3rd team | Delete a team first |
| "User can create only one active match at a time" | Already has active match | Complete/cancel existing match |
| "You must create a team first" | No teams owned | Create a team |
| "Team 1 and Team 2 cannot be the same" | Same team selected | Choose different teams |

## 🔔 Notification Types

| Type | Trigger | Recipient |
|------|---------|-----------|
| `match_request` | Match created | Team 2 owner |
| `match_accepted` | Request accepted | Team 1 owner (creator) |
| `match_rejected` | Request rejected | Team 1 owner (creator) |

## 🧪 Quick Test Commands

```bash
# Run migration
supabase db push

# Verify triggers
supabase db execute "SELECT tgname FROM pg_trigger WHERE tgname LIKE '%team%' OR tgname LIKE '%match%';"

# Check notification types
supabase db execute "SELECT DISTINCT type FROM notifications;"

# Test team limit (should fail on 3rd)
# Create 3 teams via UI

# Test match limit (should fail on 2nd)
# Create 2 matches via UI
```

## 💻 UI Code Snippets

### Check Team Limit
```dart
final teams = await teamService.getMyTeams();
if (teams.length >= 2) {
  showError('Maximum 2 teams allowed');
  return;
}
```

### Check Match Limit
```dart
final matches = await matchService.getMatches();
final activeMatch = matches.firstWhere(
  (m) => m.createdBy == userId && 
         m.status != 'cancelled' && 
         m.status != 'completed',
  orElse: () => null,
);
if (activeMatch != null) {
  showError('You already have an active match');
  return;
}
```

### Handle Match Request
```dart
// Accept
await matchService.acceptMatchRequest(matchId);
showSuccess('Match accepted!');

// Reject
await matchService.rejectMatchRequest(matchId);
showSuccess('Match rejected');
```

## 📊 Database Queries

### Get user's team count
```sql
SELECT COUNT(*) FROM teams WHERE owner_id = 'user-id' AND deleted_at IS NULL;
```

### Get user's active matches
```sql
SELECT * FROM matches m
JOIN teams t ON m.team1_id = t.id
WHERE t.owner_id = 'user-id' 
AND m.status NOT IN ('cancelled', 'completed');
```

### Get pending match requests for user's teams
```sql
SELECT m.* FROM matches m
JOIN teams t ON m.team2_id = t.id
WHERE t.owner_id = 'user-id' 
AND m.status = 'pending';
```

## 🎨 UI Components Needed

1. **Match Request Card** - Show pending requests with Accept/Reject buttons
2. **Team Limit Warning** - Show when user has 2 teams
3. **Match Limit Warning** - Show when user has active match
4. **Match Status Badge** - Show pending/confirmed/completed status
5. **Notification Badge** - Show count of pending requests

## 🔐 Permission Checks

```dart
// Can create team?
bool canCreateTeam = (await teamService.getMyTeams()).length < 2;

// Can create match?
bool hasTeam = (await teamService.getMyTeams()).isNotEmpty;
bool hasActiveMatch = /* check active matches */;
bool canCreateMatch = hasTeam && !hasActiveMatch;

// Can accept/reject request?
bool isTeam2Owner = match.team2Id == myTeam.id && myTeam.ownerId == userId;
bool canRespond = match.status == 'pending' && isTeam2Owner;
```

## 📱 Navigation Flow

```
Home
 ├─ Create Team (if < 2 teams)
 ├─ Create Match (if has team && no active match)
 ├─ Match Requests (show badge if pending)
 │   ├─ Accept → Match Details
 │   └─ Reject → Back to list
 └─ My Matches
     ├─ Pending (waiting for Team 2)
     ├─ Confirmed (accepted by Team 2)
     └─ Completed
```

## 🚀 Deployment Checklist

- [ ] Run database migration
- [ ] Verify triggers are active
- [ ] Test team creation limit
- [ ] Test match creation limit
- [ ] Test match request flow
- [ ] Test notifications
- [ ] Update UI to show limits
- [ ] Add match requests screen
- [ ] Update error messages
- [ ] Test on staging
- [ ] Deploy to production

## 📞 Support

**Common Issues:**
1. **Trigger not firing**: Check `pg_trigger` table
2. **Notification not sent**: Check `notifications` table
3. **RLS blocking update**: Check `pg_policies` table
4. **Constraint violation**: Check error logs

**Debug Commands:**
```sql
-- Check triggers
SELECT * FROM pg_trigger WHERE tgname LIKE '%team%';

-- Check recent notifications
SELECT * FROM notifications ORDER BY created_at DESC LIMIT 10;

-- Check match statuses
SELECT status, COUNT(*) FROM matches GROUP BY status;
```

---

**Last Updated**: 2025-01-15  
**Version**: 1.0  
**Author**: Amazon Q
