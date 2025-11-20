-- Critical Performance Indexes Migration
-- Created: 2024
-- Purpose: Add missing indexes to improve query performance

-- Matches table indexes
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_matches_date_status 
  ON matches(match_date, status);

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_matches_upcoming 
  ON matches(match_date) 
  WHERE status = 'scheduled' AND match_date > NOW();

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_matches_team1 
  ON matches(team1_id);

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_matches_team2 
  ON matches(team2_id);

-- Teams table indexes
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_teams_city_status 
  ON teams(city_id, status) 
  WHERE status = 'active';

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_teams_owner 
  ON teams(owner_id);

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_teams_name_search 
  ON teams USING gin(to_tsvector('english', name));

-- Team members indexes
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_team_members_team 
  ON team_members(team_id);

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_team_members_user 
  ON team_members(user_id);

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_team_members_composite 
  ON team_members(team_id, user_id);

-- Match players indexes
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_match_players_match 
  ON match_players(match_id);

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_match_players_player 
  ON match_players(player_id);

-- Notifications indexes
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_notifications_user_unread 
  ON notifications(user_id, is_read, created_at DESC);

-- Team join requests indexes
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_team_join_requests_team_status 
  ON team_join_requests(team_id, status);

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_team_join_requests_user 
  ON team_join_requests(user_id);

-- Analyze tables for query planner
ANALYZE matches;
ANALYZE teams;
ANALYZE team_members;
ANALYZE match_players;
ANALYZE notifications;
ANALYZE team_join_requests;
