#!/usr/bin/env bash
# Docker initialization script
# Creates settings.json from environment variables

SETTINGS_FILE="/app/.tinyclaw/settings.json"

# Check if settings.json already exists and is valid
if [ -f "$SETTINGS_FILE" ]; then
    # If it's a valid JSON file, don't overwrite it
    if jq empty "$SETTINGS_FILE" 2>/dev/null; then
        echo "Settings file already exists and is valid, skipping creation"
        exit 0
    fi
fi

echo "Creating settings.json from environment variables..."

# Parse enabled channels
if [ -n "$TINYCLAW_CHANNELS" ]; then
    IFS=',' read -ra CHANNELS <<< "$TINYCLAW_CHANNELS"
    CHANNELS_JSON="["
    for i in "${!CHANNELS[@]}"; do
        if [ $i -gt 0 ]; then
            CHANNELS_JSON="${CHANNELS_JSON}, "
        fi
        CHANNELS_JSON="${CHANNELS_JSON}\"${CHANNELS[$i]}\""
    done
    CHANNELS_JSON="${CHANNELS_JSON}]"
else
    # Default to telegram and discord
    CHANNELS_JSON='["telegram", "discord"]'
fi

# Determine model from ANTHROPIC_MODEL env var
# Default to sonnet if not specified or not recognized
MODEL="sonnet"
MODEL_ID=""
if [ -n "$ANTHROPIC_MODEL" ]; then
    case "$ANTHROPIC_MODEL" in
        *sonnet*|*Sonnet*)
            MODEL="sonnet"
            ;;
        *opus*|*Opus*)
            MODEL="opus"
            ;;
        *)
            # If it's not a recognized name, treat it as a custom model ID
            MODEL_ID="$ANTHROPIC_MODEL"
            MODEL="sonnet"  # Use sonnet as the base model type
            ;;
    esac
fi

# Create settings.json
mkdir -p "$(dirname "$SETTINGS_FILE")"

cat > "$SETTINGS_FILE" <<EOF
{
  "channels": {
    "enabled": ${CHANNELS_JSON},
    "discord": {
      "bot_token": "${DISCORD_BOT_TOKEN:-}"
    },
    "telegram": {
      "bot_token": "${TELEGRAM_BOT_TOKEN:-}"
    },
    "whatsapp": {}
  },
  "models": {
    "anthropic": {
      "model": "${MODEL}",
      "api_key": "${ANTHROPIC_API_KEY:-}",
      "base_url": "${ANTHROPIC_BASE_URL:-https://api.anthropic.com}",
      "model_id": "${MODEL_ID}"
    }
  },
  "monitoring": {
    "heartbeat_interval": ${TINYCLAW_HEARTBEAT_INTERVAL:-3600}
  }
}
EOF

echo "Settings file created successfully at $SETTINGS_FILE"
