#!/bin/bash

# === CONFIG ===
HOSTNAME=$(hostname)
HOOK_URL="https://mattermost.example.com/hooks/abcd1234"
THRESHOLD=85
ERRORS=()

# === Check 1: Root filesystem read-only ===
if mount | grep ' / ' | grep -q 'ro,'; then
    ERRORS+=("🛑 Filesystem on / is mounted read-only")
fi

# === Check 2: Disk usage over threshold ===
while IFS= read -r line; do
    USE=$(echo "$line" | awk '{print $5}' | tr -d '%')
    MOUNT=$(echo "$line" | awk '{print $6}')
    if [ "$USE" -gt "$THRESHOLD" ]; then
        ERRORS+=("💾 Disk usage on $MOUNT is ${USE}% (threshold: ${THRESHOLD}%)")
    fi
done <<< "$(df -hP | grep '^/dev')"

# === Check 3: SSH login errors in the last hour ===
FAILED_SSH=$(journalctl _COMM=sshd --since "1 hour ago" | grep -i "failed password" | wc -l)
if [ "$FAILED_SSH" -gt 0 ]; then
    ERRORS+=("🔐 $FAILED_SSH failed SSH login attempts in the last hour")
fi

# === Check 4: Root login attempts in the last hour ===
ROOT_LOGS=$(journalctl _COMM=sshd --since "1 hour ago" | grep -iE "Failed password|Connection reset by.*user root")
ROOT_ATTEMPTS=$(echo "$ROOT_LOGS" | grep -i "root" | wc -l)
ROOT_IPS=$(echo "$ROOT_LOGS" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' | sort | uniq | paste -sd ", " -)
if [ -n "$ROOT_IPS" ]; then
    ERRORS+=("🕵️‍♂️ Root login IPs: $ROOT_IPS")
fi

if [ "$ROOT_ATTEMPTS" -gt 0 ]; then
    ERRORS+=("⚠️ $ROOT_ATTEMPTS root login attempts in the last hour (includes resets)")
fi

# === Check 5: Fail2Ban active bans ===
if systemctl is-active --quiet fail2ban; then
    BANNED_IPS=$(fail2ban-client status sshd | grep 'Banned IP list:' | cut -d ':' -f2 | xargs)
    BAN_COUNT=$(echo "$BANNED_IPS" | wc -w)

    if [ "$BAN_COUNT" -gt 0 ]; then
        ERRORS+=("🚫 $BAN_COUNT IPs currently banned by fail2ban: $BANNED_IPS")
    fi
else
    ERRORS+=("⚠️ Fail2Ban service is *not running*")
fi

# === Send to Mattermost if there are problems ===
if [ ${#ERRORS[@]} -ne 0 ]; then
    PAYLOAD=$(printf "*%s* reported system health issues:\n%s" "$HOSTNAME" "$(printf '• %s\n' "${ERRORS[@]}")")

    curl -s -X POST -H 'Content-Type: application/json' \
        -d "{\"text\": \"${PAYLOAD}\"}" "$HOOK_URL"
fi