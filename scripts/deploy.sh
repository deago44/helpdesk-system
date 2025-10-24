#!/usr/bin/env bash
set -euo pipefail

# Production deployment script for helpdesk
# Usage: ./scripts/deploy.sh [tag]

TAG=${1:-latest}
COMPOSE_FILE="docker-compose.prod.yml"

echo "🚀 Starting production deployment with tag: $TAG"
echo "================================================"

# Validate environment variables
echo ""
echo "[1/6] Validating Environment Variables"
echo "--------------------------------------"
required_vars=(
    "DATABASE_URL"
    "FLASK_SECRET_KEY"
    "CORS_ALLOWED_ORIGINS"
    "S3_BUCKET"
    "AWS_ACCESS_KEY_ID"
    "AWS_SECRET_ACCESS_KEY"
    "SMTP_SERVER"
    "SENTRY_DSN"
)

missing_vars=()
for var in "${required_vars[@]}"; do
    if [[ -z "${!var:-}" ]]; then
        missing_vars+=("$var")
    else
        echo "✅ $var is set"
    fi
done

if [[ ${#missing_vars[@]} -gt 0 ]]; then
    echo "❌ Missing required environment variables:"
    printf '   %s\n' "${missing_vars[@]}"
    exit 1
fi

# Check Docker and Docker Compose
echo ""
echo "[2/6] Checking Prerequisites"
echo "-----------------------------"
if ! command -v docker &> /dev/null; then
    echo "❌ Docker not found"
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    echo "❌ Docker Compose not found"
    exit 1
fi

echo "✅ Docker and Docker Compose available"

# Run database migrations
echo ""
echo "[3/6] Running Database Migrations"
echo "---------------------------------"
echo "Starting PostgreSQL..."
docker-compose -f $COMPOSE_FILE up -d postgres redis

echo "Waiting for database to be ready..."
sleep 10

echo "Running Alembic migrations..."
docker-compose -f $COMPOSE_FILE run --rm api alembic upgrade head

# Build and deploy application
echo ""
echo "[4/6] Building and Deploying Application"
echo "----------------------------------------"
echo "Building API image with tag: $TAG"
docker-compose -f $COMPOSE_FILE build api

echo "Starting API service..."
docker-compose -f $COMPOSE_FILE up -d api

echo "Waiting for API to be healthy..."
sleep 15

# Deploy Nginx
echo ""
echo "[5/6] Deploying Nginx"
echo "--------------------"
echo "Starting Nginx..."
docker-compose -f $COMPOSE_FILE up -d nginx

# Seed initial data
echo ""
echo "[6/6] Seeding Initial Data"
echo "--------------------------"
echo "Running RBAC seed script..."
docker-compose -f $COMPOSE_FILE run --rm api python seed_data.py

echo ""
echo "================================================"
echo "🎉 Deployment completed successfully!"
echo ""
echo "Services status:"
docker-compose -f $COMPOSE_FILE ps
echo ""
echo "Next steps:"
echo "1. Run post-deploy validation: ./scripts/validate.sh"
echo "2. Monitor application logs: docker-compose -f $COMPOSE_FILE logs -f"
echo "3. Check health endpoints: curl https://yourdomain.com/healthz"
echo ""
