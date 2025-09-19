#!/bin/bash

# Test HTTPS Setup Script for n8n Deployment
# This script helps verify that the HTTPS configuration is working correctly

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

print_header() {
    echo ""
    print_status $BLUE "=== $1 ==="
}

# Configuration
DOMAIN="${N8N_DOMAIN:-localhost}"
HTTP_PORT="${HTTP_PORT:-80}"
HTTPS_PORT="${HTTPS_PORT:-443}"
CADDY_ADMIN_PORT="${CADDY_ADMIN_PORT:-2019}"

print_header "n8n HTTPS Configuration Test"
echo "Domain: $DOMAIN"
echo "HTTP Port: $HTTP_PORT"
echo "HTTPS Port: $HTTPS_PORT"
echo "Caddy Admin Port: $CADDY_ADMIN_PORT"

# Check if running as correct user
if [[ "$USER" == "n8n" ]]; then
    SUDO_PREFIX=""
else
    SUDO_PREFIX="sudo -u n8n"
    print_status $YELLOW "Note: Running commands as 'n8n' user"
fi

print_header "Container Status Check"

# Check if containers are running
containers=("n8n-caddy" "n8n" "n8n-postgres" "n8n-redis")
all_running=true

for container in "${containers[@]}"; do
    if $SUDO_PREFIX podman ps --format "{{.Names}}" | grep -q "^${container}$"; then
        print_status $GREEN "✓ $container is running"
    else
        print_status $RED "✗ $container is not running"
        all_running=false
    fi
done

if [ "$all_running" = false ]; then
    print_status $RED "Some containers are not running. Please check your deployment."
    exit 1
fi

print_header "Network Connectivity Tests"

# Test Caddy health endpoint
print_status $BLUE "Testing Caddy health endpoint..."
if curl -f -s -o /dev/null "http://localhost:$CADDY_ADMIN_PORT/health" 2>/dev/null; then
    print_status $GREEN "✓ Caddy health endpoint is accessible"
else
    print_status $YELLOW "⚠ Caddy health endpoint not accessible (this is normal if admin API is disabled)"
fi

# Test HTTP endpoint
print_status $BLUE "Testing HTTP endpoint..."
if curl -f -s -o /dev/null -w "%{http_code}" "http://localhost:$HTTP_PORT/healthz" 2>/dev/null | grep -q "200\|204\|301\|302"; then
    print_status $GREEN "✓ HTTP endpoint is accessible"
else
    print_status $RED "✗ HTTP endpoint is not accessible"
fi

# Test HTTPS endpoint (if not localhost)
if [[ "$DOMAIN" != "localhost" && "$DOMAIN" != "127.0.0.1" ]]; then
    print_status $BLUE "Testing HTTPS endpoint..."
    if curl -f -s -o /dev/null -w "%{http_code}" "https://$DOMAIN/healthz" 2>/dev/null | grep -q "200\|204"; then
        print_status $GREEN "✓ HTTPS endpoint is accessible"

        # Test SSL certificate
        print_status $BLUE "Testing SSL certificate..."
        cert_info=$(echo | openssl s_client -connect "$DOMAIN:$HTTPS_PORT" -servername "$DOMAIN" 2>/dev/null | openssl x509 -noout -subject -dates 2>/dev/null)
        if [ $? -eq 0 ]; then
            print_status $GREEN "✓ SSL certificate is valid"
            echo "$cert_info"
        else
            print_status $YELLOW "⚠ Could not verify SSL certificate details"
        fi
    else
        print_status $RED "✗ HTTPS endpoint is not accessible"
    fi
else
    print_status $YELLOW "⚠ Skipping HTTPS test for localhost (use a real domain for SSL testing)"
fi

print_header "Security Headers Test"

if [[ "$DOMAIN" != "localhost" ]]; then
    print_status $BLUE "Checking security headers..."
    headers=$(curl -I -s "https://$DOMAIN" 2>/dev/null || echo "Failed to fetch headers")

    security_headers=("Strict-Transport-Security" "X-Content-Type-Options" "X-Frame-Options" "X-XSS-Protection")

    for header in "${security_headers[@]}"; do
        if echo "$headers" | grep -i "$header" > /dev/null; then
            print_status $GREEN "✓ $header header is present"
        else
            print_status $YELLOW "⚠ $header header is missing"
        fi
    done
else
    print_status $YELLOW "⚠ Skipping security headers test for localhost"
fi

print_header "Volume and Data Persistence Check"

# Check volumes
volumes=("n8n-caddy-data" "n8n-caddy-config" "n8n-data" "n8n-postgres-data" "n8n-redis-data")

for volume in "${volumes[@]}"; do
    if $SUDO_PREFIX podman volume exists "$volume" 2>/dev/null; then
        print_status $GREEN "✓ Volume $volume exists"
    else
        print_status $RED "✗ Volume $volume does not exist"
    fi
done

print_header "Service Logs Check"

print_status $BLUE "Recent Caddy logs (last 10 lines):"
$SUDO_PREFIX podman logs --tail 10 n8n-caddy 2>/dev/null || print_status $RED "Could not fetch Caddy logs"

print_status $BLUE "Recent n8n logs (last 5 lines):"
$SUDO_PREFIX podman logs --tail 5 n8n 2>/dev/null || print_status $RED "Could not fetch n8n logs"

print_header "Test Summary"

if [[ "$DOMAIN" != "localhost" ]]; then
    print_status $GREEN "✓ Production HTTPS setup detected"
    echo "  - Access your n8n instance at: https://$DOMAIN"
    echo "  - SSL certificates should be automatically managed by Let's Encrypt"
    echo "  - HTTP traffic will be redirected to HTTPS"
else
    print_status $YELLOW "⚠ Development setup detected (localhost)"
    echo "  - Access your n8n instance at: http://localhost:$HTTP_PORT"
    echo "  - For production, configure N8N_DOMAIN secret with your real domain"
fi

print_status $BLUE "Troubleshooting tips:"
echo "  - Check container logs: podman logs <container-name>"
echo "  - Verify DNS: dig $DOMAIN"
echo "  - Check firewall: ufw status (or equivalent)"
echo "  - Verify secrets are set in GitHub repository settings"

print_header "Test Complete"