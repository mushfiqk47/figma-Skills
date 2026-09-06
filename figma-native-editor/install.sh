#!/bin/bash
set -e
echo "Installing figma-native-editor..."
if command -v claude >/dev/null 2>&1; then
  claude plugin install figma@claude-plugins-official || echo "Marketplace install skipped, using local wrapper."
else
  echo "Claude CLI not found, local wrapper ready at $(dirname $0)"
fi
echo ""
echo "Next:"
echo "1. export FIGMA_API_KEY=figd_... (Figma > Account Settings > Tokens)"
echo "2. In Claude Code: /plugin install ./figma-native-editor"
echo "3. Paste your figma.com/design/... URL in chat to edit natively"
