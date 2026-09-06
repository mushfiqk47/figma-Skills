@echo off
echo Installing figma-native-editor...
where claude >nul 2>nul
if %errorlevel%==0 (
  echo Attempting marketplace install...
  claude plugin install figma@claude-plugins-official || echo Marketplace install skipped, using local wrapper.
) else (
  echo Claude CLI not found, local wrapper ready at %~dp0
)
echo.
echo Next:
echo 1. Set FIGMA_API_KEY env from Figma Account Settings
echo 2. In Claude Code: /plugin install ./figma-native-editor
echo 3. Paste your figma.com/design/... URL in chat to edit natively
pause
