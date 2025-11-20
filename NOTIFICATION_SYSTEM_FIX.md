# Notification System Fix for Team and Match Requests

## Issue
The complete notification flow for team/match requests was not working:
1. Team/match owners were not receiving notifications when players send join requests
2. Players were not receiving notifications when their requests are accepted/rejected

Even though all the code was implemented, notifications were failing silently.

## Root Cause
The `notifications` table had a CHECK constraint that only allowed these notification types:
- `match_invite`
- `team_invite`
- `general`
- `system`

However, the application code in `api_service.dart` was trying to create notifications with types:
- `team_join_approved` (when request is accepted)
- `team_join_rejected` (when request is rejected)

These types were not in the allowed list, causing the notification creation to fail silently.

## Solution

### Database Migration
Created migration `20250113000000_add_notification_types.sql` that:
1. Drops the old constraint
2. Adds updated constraint with all notification types including:
   - `team_join_request`
   - `team_join_approved` ✅
   - `team_join_rejected` ✅
   - `match_created`
   - `match_joined`
   - `match_left`
   - `match_reminder`
3. Adds policy to allow system to insert notifications

### Existing Implementation
The complete notification flow was already implemented in `lib/services/api_service.dart`:

#### 1. When Player Sends Join Request (Owner Notification)
```dart
// In createJoinRequest() method (line 1637-1647)
await createNotification(
  userId: team.ownerId,  // Notify the team owner
  title: 'New Join Request',
  message: '${currentUser.name} wants to join ${team.name}',
  type: 'team_join_request',
  relatedId: teamId,
);
```

#### 2. When Player Joins Match (Owner Notification)
```dart
// In joinMatch() method (line 1336-1343)
await createNotification(
  userId: match.createdBy!,  // Notify the match creator
  title: 'New Player Joined',
  message: '${currentUser.name} joined your match',
  type: 'match_joined',
  relatedId: matchId,
);
```

#### 3. When Owner Accepts Request (Player Notification)
```dart
// In updateJoinRequestStatus() method (line 1719-1726)
await createNotification(
  userId: request.userId,  // Notify the requesting player
  title: 'Join Request Approved',
  message: 'Your request to join ${request.team?.name ?? "the team"} was approved',
  type: 'team_join_approved',
  relatedId: teamId,
);
```

#### 4. When Owner Rejects Request (Player Notification)
```dart
// In updateJoinRequestStatus() method (line 1727-1732)
await createNotification(
  userId: request.userId,  // Notify the requesting player
  title: 'Join Request Rejected',
  message: 'Your request to join ${request.team?.name ?? "the team"} was rejected',
  type: 'team_join_rejected',
  relatedId: teamId,
);
```

The notifications screen (`lib/screens/notifications_screen.dart`) already handles these types with:
- Proper icons (check_circle for approved, cancel for rejected)
- Proper colors (blue for approved, red for rejected)
- Navigation to team details when tapped

## How to Apply

Run the migration:
```bash
supabase db push
```

## Testing

After applying the migration, test the complete notification flow:

### Team Join Request Flow
1. **User A** creates a team
2. **User B** sends a join request
   - ✅ **User A** (owner) receives notification: "New Join Request"
3. **User A** accepts or rejects the request
   - ✅ **User B** (player) receives notification: "Join Request Approved" or "Join Request Rejected"
4. Both users can tap notifications to navigate to team details

### Match Join Flow
1. **User A** creates a match
2. **User B** joins the match
   - ✅ **User A** (creator) receives notification: "New Player Joined"
3. Both users can tap notification to navigate to match details

## Files Modified
- `supabase/migrations/20250113000000_add_notification_types.sql` (new)

## Files Already Implementing Notifications
- `lib/services/api_service.dart` - Creates notifications on approve/reject
- `lib/screens/notifications_screen.dart` - Displays notifications
- `lib/screens/team_management_screen.dart` - Triggers approve/reject actions
