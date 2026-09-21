#!/bin/bash
# PostToolUse hook: cache ctx_stats savings % to /tmp/ctx-stats-cache.json
input=$(cat)
tool_name=$(echo "$input" | jq -r '.tool_name // empty')

[[ "$tool_name" != *"ctx_stats"* ]] && exit 0

response=$(echo "$input" | jq -r '.tool_response // empty')
pct=$(echo "$response" | grep -oP '\(\K[\d.]+(?=% reduction\))')

[ -n "$pct" ] && echo "{\"pct\": \"$pct\"}" > /tmp/ctx-stats-cache.json
exit 0
