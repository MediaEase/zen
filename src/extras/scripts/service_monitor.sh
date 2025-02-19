#!/usr/bin/env bash
# @file extras/scripts/service_monitor.sh
# @project MediaEase
# @version 1.2.0
# @brief Continuously monitor service logs and output JSON alerts on errors.
# @description This script monitors in real time the system logs of specified services (e.g. radarr, plex) via journalctl. It detects log entries that indicate errors or service failures (including keywords "error", "Main process exited", "Failed with result 'exit-code'", and "Failed at step EXEC spawning"). When an error is detected, it outputs a JSON formatted alert that can be consumed by a frontend application.
# @author Thomas Chauveau
# @author_contact thomas.chauveau.pro@gmail.com
# @license BSD-3 Clause (Included in LICENSE)
# @copyright Copyright (C) 2025, MediaEase

command -v journalctl >/dev/null 2>&1 || { echo "journalctl is required but not installed. Aborting." >&2; exit 1; }
command -v jq >/dev/null 2>&1 || { echo "jq is required but not installed. Aborting." >&2; exit 1; }
trap 'echo "Terminating..."; exit 0' SIGINT SIGTERM
SQLITE3_DB="$(grep DATABASE_URL "/srv/harmonyui/.env.local" | sed -E 's|^DATABASE_URL=||' | sed -E 's|"||g' | sed -E 's|^sqlite:///%kernel.project_dir%|/srv/harmonyui|')"
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
USER=$(echo "$SCRIPT_DIR" | grep -oP "(?<=/home/)(.*)(?=/bin)")
USER_ID=$(sqlite3 -cmd ".timeout 20000" "$SQLITE3_DB" "SELECT id FROM user WHERE username = '$USER'")
mapfile -t SERVICES < <(sqlite3 -cmd ".timeout 20000" "$SQLITE3_DB" "SELECT name FROM service WHERE user_id = '$USER_ID'")

cmd=(journalctl)
for service in "${SERVICES[@]}"; do
    cmd+=( -u "$service" )
done
cmd+=( -f -o json )

ERROR_PATTERN="error|Main process exited|Failed with result 'exit-code'|Failed at step EXEC spawning"

output_alert() {
    local unit="$1"
    local log="$2"
    local status
    status=$(systemctl is-active "$unit" 2>/dev/null)
    if [ -z "$status" ]; then
        status="unknown"
    fi
    jq -n --arg service "$unit" --arg message "$log" --arg status "$status" \
        '{alert: "Error Alert", service: $service, message: $message, status: $status, timestamp: (now | todate)}'
}

"${cmd[@]}" | while IFS= read -r line; do
    if echo "$line" | grep -qiE "$ERROR_PATTERN"; then
        unit=$(echo "$line" | jq -r '._SYSTEMD_UNIT // "unknown"')
        log=$(echo "$line" | jq -r '.MESSAGE // empty')
        output_alert "$unit" "$log"
    fi
done
