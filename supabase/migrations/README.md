# Supabase Migrations

This directory contains all database migrations for the Football Community App. Migrations are applied in chronological order based on their timestamp prefixes.

## Migration Files

### Core Schema Migrations
- `20251020153933_initial_schema.sql` - Initial database schema with basic tables, RLS policies, and indexes
- `20251020154000_add_team_join_requests.sql` - Adds team join request functionality
- `20251025000000_update_match_type_constraint.sql` - Updates match type constraints
- `20251025030000_add_unique_team_name_fixed.sql` - Fixes team name uniqueness constraints
- `20251025040000_fix_unique_team_name.sql` - Additional team name constraint fixes
- `20251220000000_add_performance_indexes.sql` - Performance optimization indexes
- `20251220000001_create_cities_table.sql` - Cities table for location data
- `20251224000000_fix_auth_duplicate_constraints.sql` - Fixes authentication-related constraints

### Security and Performance Enhancements
- `20251025100000_enhanced_security_policies.sql` - **NEW** Enhanced RLS policies, audit triggers, and security improvements
- `20251025110000_additional_indexes_constraints.sql` - **NEW** Advanced indexes, constraints, and utility functions

## Key Features Implemented

### Row Level Security (RLS) Policies

#### Users Table
- Users can view and update their own profiles
- Admins can view and manage all user profiles
- Proper authentication checks for all operations

#### Teams Table
- Public visibility for recruiting teams
- Team members can view their teams
- Owners and captains can update team information
- Proper access controls for team management

#### Matches Table
- Participants and organizers can view matches
- Open matches are publicly visible
- Team owners and captains can create and manage matches
- Proper organizer permissions for match updates

#### Team Members Table
- Team members and owners can view membership
- Owners and captains can manage team membership
- Users can request to join teams

#### Match Participants Table
- Participants and organizers can view participation
- Users can join matches, organizers can manage participants
- Proper status tracking and access controls

#### Notifications Table
- Users can view their own notifications
- Admins can view all notifications
- System can create notifications for users

### Performance Optimizations

#### Indexes Added
- Composite indexes for common query patterns
- Partial indexes for active/open records
- Text search indexes with GIN for full-text search
- Geographic indexes (when PostGIS is available)
- Time-based indexes for analytics
- Covering indexes for SELECT query optimization

#### Query Patterns Optimized
- Team and match listings with filtering
- User search and location-based queries
- Notification management and cleanup
- Match date and status filtering
- Team member and participant queries

### Data Integrity Constraints

#### Business Rules
- Match dates must be reasonable (not too far in past/future)
- Team names must be unique per owner
- Match capacity limits enforced
- Phone number validation and normalization
- Age and player limits validation

#### Foreign Key Constraints
- Proper cascading deletes for related records
- Referential integrity maintained across all tables

### Audit and Monitoring

#### Audit Logging
- All changes to sensitive tables (users, teams, matches, team_members) are logged
- Audit trail includes user, operation type, and before/after values
- Admins can view audit logs for security monitoring

#### Automatic Cleanup
- Old notifications automatically cleaned up (keeps last 1000 per user)
- Orphaned records cleanup functions
- Match status updates based on dates

### Utility Functions

#### Permission Checking
- `get_user_team_permissions()` - Check user permissions for teams
- `get_user_match_permissions()` - Check user permissions for matches

#### Analytics and Stats
- `get_team_stats()` - Team statistics and metrics
- `get_user_activity_summary()` - User activity summary
- `get_nearby_users()` - Location-based user discovery

#### Maintenance
- `analyze_table_performance()` - Database performance monitoring
- `cleanup_orphaned_records()` - Database cleanup utilities

## Security Improvements

### Access Control
- **Before**: Teams and matches were completely public
- **After**: Proper role-based access with team membership and organizer checks

### Admin Operations
- Admin-only operations for user management
- Audit logging for all sensitive operations
- Proper authentication checks throughout

### Data Protection
- RLS policies prevent unauthorized data access
- Input validation and sanitization
- Secure default configurations

## Performance Improvements

### Query Optimization
- **Before**: Basic single-column indexes
- **After**: Composite, partial, and covering indexes for complex queries

### Database Efficiency
- Optimized index usage for common application queries
- Reduced query execution time through better indexing strategies
- Efficient text search capabilities

## Migration Order

Always apply migrations in timestamp order:

```bash
# Apply all migrations
supabase db push

# Or apply specific migration
supabase migration up --include-all
```

## Testing Migrations

Before deploying to production:

1. **Test in development environment**
   ```bash
   supabase start
   supabase db reset
   ```

2. **Verify RLS policies work correctly**
   - Test with different user roles (player, coach, admin)
   - Verify access controls for teams, matches, and notifications

3. **Performance testing**
   - Run application with realistic data load
   - Monitor query performance with new indexes
   - Check for any performance regressions

4. **Data integrity validation**
   - Verify all constraints work as expected
   - Test edge cases and boundary conditions
   - Ensure no data loss during migration

## Rollback Strategy

If issues occur with new migrations:

1. **Identify the problematic migration**
2. **Create a rollback migration** with reversed changes
3. **Test rollback in development**
4. **Apply rollback in production if necessary**

## Configuration Updates

### Supabase Config (`config.toml`)
- Enhanced authentication settings
- Database connection pooling
- API rate limiting
- Storage bucket configurations

### Edge Functions (`deno.json`)
- Updated dependencies for better security
- Added Zod for input validation
- Development tooling improvements

## Monitoring and Maintenance

### Regular Tasks
- Monitor audit logs for security incidents
- Clean up old notifications periodically
- Review and optimize slow queries
- Update indexes based on query patterns

### Performance Monitoring
- Use `analyze_table_performance()` function for insights
- Monitor index usage with `pg_stat_user_indexes`
- Review query execution plans for optimization opportunities

## Breaking Changes

### RLS Policy Changes
- **Teams**: No longer publicly visible unless recruiting
- **Matches**: Restricted visibility based on participation and organization
- **Users**: Profile access now properly controlled

### New Constraints
- Match dates cannot be too far in the past
- Team names must be unique per owner
- Phone number validation now enforced

## Migration Checklist

- [ ] Backup production database
- [ ] Test migrations in staging environment
- [ ] Verify RLS policies work for all user types
- [ ] Check query performance improvements
- [ ] Validate data integrity constraints
- [ ] Test application functionality end-to-end
- [ ] Monitor error logs during deployment
- [ ] Update application code for new permission checks
- [ ] Document any required client-side changes

## Support

For issues with these migrations:
1. Check Supabase dashboard for error details
2. Review migration logs for specific errors
3. Test individual migrations in isolation
4. Verify database extensions are installed (uuid-ossp, pg_libphonenumber)