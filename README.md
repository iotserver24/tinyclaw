# TinyClaw Simple

The simplest TinyClaw implementation using `claude -c -p` for clean response handling.

## Architecture

```
┌─────────────────────────────────────┐
│     Tmux Session (tinyclaw)         │
│                                     │
│  ┌────────────────────────────────┐│
│  │ whatsapp-monitor.sh            ││
│  │ - Polls queue for messages     ││
│  │ - Calls: claude -c -p "$msg"   ││
│  │ - Gets clean final response    ││
│  │ - Saves response for WhatsApp  ││
│  └────────────────────────────────┘│
│                                     │
│  ┌────────────────────────────────┐│
│  │ heartbeat-cron.sh              ││
│  │ - Every 5 minutes              ││
│  │ - Calls: claude -c -p "$prompt"││
│  │ - Keeps Claude active          ││
│  └────────────────────────────────┘│
└─────────────────────────────────────┘
         │                │
         ▼                ▼
    WhatsApp         Heartbeat
    Response         Logging
```

## Key Innovation

Uses `claude -c -p` (continue + print mode):

- `-c` = continue previous conversation
- `-p` = print mode (returns just final response)
- No tmux capture needed!
- Clean, parseable output

## Setup

```bash
cd /Users/jliao/workspace/tinyclaw-simple

# Make executable
chmod +x *.sh .claude/hooks/*.sh

# Start daemon
./tinyclaw.sh start

# Check status
./tinyclaw.sh status
```

## Usage

### Send Message Manually

```bash
./tinyclaw.sh send "What's the status?"
```

### WhatsApp Integration

**From your WhatsApp bot/webhook:**

```bash
# Queue a message
./whatsapp-webhook.sh "user123" "Check the logs"

# Returns the response (waits up to 30s)
```

**Example with curl (for HTTP webhook):**

```bash
# Simple HTTP webhook wrapper
curl -X POST http://your-server/whatsapp \
  -d "sender=user123" \
  -d "message=Check status"
```

### Heartbeat

Automatically runs every 5 minutes. Edit `.tinyclaw/heartbeat.md` to customize:

```markdown
Check for:

1. Pending GitHub issues
2. Failed CI/CD jobs
3. Unread notifications

If found, take action. Otherwise say "All clear."
```

## Components

### 1. tinyclaw.sh

Main orchestrator:

- Starts tmux session
- Launches monitor and heartbeat
- Provides CLI interface

### 2. whatsapp-monitor.sh

Monitors queue directory for messages:

- Polls `.tinyclaw/whatsapp_queue/*.msg`
- Sends to Claude via `claude -c -p`
- Saves response for pickup

### 3. heartbeat-cron.sh

Periodic health check:

- Runs every 5 minutes (configurable)
- Keeps conversation active
- Logs responses

### 4. whatsapp-webhook.sh

Webhook receiver:

- Queues incoming messages
- Waits for response
- Returns to caller

## Hooks

Uses Claude Code hooks in `.claude/settings.json`:

- **SessionStart**: Announces TinyClaw is active
- **PostToolUse**: Logs all activity

Hooks are lightweight - main logic is in the daemon scripts.

## Message Flow

### Incoming WhatsApp Message

```
1. WhatsApp webhook receives message
2. Calls: ./whatsapp-webhook.sh "user" "message"
3. Creates: .tinyclaw/whatsapp_queue/user.msg
4. whatsapp-monitor.sh detects file
5. Runs: claude -c -p "message"
6. Gets clean response
7. Saves: .tinyclaw/whatsapp_queue/response_user.txt
8. webhook.sh reads response
9. Returns to WhatsApp
```

### Heartbeat Flow

```
1. Every 5 minutes
2. Reads: .tinyclaw/heartbeat.md
3. Runs: claude -c -p "$prompt"
4. Logs response
5. Keeps session active
```

## Advantages

✅ **Clean responses** - `claude -c -p` returns just the answer
✅ **No parsing** - No need to extract from tmux output
✅ **Conversation continuity** - `-c` maintains context
✅ **Simple** - No complex tmux capture logic
✅ **Reliable** - Built-in Claude feature

## Testing

### Test WhatsApp Flow

```bash
# Terminal 1: Start daemon
./tinyclaw.sh start

# Terminal 2: Send message via webhook
./whatsapp-webhook.sh "testuser" "What's 2+2?"

# Should return: "4" (or Claude's response)
```

### Test Heartbeat

```bash
# Watch heartbeat log
tail -f .tinyclaw/logs/heartbeat.log

# Should see updates every 5 minutes
```

### Test Manual Message

```bash
./tinyclaw.sh send "Hello Claude!"
```

## Logs

```bash
# All logs
ls .tinyclaw/logs/

# Main daemon log
tail -f .tinyclaw/logs/daemon.log

# WhatsApp activity
tail -f .tinyclaw/logs/whatsapp.log

# Heartbeat checks
tail -f .tinyclaw/logs/heartbeat.log

# Tool usage
tail -f .tinyclaw/logs/activity.log
```

## Configuration

### Adjust Heartbeat Interval

Edit `heartbeat-cron.sh`:

```bash
INTERVAL=300  # Change to desired seconds
```

### Customize Heartbeat Prompt

Edit `.tinyclaw/heartbeat.md`:

```markdown
Your custom prompt here
```

## WhatsApp Integration Examples

### Using Twilio

```python
# Flask webhook
from flask import Flask, request
import subprocess

app = Flask(__name__)

@app.route('/whatsapp', methods=['POST'])
def whatsapp():
    sender = request.form['From']
    message = request.form['Body']

    # Call webhook script
    result = subprocess.run(
        ['./whatsapp-webhook.sh', sender, message],
        capture_output=True,
        text=True
    )

    return result.stdout
```

### Using WhatsApp Web.js

```javascript
// Node.js integration
const { Client } = require("whatsapp-web.js");
const { execSync } = require("child_process");

client.on("message", async (msg) => {
  const response = execSync(
    `./whatsapp-webhook.sh "${msg.from}" "${msg.body}"`,
    { encoding: "utf-8" },
  );

  await msg.reply(response);
});
```

## Troubleshooting

### Messages not processing

```bash
# Check monitor is running
pgrep -f "whatsapp-monitor.sh"

# Check queue
ls -la .tinyclaw/whatsapp_queue/

# View monitor log
tail -f .tinyclaw/logs/whatsapp.log
```

### Heartbeat not firing

```bash
# Check process
pgrep -f "heartbeat-cron.sh"

# Check log
tail -f .tinyclaw/logs/heartbeat.log

# Restart daemon
./tinyclaw.sh restart
```

### Session not continuing

```bash
# Check session exists
claude --resume

# Check tmux session
tmux attach -t tinyclaw
```

## Production Deployment

For production, use a process manager:

```bash
# Using systemd
sudo systemctl enable tinyclaw
sudo systemctl start tinyclaw

# Or PM2
pm2 start tinyclaw.sh --name tinyclaw

# Or supervisor
[program:tinyclaw]
command=/path/to/tinyclaw.sh start
```

## Comparison

| Feature         | TinyClaw Simple    | TinyClaw Full | Hooks-Only   |
| --------------- | ------------------ | ------------- | ------------ |
| Clean responses | ✅ `claude -c -p`  | ⚠️ Complex    | ❌           |
| WhatsApp        | ✅ Via webhook     | ✅ Native     | ⚠️ Manual    |
| Heartbeat       | ✅ Cron script     | ✅            | ✅ Stop hook |
| Tmux            | ✅ For persistence | ✅            | ❌           |
| Simplicity      | ✅✅               | ⚠️            | ✅           |

## License

MIT

## Credits

- Inspired by [TinyClaw](https://tinyclaw.ai/)
- Built on [Claude Code](https://claude.com/claude-code)
- Uses native `claude -c -p` feature
