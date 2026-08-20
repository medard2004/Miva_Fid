#!/usr/bin/env bash
# Recupere l'URL https ngrok active et l'ecrit dans api_constants.dart
# (defaultValue de API_BASE_URL). Appele automatiquement au demarrage
# du service miva-ngrok.service (voir ExecStartPost).

set -euo pipefail

TARGET_FILE="$(cd "$(dirname "$0")/.." && pwd)/lib/core/api/config/api_constants.dart"
LOG_FILE="/tmp/miva-ngrok-url.log"

URL=""
for _ in $(seq 1 40); do
  URL=$(curl -s http://127.0.0.1:4040/api/tunnels \
    | jq -r '.tunnels[] | select(.proto=="https") | .public_url' 2>/dev/null || true)
  [ -n "$URL" ] && [ "$URL" != "null" ] && break
  sleep 0.5
done

if [ -z "$URL" ] || [ "$URL" = "null" ]; then
  echo "$(date '+%F %T'): echec recuperation URL ngrok" >> "$LOG_FILE"
  exit 1
fi

API_URL="$URL/api"
sed -i "s#defaultValue: '[^']*'#defaultValue: '$API_URL'#" "$TARGET_FILE"
echo "$(date '+%F %T'): API_BASE_URL mis a jour -> $API_URL" >> "$LOG_FILE"
