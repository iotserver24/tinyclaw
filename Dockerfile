FROM node:18-slim

# Install system dependencies
RUN apt-get update && apt-get install -y \
    bash \
    tmux \
    curl \
    jq \
    && rm -rf /var/lib/apt/lists/*

# Install Claude Code CLI
RUN curl -fsSL https://claude.com/install.sh | bash

# Set working directory
WORKDIR /app

# Copy package files
COPY package*.json ./

# Install Node.js dependencies
RUN PUPPETEER_SKIP_DOWNLOAD=true npm install

# Copy application files
COPY . .

# Build TypeScript
RUN npm run build

# Create required directories
RUN mkdir -p .tinyclaw/queue/incoming .tinyclaw/queue/outgoing .tinyclaw/queue/processing .tinyclaw/logs

# Make scripts executable
RUN chmod +x tinyclaw.sh setup-wizard.sh heartbeat-cron.sh docker-init.sh

# Set environment variable for Claude
ENV PATH="/root/.local/bin:${PATH}"

# Expose any required ports (if needed in the future)
# EXPOSE 3000

# Default command - initialize from env vars and start TinyClaw
CMD ["bash", "-c", "./docker-init.sh && ./tinyclaw.sh start"]
