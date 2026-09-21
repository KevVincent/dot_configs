#!/bin/bash
# Claude Code statusline: caveman badge + context window usage

input=$(cat)

# --- Model info (session-specific) ---
model=""
# Try to get display_name from model object in stdin
model_from_stdin=$(echo "$input" | jq -r '.model.display_name // .model // empty' 2>/dev/null)
if [ -n "$model_from_stdin" ]; then
  model="$model_from_stdin"
fi
# If not in stdin, try environment variable
if [ -z "$model" ] && [ -n "${CLAUDE_MODEL:-}" ]; then
  model="$CLAUDE_MODEL"
fi
model_part=""
if [ -n "$model" ]; then
  model_part=$(printf '\033[38;5;177m%s\033[0m' "$model")
fi

# --- Caveman badge ---
caveman=$(bash "/home/kv26qzx/.claude/plugins/cache/caveman/caveman/84cc3c14fa1e/hooks/caveman-statusline.sh" <<< "")

# --- Context window usage ---
used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')

if [ -n "$used" ]; then
  used_int=$(printf '%.0f' "$used")
  ctx_part=$(printf '\033[38;5;39mCtx:%d%%\033[0m' "$used_int")
else
  ctx_part=""
fi

# --- Session usage (Claude.ai subscription rate limits) ---
five_pct=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
seven_pct=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
resets_at=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')

usage_part=""
if [ -n "$five_pct" ]; then
  five_int=$(printf '%.0f' "$five_pct")
  usage_part=$(printf '\033[38;5;214mUsage:%d%%\033[0m' "$five_int")
elif [ -n "$seven_pct" ]; then
  seven_int=$(printf '%.0f' "$seven_pct")
  usage_part=$(printf '\033[38;5;214mUsage:%d%%\033[0m' "$seven_int")
fi

# --- Reset time ---
reset_part=""
if [ -n "$resets_at" ]; then
  reset_fmt=$(TZ="Europe/Berlin" date -d "@${resets_at}" +"%l%P" 2>/dev/null | tr -d ' ')
  [ -n "$reset_fmt" ] && reset_part=$(printf '\033[38;5;244mRst:%s\033[0m' "$reset_fmt")
fi

# --- Ctx savings (cached from last ctx_stats call) ---
ctx_saved_part=""
if [ -f /tmp/ctx-stats-cache.json ]; then
  pct=$(jq -r '.pct // empty' /tmp/ctx-stats-cache.json 2>/dev/null)
  if [ -n "$pct" ]; then
    pct_int=$(printf '%.0f' "$pct")
    ctx_saved_part=$(printf '\033[38;5;46mSaved:%d%%\033[0m' "$pct_int")
  fi
fi

# --- Session cost (actual from Claude Code) ---
api_cost_part=""
session_cost=$(echo "$input" | jq -r '.cost.total_cost_usd // empty' 2>/dev/null)
if [ -n "$session_cost" ]; then
  api_cost_part=$(printf '\033[38;5;226m$%.2f\033[0m' "$session_cost")
fi

# --- One-time credit (cached; refreshed via Anthropic usage API) ---
# Statusline input has no credit data, so fetch GET /api/oauth/usage with the
# claude.ai OAuth token. Cache to disk and refresh in the background (5 min TTL)
# so the render never blocks on the network call.
credit_cache=/tmp/claude-credit-cache.json
credit_max_age=300
needs_refresh=1
if [ -f "$credit_cache" ]; then
  age=$(( $(date +%s) - $(stat -c %Y "$credit_cache" 2>/dev/null || echo 0) ))
  [ "$age" -lt "$credit_max_age" ] && needs_refresh=0
fi
if [ "$needs_refresh" -eq 1 ]; then
  (
    tok=$(jq -r '.claudeAiOauth.accessToken' ~/.claude/.credentials.json 2>/dev/null)
    [ -n "$tok" ] && curl -s --max-time 5 https://api.anthropic.com/api/oauth/usage \
      -H "Authorization: Bearer $tok" -H "Content-Type: application/json" \
      > "${credit_cache}.tmp" 2>/dev/null && mv "${credit_cache}.tmp" "$credit_cache"
  ) >/dev/null 2>&1 &
fi
credit_part=""
if [ -f "$credit_cache" ]; then
  util=$(jq -r '.cinder_cove.utilization // empty' "$credit_cache" 2>/dev/null)
  exp=$(jq -r '.cinder_cove.resets_at // empty' "$credit_cache" 2>/dev/null)
  if [ -n "$util" ]; then
    util_int=$(printf '%.0f' "$util")
    exp_fmt=""
    [ -n "$exp" ] && exp_fmt=$(date -d "$exp" +"%b%-d" 2>/dev/null)
    if [ -n "$exp_fmt" ]; then
      credit_part=$(printf '\033[38;5;208mCredit:%d%% Exp:%s\033[0m' "$util_int" "$exp_fmt")
    else
      credit_part=$(printf '\033[38;5;208mCredit:%d%%\033[0m' "$util_int")
    fi
  fi
fi

# --- Combine ---
parts=""
[ -n "$caveman" ] && parts="$caveman"
[ -n "$model_part" ] && parts="${parts:+$parts }$model_part"
[ -n "$api_cost_part" ] && parts="${parts:+$parts }$api_cost_part"
[ -n "$credit_part" ] && parts="${parts:+$parts }$credit_part"
[ -n "$ctx_part" ] && parts="${parts:+$parts }$ctx_part"
[ -n "$usage_part" ] && parts="${parts:+$parts }$usage_part"
[ -n "$reset_part" ] && parts="${parts:+$parts }$reset_part"
[ -n "$ctx_saved_part" ] && parts="${parts:+$parts }$ctx_saved_part"
printf '%s' "$parts"
