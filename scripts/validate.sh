#!/usr/bin/env bash
set -euo pipefail

# Post-deployment validation script
# Usage: ./scripts/validate.sh [api_domain] [web_domain]

API_DOMAIN=${1:-https://api.yourdomain.com}
WEB_DOMAIN=${2:-https://yourdomain.com}
COOKIE_JAR="/tmp/helpdesk_cookies.txt"

echo "🔍 Running post-deployment validation"
echo "====================================="
echo "API Domain: $API_DOMAIN"
echo "Web Domain: $WEB_DOMAIN"

# Clean up any existing cookie jar
rm -f "$COOKIE_JAR"

# Test 1: Health Checks
echo ""
echo "[1/8] Testing Health Checks"
echo "---------------------------"
echo "Testing web health..."
WEB_HEALTH=$(curl -s -o /dev/null -w "%{http_code}" "$WEB_DOMAIN/healthz" 2>/dev/null || echo "000")
if [[ "$WEB_HEALTH" == "200" ]]; then
    echo "✅ Web health check OK"
else
    echo "❌ Web health check failed: $WEB_HEALTH"
fi

echo "Testing API health..."
API_HEALTH=$(curl -s -o /dev/null -w "%{http_code}" "$API_DOMAIN/healthz" 2>/dev/null || echo "000")
if [[ "$API_HEALTH" == "200" ]]; then
    echo "✅ API health check OK"
else
    echo "❌ API health check failed: $API_HEALTH"
fi

# Test 2: User Registration and Login
echo ""
echo "[2/8] Testing User Registration and Login"
echo "----------------------------------------"
echo "Registering test user..."
REGISTER_RESPONSE=$(curl -s -w "%{http_code}" -X POST "$API_DOMAIN/api/register" \
    -H "Content-Type: application/json" \
    -d '{"username":"testuser","password":"testpass123","email":"test@example.com"}' \
    -c "$COOKIE_JAR" || echo "000")

if [[ "$REGISTER_RESPONSE" == "201" ]]; then
    echo "✅ User registration successful"
else
    echo "❌ User registration failed: $REGISTER_RESPONSE"
fi

echo "Logging in test user..."
LOGIN_RESPONSE=$(curl -s -w "%{http_code}" -X POST "$API_DOMAIN/api/login" \
    -H "Content-Type: application/json" \
    -d '{"username":"testuser","password":"testpass123"}' \
    -b "$COOKIE_JAR" -c "$COOKIE_JAR" || echo "000")

if [[ "$LOGIN_RESPONSE" == "200" ]]; then
    echo "✅ User login successful"
else
    echo "❌ User login failed: $LOGIN_RESPONSE"
fi

# Test 3: Ticket Creation
echo ""
echo "[3/8] Testing Ticket Creation"
echo "-----------------------------"
echo "Creating test ticket..."
TICKET_RESPONSE=$(curl -s -w "%{http_code}" -X POST "$API_DOMAIN/api/tickets" \
    -H "Content-Type: application/json" \
    -d '{"title":"Production Smoke Test","description":"Testing ticket creation after deployment","priority":"High"}' \
    -b "$COOKIE_JAR" || echo "000")

if [[ "$TICKET_RESPONSE" == "201" ]]; then
    echo "✅ Ticket creation successful"
else
    echo "❌ Ticket creation failed: $TICKET_RESPONSE"
fi

# Test 4: Ticket Listing
echo ""
echo "[4/8] Testing Ticket Listing"
echo "----------------------------"
echo "Listing tickets..."
TICKETS_RESPONSE=$(curl -s -w "%{http_code}" "$API_DOMAIN/api/tickets" -b "$COOKIE_JAR" || echo "000")

if [[ "$TICKETS_RESPONSE" == "200" ]]; then
    echo "✅ Ticket listing successful"
else
    echo "❌ Ticket listing failed: $TICKETS_RESPONSE"
fi

# Test 5: File Upload (if S3 configured)
echo ""
echo "[5/8] Testing File Upload"
echo "-------------------------"
echo "Testing file upload..."
# Create a test file
echo "Test file content" > /tmp/test_file.txt

UPLOAD_RESPONSE=$(curl -s -w "%{http_code}" -X POST "$API_DOMAIN/api/tickets/1/attachments" \
    -F "file=@/tmp/test_file.txt" \
    -b "$COOKIE_JAR" || echo "000")

if [[ "$UPLOAD_RESPONSE" == "200" ]]; then
    echo "✅ File upload successful"
else
    echo "❌ File upload failed: $UPLOAD_RESPONSE"
fi

# Clean up test file
rm -f /tmp/test_file.txt

# Test 6: Password Reset
echo ""
echo "[6/8] Testing Password Reset"
echo "----------------------------"
echo "Testing password reset request..."
RESET_REQUEST_RESPONSE=$(curl -s -w "%{http_code}" -X POST "$API_DOMAIN/api/password/request" \
    -H "Content-Type: application/json" \
    -d '{"username":"testuser"}' || echo "000")

if [[ "$RESET_REQUEST_RESPONSE" == "200" ]]; then
    echo "✅ Password reset request successful"
else
    echo "❌ Password reset request failed: $RESET_REQUEST_RESPONSE"
fi

# Test 7: Rate Limiting
echo ""
echo "[7/8] Testing Rate Limiting"
echo "---------------------------"
echo "Testing rate limiting on login endpoint..."
RATE_LIMIT_COUNT=0
for i in {1..10}; do
    RESPONSE=$(curl -s -w "%{http_code}" -X POST "$API_DOMAIN/api/login" \
        -H "Content-Type: application/json" \
        -d '{"username":"nonexistent","password":"wrong"}' \
        -o /dev/null || echo "000")
    
    if [[ "$RESPONSE" == "429" ]]; then
        RATE_LIMIT_COUNT=$((RATE_LIMIT_COUNT + 1))
    fi
done

if [[ $RATE_LIMIT_COUNT -gt 0 ]]; then
    echo "✅ Rate limiting working ($RATE_LIMIT_COUNT/10 requests rate limited)"
else
    echo "❌ Rate limiting not working"
fi

# Test 8: Frontend Accessibility
echo ""
echo "[8/8] Testing Frontend Accessibility"
echo "------------------------------------"
echo "Testing frontend accessibility..."
FRONTEND_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" "$WEB_DOMAIN" 2>/dev/null || echo "000")

if [[ "$FRONTEND_RESPONSE" == "200" ]]; then
    echo "✅ Frontend accessible"
else
    echo "❌ Frontend not accessible: $FRONTEND_RESPONSE"
fi

# Clean up
rm -f "$COOKIE_JAR"

echo ""
echo "================================================"
echo "🎯 Validation completed!"
echo ""
echo "Summary:"
echo "- Health checks: $([ "$WEB_HEALTH" == "200" ] && [ "$API_HEALTH" == "200" ] && echo "✅ PASS" || echo "❌ FAIL")"
echo "- User management: $([ "$REGISTER_RESPONSE" == "201" ] && [ "$LOGIN_RESPONSE" == "200" ] && echo "✅ PASS" || echo "❌ FAIL")"
echo "- Ticket operations: $([ "$TICKET_RESPONSE" == "201" ] && [ "$TICKETS_RESPONSE" == "200" ] && echo "✅ PASS" || echo "❌ FAIL")"
echo "- File upload: $([ "$UPLOAD_RESPONSE" == "200" ] && echo "✅ PASS" || echo "❌ FAIL")"
echo "- Password reset: $([ "$RESET_REQUEST_RESPONSE" == "200" ] && echo "✅ PASS" || echo "❌ FAIL")"
echo "- Rate limiting: $([ $RATE_LIMIT_COUNT -gt 0 ] && echo "✅ PASS" || echo "❌ FAIL")"
echo "- Frontend: $([ "$FRONTEND_RESPONSE" == "200" ] && echo "✅ PASS" || echo "❌ FAIL")"
echo ""
echo "Next steps:"
echo "1. Monitor application logs for errors"
echo "2. Set up monitoring and alerting"
echo "3. Configure backup schedules"
echo "4. Document incident response procedures"
echo ""
