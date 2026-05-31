---
name: discord-reader
description: Read-only Discord server navigation via REST API. Use when the user wants to search Discord messages, read channel history, read threads, summarize server activity, or dump all messages from a time period. Triggers on mentions of Discord, server discussions, channel names prefixed with #, "this week on discord", or requests to find/search conversations.
---

# Discord Reader

Read-only access to a Discord server. Uses user token for full search capability.

## Setup

Config at `~/.config/discord-claude/config.json`:
```json
{"token": "USER_TOKEN", "guild": "GUILD_ID"}
```

Get token: DevTools → Network → any Discord request → Authorization header.
Get guild ID: Enable Developer Mode → right-click server → Copy ID.

## Full Server Dump (Primary Workflow)

For comprehensive analysis ("this week on the server", activity summaries, etc.), use `dump` to get ALL messages across ALL channels and threads for a time window:

```bash
# Last 7 days - all channels and threads
~/.claude/skills/discord-reader/scripts/discord.sh dump --since 7d

# Last 24 hours
~/.claude/skills/discord-reader/scripts/discord.sh dump --since 24h

# Date range
~/.claude/skills/discord-reader/scripts/discord.sh dump --since 2024-01-01 --until 2024-01-31

# Single channel only
~/.claude/skills/discord-reader/scripts/discord.sh dump --since 7d --channel CHANNEL_ID

# With content filter (case-insensitive regex)
~/.claude/skills/discord-reader/scripts/discord.sh dump --since 7d --grep "bug|issue"
```

**Time formats**: `7d` (days), `24h` (hours), `2w` (weeks), `1m` (months), or `YYYY-MM-DD`.

**Output structure**:
```json
{
  "meta": {
    "guild": "...",
    "since": "7d",
    "dumped_at": "2024-01-15T...",
    "stats": {
      "total_channels": 12,
      "total_threads": 45,
      "total_messages": 892,
      "channels_with_messages": ["general", "dev", ...]
    }
  },
  "channels": [
    {"id": "...", "name": "general", "messages": [...]},
    ...
  ],
  "threads": [
    {"id": "...", "name": "Thread Name", "parent_channel": "...", "messages": [...]},
    ...
  ]
}
```

Save to file for analysis:
```bash
~/.claude/skills/discord-reader/scripts/discord.sh dump --since 7d > server_dump.json
```

## Quick Reference

For targeted queries when you don't need everything:

### Search messages
```bash
~/.claude/skills/discord-reader/scripts/discord.sh search "keyword"
~/.claude/skills/discord-reader/scripts/discord.sh search "keyword" CHANNEL_ID
~/.claude/skills/discord-reader/scripts/discord.sh search "keyword" "" AUTHOR_ID
```

### Read single channel
```bash
~/.claude/skills/discord-reader/scripts/discord.sh read CHANNEL_ID 50
```

### Read single thread
```bash
~/.claude/skills/discord-reader/scripts/discord.sh thread THREAD_ID 100
```

### List channels
```bash
~/.claude/skills/discord-reader/scripts/discord.sh channels
```

## Output Handling

Dump output is self-contained JSON. Extract readable content:
```bash
# From dump - all messages with context
jq '.channels[], .threads[] | .name as $ch | .messages[] | {channel: $ch, author: .author.username, content, timestamp}' dump.json

# Group by author
jq '[.channels[].messages[], .threads[].messages[]] | group_by(.author.username) | map({author: .[0].author.username, count: length})' dump.json
```

## Common Workflows

**Weekly summary**: `dump --since 7d`, then analyze the JSON for activity patterns, hot topics, key discussions.

**Find discussion on topic**: Use `dump --since 30d --grep "topic"` for comprehensive results, or `search` for quick hits.

**Audit activity**: Dump a time range, filter by author or channel in jq.
