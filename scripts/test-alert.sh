#!/usr/bin/env bash
# Homelab Observability Alert Pipeline Verification
# Usage: ./scripts/test-alert.sh [resolve]

set -euo pipefail

ALERTMANAGER_URL="${ALERTMANAGER_URL:-http://192.168.1.99:9093}"
ACTION="${1:-fire}"

NOW=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
if [ "$ACTION" = "resolve" ]; then
  STARTS_AT=$(date -u -d '10 minutes ago' +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date -u -v-10M +"%Y-%m-%dT%H:%M:%SZ")
  ENDS_AT="$NOW"
  STATUS_MSG="Sending RESOLVED signal for simulated incident..."
else
  STARTS_AT="$NOW"
  ENDS_AT=$(date -u -d '1 hour' +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date -u -v+1H +"%Y-%m-%dT%H:%M:%SZ")
  STATUS_MSG="Sending FIRING signal for simulated incident..."
fi

echo "$STATUS_MSG"

PAYLOAD=$(cat <<EOF
[
  {
    "labels": {
      "alertname": "ProductionIncidentSimulation",
      "severity": "critical",
      "environment": "production",
      "service": "order-api"
    },
    "annotations": {
      "summary": "Simulated upstream database connection pool exhaustion",
      "description": "5xx error rate has breached SLO threshold (5.8% errors over 5m window).",
      "runbook": "docker compose logs --tail=100 order-api | grep ERROR",
      "action": "Restart container: docker compose restart order-api",
      "dashboard": "http://192.168.1.99:3000/explore"
    },
    "startsAt": "$STARTS_AT",
    "endsAt": "$ENDS_AT"
  }
]
EOF
)

curl -sS -X POST "${ALERTMANAGER_URL}/api/v2/alerts" \
  -H "Content-Type: application/json" \
  -d "$PAYLOAD"

echo ""
echo "Done. Querying active alerts from Alertmanager:"
curl -sS "${ALERTMANAGER_URL}/api/v2/alerts" | grep -o '"alertname":"ProductionIncidentSimulation"' || echo "(No matching active alerts or alert resolved)"
