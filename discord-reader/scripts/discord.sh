#!/bin/bash
# Discord API wrapper for Claude Code
# Config: ~/.config/discord-claude/config.json

set -e

CONFIG_FILE="${DISCORD_CONFIG:-$HOME/.config/discord-claude/config.json}"

if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "Error: Config not found at $CONFIG_FILE" >&2
    echo "Create it with: {\"token\": \"YOUR_TOKEN\", \"guild\": \"GUILD_ID\"}" >&2
    exit 1
fi

TOKEN=$(jq -r '.token' "$CONFIG_FILE")
DEFAULT_GUILD=$(jq -r '.guild' "$CONFIG_FILE")

if [[ "$TOKEN" == "null" || -z "$TOKEN" ]]; then
    echo "Error: token not set in config" >&2
    exit 1
fi

API="https://discord.com/api/v10"

discord_api() {
    curl -sS -H "Authorization: $TOKEN" "$@"
}

# Convert date to Discord snowflake ID
# Discord epoch: 2015-01-01 00:00:00 UTC = 1420070400000 ms
date_to_snowflake() {
    local date_str="$1"
    local ts_ms
    if [[ "$OSTYPE" == "darwin"* ]]; then
        ts_ms=$(($(date -j -f "%Y-%m-%d" "$date_str" +%s 2>/dev/null || date -j -v"$date_str" +%s 2>/dev/null || date -j -f "%Y-%m-%dT%H:%M:%S" "$date_str" +%s 2>/dev/null || date +%s) * 1000))
    else
        ts_ms=$(($(date -d "$date_str" +%s) * 1000))
    fi
    echo $(( (ts_ms - 1420070400000) << 22 ))
}

# Parse relative time like "7d", "24h", "2w" to a date
relative_to_date() {
    local spec="$1"
    local num="${spec%[dhwmH]}"
    local unit="${spec: -1}"
    case "$unit" in
        d|h|w|m|H)
            if [[ "$OSTYPE" == "darwin"* ]]; then
                # macOS: -v-4d, -v-24H, -v-2w, -v-1m
                local mac_unit="$unit"
                [[ "$unit" == "h" ]] && mac_unit="H"  # macOS uses H for hours
                date -v"-${num}${mac_unit}" +%Y-%m-%d
            else
                local gnu_unit
                case "$unit" in
                    d) gnu_unit="days" ;;
                    h|H) gnu_unit="hours" ;;
                    w) gnu_unit="weeks" ;;
                    m) gnu_unit="months" ;;
                esac
                date -d "-${num} ${gnu_unit}" +%Y-%m-%d
            fi
            ;;
        *) echo "$spec" ;;  # Not relative, return as-is (assumed YYYY-MM-DD)
    esac
}

# Fetch all messages from a channel with pagination, filtered by time
fetch_all_messages() {
    local channel_id="$1"
    local after_snowflake="$2"
    local before_snowflake="$3"
    local all_messages="[]"
    local before_id=""
    local batch
    local count=0
    local max_iterations=100  # Safety limit: 100 * 100 = 10000 messages per channel

    while [[ $count -lt $max_iterations ]]; do
        local url="$API/channels/$channel_id/messages?limit=100"
        [[ -n "$before_id" ]] && url="$url&before=$before_id"

        batch=$(discord_api "$url" 2>/dev/null) || break

        # Check for valid response
        if ! echo "$batch" | jq -e 'type == "array"' >/dev/null 2>&1; then
            break
        fi

        local batch_len=$(echo "$batch" | jq 'length')
        [[ "$batch_len" -eq 0 ]] && break

        # Filter by time window
        if [[ -n "$after_snowflake" || -n "$before_snowflake" ]]; then
            batch=$(echo "$batch" | jq --arg after "$after_snowflake" --arg before "$before_snowflake" '
                [.[] | select(
                    (if $after != "" then (.id | tonumber) >= ($after | tonumber) else true end) and
                    (if $before != "" then (.id | tonumber) <= ($before | tonumber) else true end)
                )]
            ')
        fi

        all_messages=$(echo "$all_messages" "$batch" | jq -s 'add')

        # Get oldest message ID for next page
        before_id=$(echo "$batch" | jq -r 'last.id // empty')
        [[ -z "$before_id" ]] && break

        # If we got less than 100, we're done
        [[ "$batch_len" -lt 100 ]] && break

        # If oldest message is before our window, stop
        if [[ -n "$after_snowflake" ]]; then
            local oldest_id=$(echo "$batch" | jq -r 'last.id')
            [[ $(echo "$oldest_id < $after_snowflake" | bc) -eq 1 ]] && break
        fi

        ((count++))
        sleep 0.5  # Rate limit protection
    done

    echo "$all_messages"
}

cmd="$1"
shift || true

case "$cmd" in
    search)
        # Usage: discord.sh search "keyword" [channel_id] [author_id]
        guild="${DEFAULT_GUILD}"
        encoded=$(python3 -c "import urllib.parse; print(urllib.parse.quote('$1'))")
        query="content=$encoded"
        [[ -n "$2" ]] && query="$query&channel_id=$2"
        [[ -n "$3" ]] && query="$query&author_id=$3"
        discord_api "$API/guilds/$guild/messages/search?$query"
        ;;

    read)
        # Usage: discord.sh read <channel_id> [limit]
        channel="$1"
        limit="${2:-50}"
        discord_api "$API/channels/$channel/messages?limit=$limit"
        ;;

    channels)
        # Usage: discord.sh channels [guild_id] [--raw]
        # Filters to readable channels, groups by category
        guild="${1:-$DEFAULT_GUILD}"
        if [[ "$1" == "--raw" || "$2" == "--raw" ]]; then
            discord_api "$API/guilds/$guild/channels"
        else
            discord_api "$API/guilds/$guild/channels" | jq '
                # Type name mapping
                def type_name:
                    if . == 0 then "text"
                    elif . == 2 then "voice"
                    elif . == 4 then "category"
                    elif . == 5 then "announcement"
                    elif . == 10 then "thread"
                    elif . == 11 then "thread"
                    elif . == 12 then "thread"
                    elif . == 13 then "stage"
                    elif . == 15 then "forum"
                    else "other" end;

                # Get categories for grouping
                (map(select(.type == 4)) | map({(.id): .name}) | add) as $cats |

                # Filter to actual channels, add category name
                [.[] | select(.type != 4 and .type != 2 and .type != 13)] |
                map({
                    name,
                    id,
                    type: (.type | type_name),
                    category: (if .parent_id then $cats[.parent_id] else null end)
                }) |
                sort_by(.category // "zzz", .position)
            '
        fi
        ;;

    threads)
        # Usage: discord.sh threads <channel_id>
        channel="$1"
        discord_api "$API/channels/$channel/threads/archived/public"
        ;;

    thread)
        # Usage: discord.sh thread <thread_id> [limit]
        # Threads are channels, so same as read
        thread="$1"
        limit="${2:-100}"
        discord_api "$API/channels/$thread/messages?limit=$limit"
        ;;

    raw)
        # Usage: discord.sh raw <endpoint>
        # For direct API access
        discord_api "$API/$1"
        ;;

    dump)
        # Usage: discord.sh dump [--since DATE|RELATIVE] [--until DATE] [--grep PATTERN]
        # Uses guild search API - single paginated query for all messages in time window
        # Examples:
        #   discord.sh dump --since 7d                    # Last 7 days
        #   discord.sh dump --since 2024-01-01            # Since date
        #   discord.sh dump --since 7d --grep "bug"       # Filter by content
        guild="$DEFAULT_GUILD"
        since=""
        until_date=""
        grep_pattern=""

        while [[ $# -gt 0 ]]; do
            case "$1" in
                --since) since="$2"; shift 2 ;;
                --until) until_date="$2"; shift 2 ;;
                --grep) grep_pattern="$2"; shift 2 ;;
                --guild) guild="$2"; shift 2 ;;
                *) shift ;;
            esac
        done

        # Build search query params
        query=""
        if [[ -n "$since" ]]; then
            since_date=$(relative_to_date "$since")
            after_snowflake=$(date_to_snowflake "$since_date")
            query="min_id=$after_snowflake"
        fi
        if [[ -n "$until_date" ]]; then
            until_resolved=$(relative_to_date "$until_date")
            before_snowflake=$(date_to_snowflake "$until_resolved")
            [[ -n "$query" ]] && query="$query&"
            query="${query}max_id=$before_snowflake"
        fi

        # Paginate through search results (25 per page max)
        all_messages="[]"
        offset=0
        total_results=0
        max_offset=5000  # Safety limit

        echo "Searching messages since $since..." >&2

        while [[ $offset -lt $max_offset ]]; do
            url="$API/guilds/$guild/messages/search?$query&limit=25&offset=$offset"
            response=$(discord_api "$url" 2>/dev/null)

            # Check for errors
            if echo "$response" | jq -e '.message' >/dev/null 2>&1; then
                echo "API error: $(echo "$response" | jq -r '.message')" >&2
                break
            fi

            # Get total on first request
            if [[ $offset -eq 0 ]]; then
                total_results=$(echo "$response" | jq '.total_results // 0')
                echo "Found $total_results total messages" >&2
            fi

            # Extract messages (search returns nested arrays)
            batch=$(echo "$response" | jq '[.messages[][] ]')
            batch_len=$(echo "$batch" | jq 'length')

            [[ "$batch_len" -eq 0 ]] && break

            all_messages=$(echo "$all_messages" "$batch" | jq -s 'add')

            fetched=$(echo "$all_messages" | jq 'length')
            echo "  Fetched $fetched / $total_results messages..." >&2

            # If we got everything, stop
            [[ $fetched -ge $total_results ]] && break

            offset=$((offset + 25))
            sleep 1  # Rate limit - be gentle with search API
        done

        # Apply grep filter if specified
        if [[ -n "$grep_pattern" ]]; then
            all_messages=$(echo "$all_messages" | jq --arg pat "$grep_pattern" \
                '[.[] | select(.content | test($pat; "i"))]')
        fi

        # Build result with metadata
        result=$(jq -n \
            --arg guild "$guild" \
            --arg since "$since" \
            --arg until "$until_date" \
            --arg grep "$grep_pattern" \
            --argjson messages "$all_messages" \
            --argjson total "$total_results" \
            '{
                meta: {
                    guild: $guild,
                    since: $since,
                    until: (if $until == "" then null else $until end),
                    grep: (if $grep == "" then null else $grep end),
                    dumped_at: (now | todate),
                    total_results: $total,
                    fetched: ($messages | length)
                },
                messages: $messages
            }')

        # Add channel summary
        result=$(echo "$result" | jq '
            .meta.channels = (
                [.messages[] | {id: .channel_id, name: (.channel_id)}] |
                group_by(.id) |
                map({channel_id: .[0].id, count: length}) |
                sort_by(-.count)
            ) |
            .meta.authors = (
                [.messages[] | .author.username] |
                group_by(.) |
                map({author: .[0], count: length}) |
                sort_by(-.count) |
                .[0:20]
            )
        ')

        echo "$result"
        ;;

    *)
        echo "Usage: discord.sh <command> [args]"
        echo "Commands: search, read, channels, threads, thread, dump, raw"
        exit 1
        ;;
esac
