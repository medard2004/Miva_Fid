#!/usr/bin/env bash
# Lance l'app avec l'URL d'API deja injectee, sans avoir a la taper a la main.
#
#   ./scripts/dev.sh              # web, mobile via wifi, mobile via cable (meme reseau)
#   ./scripts/dev.sh tunnel       # mobile via donnees cellulaires (tunnel ngrok)
#
# Args supplementaires transmis a `flutter run` (ex: -d chrome, -d <device-id>).
#
# Le backend Laravel doit ecouter sur toutes les interfaces, pas juste localhost:
#   php artisan serve --host=0.0.0.0 --port=8000
#   (ou `composer dev`, qui le fait deja)

set -euo pipefail
cd "$(dirname "$0")/.."

MODE="lan"
if [[ "${1:-}" == "lan" || "${1:-}" == "tunnel" ]]; then
  MODE="$1"
  shift
fi

PORT=8000

lan_ip() {
  ip route get 1.1.1.1 2>/dev/null | awk '{print $7; exit}' \
    || hostname -I | awk '{print $1}'
}

case "$MODE" in
  lan)
    IP=$(lan_ip)
    if [ -z "$IP" ]; then
      echo "Erreur: impossible de detecter l'IP locale (wifi/reseau connecte ?)" >&2
      exit 1
    fi
    URL="http://$IP:$PORT/api"
    echo "API: $URL  (web, wifi, cable sur le meme reseau)"
    flutter run --dart-define=API_BASE_URL="$URL" "$@"
    ;;

  tunnel)
    echo "Ouverture d'un tunnel ngrok vers le backend local (donnees mobiles)..."
    ngrok http "$PORT" --log=stdout > /tmp/ngrok-mivafid.log 2>&1 &
    NGROK_PID=$!
    trap 'kill $NGROK_PID 2>/dev/null || true' EXIT

    URL=""
    for _ in $(seq 1 20); do
      URL=$(curl -s http://127.0.0.1:4040/api/tunnels \
        | jq -r '.tunnels[] | select(.proto=="https") | .public_url' 2>/dev/null || true)
      [ -n "$URL" ] && [ "$URL" != "null" ] && break
      sleep 0.5
    done

    if [ -z "$URL" ] || [ "$URL" = "null" ]; then
      echo "Erreur: le tunnel ngrok n'a pas demarre (voir /tmp/ngrok-mivafid.log)" >&2
      exit 1
    fi

    echo "API: $URL/api  (donnees mobiles, hors reseau local)"
    flutter run --dart-define=API_BASE_URL="$URL/api" "$@"
    ;;
esac
