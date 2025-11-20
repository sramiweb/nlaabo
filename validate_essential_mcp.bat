@echo off
echo Validating Essential MCP Servers...
echo ===================================
echo.

echo [1] Memory Server:
echo Installing and testing...
call npx -y @modelcontextprotocol/server-memory --help >nul 2>&1
if %errorlevel%==0 (echo ✓ Memory Server - READY) else (echo ✗ Memory Server - FAILED)

echo.
echo [2] Filesystem Server:
echo Installing and testing...
call npx -y @modelcontextprotocol/server-filesystem --help >nul 2>&1
if %errorlevel%==0 (echo ✓ Filesystem Server - READY) else (echo ✗ Filesystem Server - FAILED)

echo.
echo [3] Git Server:
echo Installing and testing...
call npx -y @modelcontextprotocol/server-git --help >nul 2>&1
if %errorlevel%==0 (echo ✓ Git Server - READY) else (echo ✗ Git Server - FAILED)

echo.
echo [4] Fetch Server:
echo Installing and testing...
call npx -y @modelcontextprotocol/server-fetch --help >nul 2>&1
if %errorlevel%==0 (echo ✓ Fetch Server - READY) else (echo ✗ Fetch Server - FAILED)

echo.
echo [5] SQLite Server:
echo Installing and testing...
call npx -y @modelcontextprotocol/server-sqlite --help >nul 2>&1
if %errorlevel%==0 (echo ✓ SQLite Server - READY) else (echo ✗ SQLite Server - FAILED)

echo.
echo ===================================
echo Essential MCP Servers Validation Complete!
echo ===================================
echo.
echo Your MCP configuration is now optimized for Flutter development.
echo Restart Amazon Q to load the new MCP servers.
echo.
pause