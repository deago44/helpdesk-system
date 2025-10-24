#!/usr/bin/env bash
set -euo pipefail

# Production rollback script
# Usage: ./scripts/rollback.sh [previous_tag]

PREVIOUS_TAG=${1:-previous}
COMPOSE_FILE="docker-compose.prod.yml"

echo "🔄 Starting production rollback to tag: $PREVIOUS_TAG"
echo "=================================================="

# Confirm rollback
echo "⚠️  WARNING: This will rollback the production deployment!"
read -p "Are you sure you want to continue? (yes/no): " confirm

if [[ "$confirm" != "yes" ]]; then
    echo "❌ Rollback cancelled"
    exit 1
fi

# Step 1: Scale down API service
echo ""
echo "[1/4] Scaling Down API Service"
echo "-------------------------------"
echo "Scaling API service to 0..."
docker-compose -f $COMPOSE_FILE scale api=0

echo "Waiting for service to stop..."
sleep 10

# Step 2: Pull previous image
echo ""
echo "[2/4] Pulling Previous Image"
echo "-----------------------------"
echo "Pulling previous image: helpdesk-api:$PREVIOUS_TAG"
docker pull helpdesk-api:$PREVIOUS_TAG || echo "⚠️  Could not pull image, using local version"

# Step 3: Deploy previous version
echo ""
echo "[3/4] Deploying Previous Version"
echo "--------------------------------"
echo "Starting API service with previous version..."
docker-compose -f $COMPOSE_FILE up -d api

echo "Waiting for service to be healthy..."
sleep 15

# Step 4: Validate rollback
echo ""
echo "[4/4] Validating Rollback"
echo "-------------------------"
echo "Testing health check..."
HEALTH_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" https://api.yourdomain.com/healthz 2>/dev/null || echo "000")

if [[ "$HEALTH_RESPONSE" == "200" ]]; then
    echo "✅ Rollback successful - API is healthy"
else
    echo "❌ Rollback failed - API is not healthy: $HEALTH_RESPONSE"
    echo "Consider manual intervention or further rollback steps"
fi

echo ""
echo "=================================================="
echo "🎯 Rollback completed!"
echo ""
echo "Current service status:"
docker-compose -f $COMPOSE_FILE ps
echo ""
echo "Next steps:"
echo "1. Run validation script: ./scripts/validate.sh"
echo "2. Monitor application logs: docker-compose -f $COMPOSE_FILE logs -f api"
echo "3. Investigate root cause of the issue"
echo "4. Plan remediation steps"
echo ""
echo "If rollback failed:"
echo "1. Check Docker logs: docker-compose -f $COMPOSE_FILE logs api"
echo "2. Verify database connectivity"
echo "3. Check environment variables"
echo "4. Consider emergency procedures"
echo ""
