# Supabase MCP Server Setup

## Overview

The Supabase MCP (Model Context Protocol) server has been successfully configured in this project. This server allows AI assistants to interact directly with Supabase projects, enabling operations like managing tables, fetching configurations, querying data, and more.

## Configuration

The MCP server is configured in `blackbox_mcp_settings.json` with the following setup:

```json
{
  "mcpServers": {
    "github.com/supabase-community/supabase-mcp": {
      "type": "http",
      "url": "https://mcp.supabase.com/mcp"
    }
  }
}
```

### Server Details

- **Server Name**: `github.com/supabase-community/supabase-mcp`
- **Type**: HTTP transport with OAuth authentication
- **URL**: `https://mcp.supabase.com/mcp`
- **Repository**: https://github.com/supabase-community/supabase-mcp

## Available Tools

The Supabase MCP server provides the following tool groups:

### 1. Account Tools
- `list_projects`: Lists all Supabase projects
- `get_project`: Gets details for a specific project
- `create_project`: Creates a new Supabase project
- `pause_project`: Pauses a project
- `restore_project`: Restores a project
- `list_organizations`: Lists all organizations
- `get_organization`: Gets organization details
- `get_cost`: Gets cost estimates
- `confirm_cost`: Confirms cost understanding

### 2. Knowledge Base Tools
- `search_docs`: Searches Supabase documentation for up-to-date information

### 3. Database Tools
- `list_tables`: Lists all tables within specified schemas
- `list_extensions`: Lists all database extensions
- `list_migrations`: Lists all migrations
- `apply_migration`: Applies SQL migrations (tracked in database)
- `execute_sql`: Executes raw SQL queries

### 4. Debugging Tools
- `get_logs`: Gets logs by service type (api, postgres, edge functions, auth, storage, realtime)
- `get_advisors`: Gets advisory notices for security vulnerabilities or performance issues

### 5. Development Tools
- `get_project_url`: Gets the API URL for a project
- `get_anon_key`: Gets the anonymous API key
- `generate_typescript_types`: Generates TypeScript types from database schema

### 6. Edge Functions Tools
- `list_edge_functions`: Lists all Edge Functions
- `get_edge_function`: Retrieves Edge Function file contents
- `deploy_edge_function`: Deploys new or updates existing Edge Functions

### 7. Branching Tools (Experimental, requires paid plan)
- `create_branch`: Creates development branch with migrations
- `list_branches`: Lists all development branches
- `delete_branch`: Deletes a development branch
- `merge_branch`: Merges migrations and edge functions to production
- `reset_branch`: Resets migrations to prior version
- `rebase_branch`: Rebases development branch on production

### 8. Storage Tools (Disabled by default)
- `list_storage_buckets`: Lists all storage buckets
- `get_storage_config`: Gets storage configuration
- `update_storage_config`: Updates storage configuration (requires paid plan)

## Configuration Options

You can customize the server behavior using URL query parameters:

### Read-Only Mode (Recommended)
```
https://mcp.supabase.com/mcp?read_only=true
```
Restricts the server to read-only queries, preventing write operations.

### Project Scoped Mode (Recommended)
```
https://mcp.supabase.com/mcp?project_ref=<project-ref>
```
Limits access to a specific project only.

### Feature Groups
```
https://mcp.supabase.com/mcp?features=database,docs
```
Enables only specific tool groups. Available groups: `account`, `docs`, `database`, `debugging`, `development`, `functions`, `storage`, `branching`.

### Combined Example
```
https://mcp.supabase.com/mcp?read_only=true&project_ref=your-project-ref&features=database,docs,debugging
```

## Authentication

The MCP server uses OAuth authentication. When you first use the server:

1. Your MCP client will prompt you to login to Supabase
2. A browser window will open for authentication
3. Login to your Supabase account
4. Grant access to the MCP client
5. Choose the organization containing your project

## Security Best Practices

### Recommendations:
1. **Don't connect to production**: Use with development projects only
2. **Don't give to customers**: This is a developer tool, not for end users
3. **Enable read-only mode**: Set `read_only=true` when connecting to real data
4. **Use project scoping**: Limit access to specific projects with `project_ref`
5. **Use branching**: Test changes in development branches before production
6. **Limit feature groups**: Enable only the tools you need

### Prompt Injection Risk
Be aware that LLMs can be tricked by malicious content in your data. Always:
- Review tool calls before executing them
- Keep manual approval enabled in your MCP client
- Review SQL query outputs before proceeding with further actions

## Usage Example

Once configured, you can ask your AI assistant to:

- "List all tables in my Supabase database"
- "Show me the schema for the users table"
- "Search the Supabase docs for information about Row Level Security"
- "Get the logs for my Edge Functions"
- "Generate TypeScript types for my database schema"

## Testing the Setup

To verify the MCP server is working correctly, you can:

1. Ask your AI assistant to use the `search_docs` tool to find information about a Supabase feature
2. Request to list your Supabase projects using `list_projects`
3. Query your database schema using `list_tables`

## Resources

- [Supabase MCP Documentation](https://supabase.com/docs/guides/getting-started/mcp)
- [Model Context Protocol](https://modelcontextprotocol.io/introduction)
- [GitHub Repository](https://github.com/supabase-community/supabase-mcp)

## Current Project Integration

This project already has a Supabase backend with:
- Database tables for users, teams, matches, and notifications
- Edge Functions for match and team creation
- Storage buckets for team logos
- Authentication system

The MCP server can now be used to interact with and manage these resources through AI assistance.
