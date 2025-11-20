# Team & Match Logic Implementation Guide

## Overview
This document describes the implementation of team and match constraints to ensure proper game organization and prevent abuse.

## Business Rules

### Team Ownership
1. **Maximum 2 Teams per User**: Each user can create and own a maximum of 2 teams
2. **Automatic Ownership**: When a user creates a team, they automatically become the owner
3. **Owner Privileges**: Team owners can manage members, update team info, and delete the team

### Match Creation
1. **One Active Match per User**: Users can create only one active match at a time
2. **Team Requirement**: Users must own at least one team to create a match
3. **Auto-assign Team 1**: When creating a match, Team 1 is automatically set to one of the creator's teams
4. **Match Request System**: Matches require approval from Team 2 before becoming official

### Match Request Flow
1. **Create Request**: User creates a match with Team 1 (their team) and Team 2 (opponent)
2. **Pending Status**: Match is created with status='pending'
3. **Notification**: Team 2 owner receives a notification about the match request
4. **Approval/Rejection**: Team 2 owner can accept or reject the request
5. **Confirmed**: If accepted, match status changes to 'confirmed'
6. **Cancelled**: If rejected, match status changes to 'cancelled'

## Database Changes

### Migration: `20250115000000_team_match_constraints.sql`

#### New Constraints
- **Team Ownership Limit**: Trigger prevents users from owning more than 2 teams
- **Match Creation Limit**: Trigger prevents users from creating more than 1 active match
- **Match Status**: Added 'pending' and 'confirmed' statuses

#### New Fields
- `matches.created_by`: UUID reference to the user who created the match
- `matches.status`: Updated to include 'pending' and 'confirmed'

#### New Triggers
- `check_team_ownership_limit()`: Validates team ownership before insert
- `check_match_creation_limit()`: Validates match creation before insert
- `notify_match_request()`: Sends notification to Team 2 owner

#### New Notification Types
- `match_request`: Sent when a match request is created
- `match_accepted`: Sent when a match request is accepted
- `match_rejected`: Sent when a match request is rejected

## Code Changes

### Models

#### Match Model (`lib/models/match.dart`)
- Added `isPending` and `isConfirmed` getters
- Updated status validation to include 'pending' and 'confirmed'
- Default status changed from 'open' to 'pending'

### Services

#### MatchService (`lib/services/match_service.dart`)
New methods:
- `acceptMatchRequest(String matchId)`: Accept a pending match request
- `rejectMatchRequest(String matchId)`: Reject a pending match request
- `getPendingMatchRequests()`: Get all pending match requests for user's teams

#### ApiService (`lib/services/api_service.dart`)
New methods:
- `acceptMatchRequest(String matchId)`: Updates match status to 'confirmed'
- `rejectMatchRequest(String matchId)`: Updates match status to 'cancelled'
- `getPendingMatchRequests()`: Fetches pending requests for user's teams

### Repositories

#### MatchRepository (`lib/repositories/match_repository.dart`)
New methods:
- `acceptMatchRequest(String matchId)`
- `rejectMatchRequest(String matchId)`
- `getPendingMatchRequests()`

## UI Implementation Guide

### Create Match Screen
```dart
// 1. Check if user has teams
final userTeams = await teamService.getMyTeams();
if (userTeams.isEmpty) {
  showError('You must create a team first');
  return;
}

// 2. Check if user already has an active match
final activeMatches = await matchService.getMatches();
final userActiveMatch = activeMatches.where((m) => 
  m.createdBy == currentUserId && 
  m.status != 'cancelled' && 
  m.status != 'completed'
).toList();

if (userActiveMatch.isNotEmpty) {
  showError('You already have an active match');
  return;
}

// 3. Auto-select Team 1 from user's teams
String team1Id = userTeams.first.id; // or let user choose

// 4. Let user select Team 2
String team2Id = await showTeamPicker();

// 5. Create match (will be pending)
await matchService.createMatch(
  team1Id: team1Id,
  team2Id: team2Id,
  matchDate: selectedDate,
  location: location,
);

showSuccess('Match request sent to ${team2Name}');
```

### Match Requests Screen
```dart
// Show pending match requests for user's teams
final pendingRequests = await matchService.getPendingMatchRequests();

ListView.builder(
  itemCount: pendingRequests.length,
  itemBuilder: (context, index) {
    final match = pendingRequests[index];
    return MatchRequestCard(
      match: match,
      onAccept: () async {
        await matchService.acceptMatchRequest(match.id);
        showSuccess('Match accepted!');
      },
      onReject: () async {
        await matchService.rejectMatchRequest(match.id);
        showSuccess('Match rejected');
      },
    );
  },
);
```

### Create Team Screen
```dart
// Check team ownership limit before showing form
final myTeams = await teamService.getMyTeams();
if (myTeams.length >= 2) {
  showError('You can only own 2 teams maximum');
  return;
}

// Show create team form
await teamService.createTeam(
  name: teamName,
  location: location,
  numberOfPlayers: numberOfPlayers,
);
```

## Testing Checklist

### Team Constraints
- [ ] User can create first team successfully
- [ ] User can create second team successfully
- [ ] User cannot create third team (error shown)
- [ ] User becomes owner automatically when creating team
- [ ] Team owner can manage team members

### Match Constraints
- [ ] User without teams cannot create match
- [ ] User with teams can create first match
- [ ] User cannot create second active match
- [ ] User can create new match after previous is completed/cancelled
- [ ] Team 1 is auto-assigned to creator's team

### Match Request Flow
- [ ] Match is created with 'pending' status
- [ ] Team 2 owner receives notification
- [ ] Team 2 owner can see pending request
- [ ] Team 2 owner can accept request (status → 'confirmed')
- [ ] Team 2 owner can reject request (status → 'cancelled')
- [ ] Team 1 owner receives notification of acceptance/rejection
- [ ] Only pending matches can be accepted/rejected

## Migration Steps

1. **Backup Database**
   ```bash
   # Create backup before migration
   supabase db dump > backup_$(date +%Y%m%d).sql
   ```

2. **Run Migration**
   ```bash
   supabase db push
   ```

3. **Verify Constraints**
   ```sql
   -- Check triggers exist
   SELECT * FROM pg_trigger WHERE tgname LIKE '%team%' OR tgname LIKE '%match%';
   
   -- Check notification types
   SELECT DISTINCT type FROM notifications;
   ```

4. **Test Constraints**
   - Try creating 3 teams (should fail)
   - Try creating 2 matches (should fail)
   - Create match request and verify notification

## Error Messages

### Team Creation
- "User can own maximum 2 teams" - Shown when trying to create 3rd team
- "A team with this name already exists" - Duplicate team name

### Match Creation
- "You must create a team first" - User has no teams
- "User can create only one active match at a time" - Already has active match
- "Team 1 and Team 2 cannot be the same" - Same team selected twice

### Match Requests
- "Match request sent to {team_name}" - Success message
- "Match accepted!" - Team 2 accepted
- "Match rejected" - Team 2 rejected
- "Only pending matches can be accepted" - Invalid status

## API Endpoints Summary

### Match Requests
- `POST /matches` - Create match (status='pending')
- `GET /matches?status=pending` - Get pending requests
- `PATCH /matches/:id/accept` - Accept request
- `PATCH /matches/:id/reject` - Reject request

### Team Management
- `GET /teams/my` - Get user's teams (max 2)
- `POST /teams` - Create team (enforces limit)
- `GET /teams/:id/members` - Get team members

## Notifications

### Match Request Created
```json
{
  "type": "match_request",
  "title": "Match Request",
  "message": "{team1_name} wants to play a match with your team",
  "related_id": "{match_id}"
}
```

### Match Request Accepted
```json
{
  "type": "match_accepted",
  "title": "Match Request Accepted",
  "message": "{team2_name} accepted your match request",
  "related_id": "{match_id}"
}
```

### Match Request Rejected
```json
{
  "type": "match_rejected",
  "title": "Match Request Rejected",
  "message": "{team2_name} rejected your match request",
  "related_id": "{match_id}"
}
```

## Future Enhancements

1. **Match Scheduling**: Add time slots to prevent double-booking
2. **Team Availability**: Check team availability before creating match
3. **Match History**: Track accepted/rejected requests
4. **Bulk Actions**: Accept/reject multiple requests at once
5. **Match Reminders**: Send notifications before match time
6. **Team Ratings**: Rate teams after matches
7. **Match Templates**: Save common match configurations

## Support

For issues or questions:
1. Check database logs: `supabase logs`
2. Verify triggers are active: `SELECT * FROM pg_trigger`
3. Check RLS policies: `SELECT * FROM pg_policies`
4. Review error logs in app
