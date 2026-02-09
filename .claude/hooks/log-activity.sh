#!/bin/bash
# Log activity

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name')
LOGFILE="$CLAUDE_PROJECT_DIR/.tinyclaw/logs/activity.log"

mkdir -p "$(dirname "$LOGFILE")"
echo "[$(date)] $TOOL_NAME" >> "$LOGFILE"

exit 0
