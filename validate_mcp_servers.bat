@echo off
echo Testing MCP Server Connections...
echo ================================

echo.
echo [1/20] Testing Brave Search...
npx -y @modelcontextprotocol/server-brave-search --help >nul 2>&1
if %errorlevel%==0 (echo ✓ Brave Search - OK) else (echo ✗ Brave Search - FAILED)

echo.
echo [2/20] Testing Supabase...
npx -y @supabase/mcp-server-supabase@0.5.5 --help >nul 2>&1
if %errorlevel%==0 (echo ✓ Supabase - OK) else (echo ✗ Supabase - FAILED)

echo.
echo [3/20] Testing Context7...
npx -y @upstash/context7-mcp --help >nul 2>&1
if %errorlevel%==0 (echo ✓ Context7 - OK) else (echo ✗ Context7 - FAILED)

echo.
echo [4/20] Testing Memory...
npx -y @modelcontextprotocol/server-memory --help >nul 2>&1
if %errorlevel%==0 (echo ✓ Memory - OK) else (echo ✗ Memory - FAILED)

echo.
echo [5/20] Testing Dart...
dart --version >nul 2>&1
if %errorlevel%==0 (echo ✓ Dart - OK) else (echo ✗ Dart - FAILED)

echo.
echo [6/20] Testing N8N...
npx -y n8n-mcp@2.12.2 --help >nul 2>&1
if %errorlevel%==0 (echo ✓ N8N - OK) else (echo ✗ N8N - FAILED)

echo.
echo [7/20] Testing Time...
python -m uv tool run mcp-server-time --help >nul 2>&1
if %errorlevel%==0 (echo ✓ Time - OK) else (echo ✗ Time - FAILED)

echo.
echo [8/20] Testing Flutter...
npx -y @modelcontextprotocol/server-flutter --help >nul 2>&1
if %errorlevel%==0 (echo ✓ Flutter - OK) else (echo ✗ Flutter - FAILED)

echo.
echo [9/20] Testing Postgres...
npx -y @modelcontextprotocol/server-postgres --help >nul 2>&1
if %errorlevel%==0 (echo ✓ Postgres - OK) else (echo ✗ Postgres - FAILED)

echo.
echo [10/20] Testing Git...
npx -y @modelcontextprotocol/server-git --help >nul 2>&1
if %errorlevel%==0 (echo ✓ Git - OK) else (echo ✗ Git - FAILED)

echo.
echo [11/20] Testing Filesystem...
npx -y @modelcontextprotocol/server-filesystem --help >nul 2>&1
if %errorlevel%==0 (echo ✓ Filesystem - OK) else (echo ✗ Filesystem - FAILED)

echo.
echo [12/20] Testing Puppeteer...
npx -y @modelcontextprotocol/server-puppeteer --help >nul 2>&1
if %errorlevel%==0 (echo ✓ Puppeteer - OK) else (echo ✗ Puppeteer - FAILED)

echo.
echo [13/20] Testing Fetch...
npx -y @modelcontextprotocol/server-fetch --help >nul 2>&1
if %errorlevel%==0 (echo ✓ Fetch - OK) else (echo ✗ Fetch - FAILED)

echo.
echo [14/20] Testing Markdown...
npx -y @modelcontextprotocol/server-markdown --help >nul 2>&1
if %errorlevel%==0 (echo ✓ Markdown - OK) else (echo ✗ Markdown - FAILED)

echo.
echo [15/20] Testing Env...
npx -y @modelcontextprotocol/server-env --help >nul 2>&1
if %errorlevel%==0 (echo ✓ Env - OK) else (echo ✗ Env - FAILED)

echo.
echo [16/20] Testing SQLite...
npx -y @modelcontextprotocol/server-sqlite --help >nul 2>&1
if %errorlevel%==0 (echo ✓ SQLite - OK) else (echo ✗ SQLite - FAILED)

echo.
echo [17/20] Testing Shell...
npx -y @modelcontextprotocol/server-shell --help >nul 2>&1
if %errorlevel%==0 (echo ✓ Shell - OK) else (echo ✗ Shell - FAILED)

echo.
echo [18/20] Testing GitHub...
npx -y @modelcontextprotocol/server-github --help >nul 2>&1
if %errorlevel%==0 (echo ✓ GitHub - OK) else (echo ✗ GitHub - FAILED)

echo.
echo [19/20] Testing Docker...
npx -y @modelcontextprotocol/server-docker --help >nul 2>&1
if %errorlevel%==0 (echo ✓ Docker - OK) else (echo ✗ Docker - FAILED)

echo.
echo [20/20] Testing AWS...
npx -y @modelcontextprotocol/server-aws --help >nul 2>&1
if %errorlevel%==0 (echo ✓ AWS - OK) else (echo ✗ AWS - FAILED)

echo.
echo ================================
echo MCP Server Validation Complete!
echo ================================
echo.
echo Note: Some servers may require additional configuration (API keys, tokens, etc.)
echo Check the mcp.json file to configure environment variables as needed.
echo.
pause