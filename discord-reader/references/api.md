# Discord API Reference

Load this file when debugging API issues or needing additional endpoints.

## Base URL
`https://discord.com/api/v10`

## Authentication
Header: `Authorization: USER_TOKEN` (no "Bot" prefix for user tokens)

## Endpoints

### Search
`GET /guilds/{guild_id}/messages/search`

| Param | Description |
|-------|-------------|
| content | Search text |
| author_id | Filter by author |
| channel_id | Filter by channel |
| has | link, file, embed, image, video, sticker |
| before | Snowflake ID or ISO date |
| after | Snowflake ID or ISO date |
| limit | Max 25 (default 25) |
| offset | For pagination |

Response: `{"messages": [[msg1], [msg2]], "total_results": N}`

### Messages
`GET /channels/{channel_id}/messages`

| Param | Description |
|-------|-------------|
| limit | 1-100, default 50 |
| before | Get messages before this ID |
| after | Get messages after this ID |
| around | Get messages around this ID |

Response: Array of message objects.

### Channels
`GET /guilds/{guild_id}/channels`

Response: Array of channel objects with `id`, `name`, `type`, `topic`, `parent_id`.

Channel types: 0=text, 2=voice, 4=category, 5=announcement, 10/11/12=threads, 13=stage, 15=forum.

### Threads
`GET /guilds/{guild_id}/threads/active` - All active threads in guild
`GET /channels/{channel_id}/threads/archived/public` - Archived public threads in channel
`GET /channels/{channel_id}/threads/archived/private` (if member)

Response for active: `{"threads": [...], "members": [...]}`
Response for archived: `{"threads": [...], "has_more": bool}`

### Single Channel/Thread Info
`GET /channels/{channel_id}`

## Rate Limits

User accounts have stricter limits than bots. If 429 returned, respect `Retry-After` header.

## Snowflake IDs

Discord IDs encode timestamp. To convert:
```python
timestamp = ((snowflake >> 22) + 1420070400000) / 1000
```
