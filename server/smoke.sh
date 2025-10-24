#!/usr/bin/env bash
set -euo pipefail
host=${1:-http://localhost:5000}
echo "Register 'admin' (ignore if exists)"
curl -s -X POST -H "Content-Type: application/json" -c cookies.txt -d '{"username":"admin","password":"secret"}' $host/api/register || true
echo
echo "Login"
curl -s -X POST -H "Content-Type: application/json" -c cookies.txt -b cookies.txt -d '{"username":"admin","password":"secret"}' $host/api/login
echo
echo "Create ticket"
curl -s -X POST -H "Content-Type: application/json" -c cookies.txt -b cookies.txt -d '{"title":"Printer jam","description":"3rd floor","priority":"High"}' $host/api/tickets
echo
echo "List tickets"
curl -s -c cookies.txt -b cookies.txt $host/api/tickets
echo
