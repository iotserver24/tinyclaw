# TinyClaw 🦞

Minimal multi-channel AI assistant with Discord, WhatsApp, and Telegram integration.

## 🎯 What is TinyClaw?

TinyClaw is a lightweight wrapper around [Claude Code](https://claude.com/claude-code) that:

- ✅ Connects Discord, WhatsApp, and Telegram
- ✅ Processes messages sequentially (no race conditions)
- ✅ Maintains conversation context
- ✅ Runs 24/7 in tmux
- ✅ Extensible multi-channel architecture

**Key innovation:** File-based queue system prevents race conditions and enables seamless multi-channel support.

## 📐 Architecture

```
┌─────────────────┐
│  Discord        │──┐
│  Client         │  │
└─────────────────┘  │
                     │
┌─────────────────┐  │
│  WhatsApp       │──┤
│  Client         │  │
└─────────────────┘  ├──→ Queue (incoming/)
                     │        ↓
┌─────────────────┐  │   ┌──────────────┐
│  Telegram       │──┤   │   Queue      │
│  Client         │  │   │  Processor   │
└─────────────────┘  │   └──────────────┘
                     │        ↓
                     │   claude -c -p
                     │        ↓
                     │   Queue (outgoing/)
                     │        ↓
                     └──> Channels send
                          responses
```

## 🚀 Quick Start

### Prerequisites

- macOS or Linux
- [Claude Code](https://claude.com/claude-code) installed
- Node.js v14+
- tmux
- Bash 4.0+ (macOS users: `brew install bash` - system bash 3.2 won't work)

### Installation

```bash
cd /path/to/tinyclaw

# Install dependencies
npm install

# Start TinyClaw (first run triggers setup wizard)
./tinyclaw.sh start
```

### First Run - Setup Wizard

On first start, you'll see an interactive setup wizard:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  TinyClaw - Setup Wizard
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Which messaging channels do you want to enable?

  Enable Discord? [y/N]: y
    ✓ Discord enabled
  Enable WhatsApp? [y/N]: y
    ✓ WhatsApp enabled
  Enable Telegram? [y/N]: y
    ✓ Telegram enabled

Enter your Discord bot token:
(Get one at: https://discord.com/developers/applications)

Token: YOUR_DISCORD_BOT_TOKEN_HERE

✓ Discord token saved

Enter your Telegram bot token:
(Create a bot via @BotFather on Telegram to get a token)

Token: YOUR_TELEGRAM_BOT_TOKEN_HERE

✓ Telegram token saved

Which Claude model?

  1) Sonnet  (fast, recommended)
  2) Opus    (smartest)

Choose [1-2]: 1

✓ Model: sonnet

Heartbeat interval (seconds)?
(How often Claude checks in proactively)

Interval [default: 3600]: 3600

✓ Heartbeat interval: 3600s

✓ Configuration saved to .tinyclaw/settings.json
```

### Discord Setup

1. Go to [Discord Developer Portal](https://discord.com/developers/applications)
2. Create a new application
3. Go to "Bot" section and create a bot
4. Copy the bot token
5. Enable "Message Content Intent" in Bot settings
6. Invite the bot to your server using OAuth2 URL Generator

### Telegram Setup

1. Open Telegram and search for @BotFather
2. Send `/newbot` and follow the prompts
3. Choose a name and username for your bot
4. Copy the bot token provided by BotFather
5. Start a chat with your bot or add it to a group

### WhatsApp Setup

After starting, a QR code will appear if WhatsApp is enabled:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        WhatsApp QR Code
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[QR CODE HERE]

📱 Scan with WhatsApp:
   Settings → Linked Devices → Link a Device
```

Scan it with your phone. **Done!** 🎉

### Test It

**Discord:** Send a DM to your bot or mention it in a channel

**WhatsApp:** Send a message to the connected number

**Telegram:** Send a message to your bot

You'll get a response! 🤖

## 📋 Commands

```bash
# Start TinyClaw
./tinyclaw.sh start

# Run setup wizard (change channels/model/heartbeat)
./tinyclaw.sh setup

# Check status
./tinyclaw.sh status

# Send manual message
./tinyclaw.sh send "What's the weather?"

# Reset conversation
./tinyclaw.sh reset

# Reset channel authentication
./tinyclaw.sh channels reset whatsapp  # Clear WhatsApp session
./tinyclaw.sh channels reset discord   # Shows Discord reset instructions
./tinyclaw.sh channels reset telegram  # Shows Telegram reset instructions

# Switch Claude model
./tinyclaw.sh model           # Show current model
./tinyclaw.sh model sonnet    # Switch to Sonnet (fast)
./tinyclaw.sh model opus      # Switch to Opus (smartest)

# View logs
./tinyclaw.sh logs whatsapp   # WhatsApp activity
./tinyclaw.sh logs discord    # Discord activity
./tinyclaw.sh logs telegram   # Telegram activity
./tinyclaw.sh logs queue      # Queue processing
./tinyclaw.sh logs heartbeat  # Heartbeat checks

# Attach to tmux
./tinyclaw.sh attach

# Restart
./tinyclaw.sh restart

# Stop
./tinyclaw.sh stop
```

## 🔧 Components

### 1. setup-wizard.sh

- Interactive setup on first run
- Configures channels (Discord/WhatsApp/Telegram)
- Collects bot tokens for enabled channels
- Selects Claude model
- Writes to `.tinyclaw/settings.json`

### 2. discord-client.ts

- Connects to Discord via bot token
- Listens for DMs and mentions
- Writes incoming messages to queue
- Reads responses from queue
- Sends replies back

### 3. whatsapp-client.ts

- Connects to WhatsApp via QR code
- Writes incoming messages to queue
- Reads responses from queue
- Sends replies back

### 4. telegram-client.ts

- Connects to Telegram via bot token
- Listens for messages
- Writes incoming messages to queue
- Reads responses from queue
- Sends replies back

### 5. queue-processor.ts

- Polls incoming queue
- Processes **ONE message at a time**
- Calls `claude -c -p`
- Waits indefinitely for Claude to finish (supports long-running agent tasks)
- Writes responses to outgoing queue

### 6. heartbeat-cron.sh

- Runs every 5 minutes
- Sends heartbeat via queue
- Keeps conversation active

### 7. tinyclaw.sh

- Main orchestrator
- Manages tmux session
- CLI interface

## 💬 Message Flow

```
Message arrives (Discord/WhatsApp/Telegram)
       ↓
Client writes to:
  .tinyclaw/queue/incoming/{channel}_<id>.json
       ↓
queue-processor.ts picks it up
       ↓
Runs: claude -c -p "message"
       ↓
Writes to:
  .tinyclaw/queue/outgoing/{channel}_<id>.json
       ↓
Client reads and sends response
       ↓
User receives reply
```

## 📁 Directory Structure

```
tinyclaw/
├── .claude/              # Claude Code config
│   ├── settings.json     # Hooks config
│   └── hooks/            # Hook scripts
├── .tinyclaw/            # TinyClaw data
│   ├── settings.json     # Configuration (channel, model, tokens)
│   ├── queue/
│   │   ├── incoming/     # New messages
│   │   ├── processing/   # Being processed
│   │   └── outgoing/     # Responses
│   ├── logs/
│   │   ├── discord.log
│   │   ├── whatsapp.log
│   │   ├── queue.log
│   │   └── heartbeat.log
│   ├── channels/         # Runtime channel data
│   ├── whatsapp-session/
│   └── heartbeat.md
├── src/
│   ├── discord-client.ts    # Discord I/O
│   ├── whatsapp-client.ts   # WhatsApp I/O
│   ├── telegram-client.ts   # Telegram I/O
│   └── queue-processor.ts   # Message processing
├── dist/                 # TypeScript build output
├── setup-wizard.sh       # Interactive setup
├── tinyclaw.sh           # Main script
└── heartbeat-cron.sh     # Health checks
```

## 🔄 Reset Conversation

### Via CLI

```bash
./tinyclaw.sh reset
```

### Via WhatsApp

Send: `!reset` or `/reset`

Next message starts fresh (no conversation history).

## ⚙️ Configuration

### Settings File

All configuration is stored in `.tinyclaw/settings.json`:

```json
{
  "channels": "discord,whatsapp,telegram",
  "model": "sonnet",
  "discord_bot_token": "YOUR_DISCORD_TOKEN_HERE",
  "telegram_bot_token": "YOUR_TELEGRAM_TOKEN_HERE",
  "heartbeat_interval": 3600
}
```

To reconfigure, run:

```bash
./tinyclaw.sh setup
```

The heartbeat interval is in seconds (default: 3600s = 60 minutes).
This controls how often Claude proactively checks in.

### Heartbeat Prompt

Edit `.tinyclaw/heartbeat.md`:

```markdown
Check for:

1. Pending tasks
2. Errors
3. Unread messages

Take action if needed.
```

## 📊 Monitoring

### View Logs

```bash
# WhatsApp activity
tail -f .tinyclaw/logs/whatsapp.log

# Discord activity
tail -f .tinyclaw/logs/discord.log

# Telegram activity
tail -f .tinyclaw/logs/telegram.log

# Queue processing
tail -f .tinyclaw/logs/queue.log

# Heartbeat checks
tail -f .tinyclaw/logs/heartbeat.log

# All logs
./tinyclaw.sh logs daemon
```

### Watch Queue

```bash
# Incoming messages
watch -n 1 'ls -lh .tinyclaw/queue/incoming/'

# Outgoing responses
watch -n 1 'ls -lh .tinyclaw/queue/outgoing/'
```

## 🎨 Features

### ✅ No Race Conditions

Messages processed **sequentially**, one at a time:

```
Message 1 → Process → Done
Message 2 → Wait → Process → Done
Message 3 → Wait → Process → Done
```

### ✅ Multi-Channel Support

Discord, WhatsApp, and Telegram work seamlessly together. All channels share the same conversation context!

**Adding more channels is easy:**

```typescript
// new-channel-client.ts
// Write to queue
fs.writeFileSync(
  ".tinyclaw/queue/incoming/channel_<id>.json",
  JSON.stringify({
    channel: "channel-name",
    message,
    sender,
    timestamp,
  }),
);

// Read responses from outgoing queue
// Same format as other channels
```

Queue processor handles all channels automatically!

### ✅ Clean Responses

Uses `claude -c -p`:

- `-c` = continue conversation
- `-p` = print mode (clean output)
- No tmux capture needed

### ✅ Persistent Sessions

WhatsApp session persists across restarts:

```bash
# First time: Scan QR code
./tinyclaw.sh start

# Subsequent starts: Auto-connects
./tinyclaw.sh restart
```

## 🔐 Security

- WhatsApp session stored locally in `.tinyclaw/whatsapp-session/`
- Queue files are local (no network exposure)
- Each channel handles its own authentication
- Claude runs with your user permissions

## 🐛 Troubleshooting

### Bash version error on macOS

If you see:

```
Error: This script requires bash 4.0 or higher (you have 3.2.57)
```

macOS ships with bash 3.2 by default. Install a newer version:

```bash
# Install bash 5.x via Homebrew
brew install bash

# Add to your PATH (add this to ~/.zshrc or ~/.bash_profile)
export PATH="/opt/homebrew/bin:$PATH"

# Or run directly with the new bash
/opt/homebrew/bin/bash ./tinyclaw.sh start
```

### WhatsApp not connecting

```bash
# Check logs
./tinyclaw.sh logs whatsapp

# Reset WhatsApp authentication
./tinyclaw.sh channels reset whatsapp
./tinyclaw.sh restart
```

### Discord not connecting

```bash
# Check logs
./tinyclaw.sh logs discord

# Update Discord bot token
./tinyclaw.sh setup
```

### Telegram not connecting

```bash
# Check logs
./tinyclaw.sh logs telegram

# Update Telegram bot token
./tinyclaw.sh setup
```

### Messages not processing

```bash
# Check queue processor
./tinyclaw.sh status

# Check queue
ls -la .tinyclaw/queue/incoming/

# View queue logs
./tinyclaw.sh logs queue
```

### QR code not showing

```bash
# Attach to tmux to see the QR code
tmux attach -t tinyclaw
```

## 🚀 Production Deployment

### Using Docker Compose (Recommended for VPS/Coolify)

Docker deployment is perfect for hosting on VPS platforms like Coolify, with support for custom API endpoints and environment-based configuration.

#### Step 1: Configure Environment Variables

Copy the example environment file and edit it:

```bash
cp .env.example .env
nano .env  # or use your preferred editor
```

Set the following required variables in `.env`:

```bash
# Bot Tokens
DISCORD_BOT_TOKEN=your_discord_bot_token_here
TELEGRAM_BOT_TOKEN=your_telegram_bot_token_here

# Claude API Configuration
ANTHROPIC_API_KEY=your_anthropic_api_key_here
ANTHROPIC_BASE_URL=https://api.anthropic.com  # Optional: custom endpoint
ANTHROPIC_MODEL=claude-sonnet-4-5              # Optional: custom model ID

# TinyClaw Configuration
TINYCLAW_CHANNELS=telegram,discord  # Comma-separated list
TINYCLAW_HEARTBEAT_INTERVAL=3600    # Seconds
```

#### Step 2: Deploy with Docker Compose

```bash
# Build and start the container
docker-compose up -d

# View logs
docker-compose logs -f

# Stop the container
docker-compose down

# Rebuild after changes
docker-compose up -d --build
```

#### Step 3: WhatsApp QR Code (if enabled)

To scan the WhatsApp QR code:

```bash
# View container logs to see the QR code
docker-compose logs -f tinyclaw
```

Scan the QR code with your phone. The session will persist in the `whatsapp-session` volume.

#### Deployment on Coolify

1. Fork/clone this repository
2. In Coolify, create a new resource → Docker Compose
3. Point to your repository
4. Set environment variables in Coolify's UI (same as above)
5. Deploy!

Coolify will automatically:
- Build the Docker image
- Set environment variables
- Manage container lifecycle
- Handle logs and monitoring

#### Volume Persistence

Docker Compose mounts these directories for persistence:
- `whatsapp-session/`: WhatsApp session data (persisted in named volume)
- `logs/`: Application logs
- `queue/`: Message queue data

**Note:** Configuration is managed through environment variables (not a mounted file). The `settings.json` file is automatically generated at container startup from the environment variables you set.

### Using Docker (Manual)

```bash
# Build the image
docker build -t tinyclaw .

# Run with environment variables
docker run -d \
  --name tinyclaw \
  -e DISCORD_BOT_TOKEN="your_token" \
  -e TELEGRAM_BOT_TOKEN="your_token" \
  -e ANTHROPIC_API_KEY="your_api_key" \
  -e ANTHROPIC_MODEL="claude-sonnet-4-5" \
  -e TINYCLAW_CHANNELS="telegram,discord" \
  -v tinyclaw-whatsapp:/app/.tinyclaw/whatsapp-session \
  -v ./logs:/app/.tinyclaw/logs \
  tinyclaw

# View logs
docker logs -f tinyclaw

# Stop container
docker stop tinyclaw
```

### Using systemd

```bash
sudo systemctl enable tinyclaw
sudo systemctl start tinyclaw
```

### Using PM2

```bash
pm2 start tinyclaw.sh --name tinyclaw
pm2 save
```

### Using supervisor

```ini
[program:tinyclaw]
command=/path/to/tinyclaw/tinyclaw.sh start
autostart=true
autorestart=true
```

### Custom API Configuration (Non-Docker)

If running without Docker, you can configure custom API settings through the setup wizard:

```bash
./tinyclaw.sh setup
```

The wizard will prompt you for:
- API Key (leave empty to use Claude Code default)
- Base URL (default: https://api.anthropic.com)
- Custom Model ID (optional, e.g., for fine-tuned models)

These settings are saved in `.tinyclaw/settings.json` and used for all API calls.

## 🎯 Use Cases

### Personal AI Assistant

```
You: "Remind me to call mom"
Claude: "I'll remind you!"
[5 minutes later via heartbeat]
Claude: "Don't forget to call mom!"
```

### Code Helper

```
You: "Review my code"
Claude: [reads files, provides feedback]
You: "Fix the bug"
Claude: [fixes and commits]
```

### Multi-Device

- WhatsApp on phone
- Discord on desktop/mobile
- Telegram on any device
- CLI for scripts

All channels share the same Claude conversation!

## Star History

[![Star History Chart](https://api.star-history.com/svg?repos=jlia0/tinyclaw&type=date&legend=top-left)](https://www.star-history.com/#jlia0/tinyclaw&type=date&legend=top-left)

## 🙏 Credits

- Inspired by [OpenClaw](https://openclaw.ai/) by Peter Steinberger
- Built on [Claude Code](https://claude.com/claude-code)
- Uses [discord.js](https://discord.js.org/)
- Uses [whatsapp-web.js](https://github.com/pedroslopez/whatsapp-web.js)

## 📄 License

MIT

---

**TinyClaw - Small but mighty!** 🦞✨
