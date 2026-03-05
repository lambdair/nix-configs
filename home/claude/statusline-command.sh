#!/usr/bin/env bash
input=$(cat)

# === Parse stdin JSON ===
eval "$(echo "$input" | jq -r '
  [
    "model=\(.model.display_name // "Unknown" | @sh)",
    "ctx_pct=\(.context_window.used_percentage // 0 | round)",
    "add=\(.cost.total_lines_added // 0)",
    "del=\(.cost.total_lines_removed // 0)",
    "cwd=\(.cwd // "." | @sh)"
  ] | .[]')"

# === VCS info (jj preferred, git fallback) ===
vcs_info=""
if jj log --no-pager -R "$cwd" -r @ --no-graph -T 'change_id.shortest()' >/dev/null 2>&1; then
  jj_rev=$(jj log --no-pager -R "$cwd" -r @ --no-graph -T 'change_id.shortest()' 2>/dev/null)
  jj_bookmarks=$(jj log --no-pager -R "$cwd" -r @ --no-graph -T 'bookmarks.map(|b| b.name()).join(" ")' 2>/dev/null | awk '{print $1}')
  if [ -n "$jj_bookmarks" ]; then
    vcs_info="${jj_bookmarks} (${jj_rev})"
  else
    vcs_info="${jj_rev}"
  fi
else
  branch=$(git -C "$cwd" branch --show-current 2>/dev/null)
  [ -z "$branch" ] && branch=$(git -C "$cwd" rev-parse --short HEAD 2>/dev/null || echo "?")
  vcs_info="$branch"
fi

# === ANSI Colors (24-bit true color) ===
G=$'\033[38;2;151;201;195m'   # green  0-49%
Y=$'\033[38;2;229;192;123m'   # yellow 50-79%
R=$'\033[38;2;224;108;117m'   # red    80-100%
D=$'\033[38;2;74;88;92m'      # grey   delimiters
N=$'\033[0m'                   # reset

cpct() {
  local p=${1:-0}
  if [ "$p" -ge 80 ] 2>/dev/null; then printf '%s' "$R"
  elif [ "$p" -ge 50 ] 2>/dev/null; then printf '%s' "$Y"
  else printf '%s' "$G"; fi
}

# === Progress bar (▰▱ × 10 segments) ===
bar() {
  local p=${1:-0} f=$(( (${1:-0} + 5) / 10 )) b=""
  [ "$f" -gt 10 ] && f=10; [ "$f" -lt 0 ] && f=0
  for ((i=0; i<f; i++)); do b+="▰"; done
  for ((i=0; i<10-f; i++)); do b+="▱"; done
  printf '%s' "$b"
}

# === Configuration ===
DISPLAY_TZ="${CLAUDE_STATUSLINE_TZ:-Asia/Tokyo}"

# === Platform detection ===
# Check actual command behavior, not just OS, to handle nix/GNU coreutils on macOS
has_keychain() { command -v security >/dev/null 2>&1; }
has_bsd_date() { date -j +%s >/dev/null 2>&1; }
has_bsd_stat() { stat -f %m /dev/null >/dev/null 2>&1; }

# === Get OAuth token (cross-platform) ===
get_token() {
  local creds token
  if has_keychain; then
    creds=$(security find-generic-password -s "Claude Code-credentials" -w 2>/dev/null) || return 1
    # Try parsing as JSON first, then fall back to hex decode
    token=$(echo "$creds" | jq -r '.claudeAiOauth.accessToken // empty' 2>/dev/null)
    if [ -z "$token" ]; then
      token=$(echo "$creds" | xxd -r -p 2>/dev/null \
        | awk -F'"' '{for(i=1;i<=NF;i++){if($(i)=="accessToken"&&f){print $(i+2);exit}if($(i)=="claudeAiOauth")f=1}}')
    fi
  else
    # Linux: read from credentials file
    creds=$(cat ~/.claude/.credentials.json 2>/dev/null) || return 1
    token=$(echo "$creds" | jq -r '.claudeAiOauth.accessToken // empty' 2>/dev/null)
  fi
  [ -n "$token" ] && echo "$token" || return 1
}

# === Format ISO 8601 time (cross-platform) ===
fmt_time() {
  local ts="$1" fmt="$2" result
  [ -z "$ts" ] && printf '?' && return
  if has_bsd_date; then
    local clean="${ts%%.*}" epoch
    clean="${clean%Z}"
    epoch=$(date -juf "%Y-%m-%dT%H:%M:%S" "$clean" "+%s" 2>/dev/null) || { printf '?'; return; }
    result=$(TZ=$DISPLAY_TZ date -jr "$epoch" "+$fmt" 2>/dev/null)
  else
    result=$(TZ=$DISPLAY_TZ date -d "$ts" "+$fmt" 2>/dev/null)
  fi
  result=$(echo "$result" | sed 's/^ *//' | tr '[:upper:]' '[:lower:]')
  [ -n "$result" ] && printf '%s' "$result" || printf '?'
}

# === Rate limit usage (cached 360s) ===
CF="/tmp/claude-usage-cache-${UID}.json"

fetch() {
  if [ -f "$CF" ]; then
    local now mtime age
    now=$(date +%s)
    if has_bsd_stat; then
      mtime=$(stat -f %m "$CF" 2>/dev/null || echo 0)
    else
      mtime=$(stat -c %Y "$CF" 2>/dev/null || echo 0)
    fi
    age=$((now - mtime))
    [ "$age" -lt 360 ] && { cat "$CF"; return; }
  fi

  local token result
  token=$(get_token) || { [ -f "$CF" ] && cat "$CF" || echo "{}"; return; }

  result=$(curl -s --max-time 5 \
    -H "Authorization: Bearer $token" \
    -H "anthropic-beta: oauth-2025-04-20" \
    -H "Content-Type: application/json" \
    "https://api.anthropic.com/api/oauth/usage" 2>/dev/null)

  if echo "$result" | jq -e '.five_hour' >/dev/null 2>&1; then
    install -m 600 /dev/null "$CF"
    echo "$result" > "$CF"
    echo "$result"
  else
    # Cache empty result on failure to prevent repeated API calls
    install -m 600 /dev/null "$CF"
    echo "{}" > "$CF"
    echo "{}"
  fi
}

u=$(fetch)
eval "$(echo "$u" | jq -r '
  [
    "fp=\(.five_hour.utilization // 0 | round)",
    "sp=\(.seven_day.utilization // 0 | round)",
    "fr=\(.five_hour.resets_at // "" | @sh)",
    "sr=\(.seven_day.resets_at // "" | @sh)"
  ] | .[]')"

frs=$(fmt_time "$fr" "%-H:%M")
srs=$(fmt_time "$sr" "%-m/%-d %-H:%M")

# === Output 3 lines ===
cc=$(cpct "$ctx_pct")
fc=$(cpct "$fp")
sc=$(cpct "$sp")

# Line 1: 󰚩 Model │ 󰄨 CTX% │ 󰏫 +N/-N │ 󰘬 VCS info
printf '%s\n' "󰚩 ${model} ${D}│${N} 󰄨 ${cc}${ctx_pct}%${N} ${D}│${N} 󰏫 ${G}+${add}${N}/${R}-${del}${N} ${D}│${N} 󰘬 ${vcs_info}"

# Line 2: 󰅒 5h rate limit
printf '%s\n' "󰅒 5h  ${fc}$(bar "$fp")  ${fp}%${N}  Resets ${frs} (${DISPLAY_TZ})"

# Line 3: 󰃭 7d rate limit
printf '%s\n' "󰃭 7d  ${sc}$(bar "$sp")  ${sp}%${N}  Resets ${srs} (${DISPLAY_TZ})"
